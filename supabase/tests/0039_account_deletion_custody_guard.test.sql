-- Testes das migrations 0039/0040: exclusão de conta bloqueada enquanto houver dados, log mínimo, recibo de
-- exportação e proteção dos arquivos de anexos no Storage. Rodar com supabase/tests/run_sql_tests.sh.
-- Tudo numa transação desfeita. Dados fictícios.

begin;

create function pg_temp.check(cond boolean, label text) returns void
language plpgsql as $$
begin
  if cond is not true then
    raise exception 'FAIL: %', label;
  end if;
  raise notice 'PASS: %', label;
end $$;

create function pg_temp.new_user() returns uuid
language plpgsql as $$
declare v_id uuid;
begin
  insert into auth.users (id, email) values (gen_random_uuid(), gen_random_uuid() || '@teste.local') returning id into v_id;
  insert into public.profiles (id, name, crefito, phone, email)
  values (v_id, 'Teste', '0', '0', 'x@teste.local') on conflict (id) do nothing;
  return v_id;
end $$;

create function pg_temp.act_as(p_id uuid) returns void
language sql as $$ select set_config('request.jwt.claim.sub', p_id::text, true) $$;

create function pg_temp.try_delete() returns text
language plpgsql as $$
begin
  perform public.delete_own_account();
  return 'ok';
exception when others then
  return sqlerrm;
end $$;

create function pg_temp.patient(p_owner uuid, p_id text, p_deleted boolean default false) returns void
language plpgsql as $$
begin
  insert into public.patients (id, fisioterapeuta_id, name, deleted_at)
  values (p_id, p_owner, 'Paciente Fictícia', case when p_deleted then now() end);
end $$;

-- Conta com UMA categoria de dado: precisa ser bloqueada, e nada pode ter sido apagado.
create function pg_temp.assert_blocked(p_user uuid, p_label text) returns void
language plpgsql as $$
declare r text;
begin
  perform pg_temp.act_as(p_user);
  r := pg_temp.try_delete();
  perform pg_temp.check(r = 'account_has_data', p_label || ': bloqueia (' || r || ')');
  perform pg_temp.check(exists (select 1 from auth.users where id = p_user), p_label || ': usuário preservado');
  begin
    perform public.check_account_deletion_allowed();
    perform pg_temp.check(false, p_label || ': pré-checagem deveria bloquear');
  exception when others then
    perform pg_temp.check(sqlerrm = 'account_has_data', p_label || ': pré-checagem bloqueia');
  end;
end $$;

-- 1. Conta realmente vazia exclui, deixa log mínimo, e a chamada repetida é idempotente.
do $$
declare
  vazia uuid := pg_temp.new_user();
begin
  perform pg_temp.act_as(vazia);
  perform public.check_account_deletion_allowed();
  perform pg_temp.check(pg_temp.try_delete() = 'ok', 'conta vazia exclui');
  perform pg_temp.check(not exists (select 1 from auth.users where id = vazia), 'usuário vazio removido');
  perform pg_temp.check(exists (
    select 1 from public.account_deletion_log
     where user_hash = encode(sha256(convert_to(vazia::text, 'utf8')), 'hex')
       and (counts ->> 'patients')::int = 0), 'log sobrevive ao cascade, só com hash e contagens');
  perform pg_temp.check(not exists (select 1 from public.account_deletion_log where user_hash = vazia::text),
    'log não guarda o id em claro');
  perform pg_temp.check(pg_temp.try_delete() = 'ok', 'chamada repetida é idempotente');
  perform pg_temp.check((select count(*) from public.account_deletion_log
     where user_hash = encode(sha256(convert_to(vazia::text, 'utf8')), 'hex')) = 1, 'chamada repetida não duplica o log');
end $$;

-- 2. Cada categoria, isolada, bloqueia.
do $$
declare
  u uuid;
  dono uuid;
begin
  -- só paciente
  u := pg_temp.new_user();
  perform pg_temp.patient(u, 'p-solo');
  perform pg_temp.assert_blocked(u, 'só paciente');
  perform pg_temp.check(exists (select 1 from public.patients where id = 'p-solo'), 'só paciente: registro preservado');

  -- só paciente excluído logicamente (soft delete)
  u := pg_temp.new_user();
  perform pg_temp.patient(u, 'p-soft', true);
  perform pg_temp.assert_blocked(u, 'só paciente soft-deleted');
  perform pg_temp.check(exists (select 1 from public.patients where id = 'p-soft'), 'soft-deleted: registro preservado');

  -- só agenda (sem paciente)
  u := pg_temp.new_user();
  insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status)
  values ('a-solo', u, current_date, '10:00', 'x', 'scheduled');
  perform pg_temp.assert_blocked(u, 'só agenda');
  perform pg_temp.check(exists (select 1 from public.appointments where id = 'a-solo'), 'agenda preservada');

  -- evolução registrada na conta, paciente de outro dono (coluna physiotherapist_id)
  u := pg_temp.new_user();
  dono := pg_temp.new_user();
  perform pg_temp.patient(dono, 'p-outro');
  insert into public.evolution_entries (id, patient_id, physiotherapist_id, date, description)
  values ('e-solo', 'p-outro', u, current_date, 'ficticio');
  perform pg_temp.assert_blocked(u, 'só evolução');

  -- financeiro: depende de paciente (FK), mas a categoria precisa ser contada à parte
  u := pg_temp.new_user();
  perform pg_temp.patient(u, 'p-fin');
  insert into public.financial_entries (id, patient_id, fisioterapeuta_id, date, amount)
  values ('f-solo', 'p-fin', u, current_date, 10);
  perform pg_temp.check((public.account_data_counts(u) ->> 'financial_entries')::int = 1, 'financeiro contado');
  perform pg_temp.assert_blocked(u, 'paciente + financeiro');

  -- só anexo (linha)
  u := pg_temp.new_user();
  perform pg_temp.patient(u, 'p-anx');
  insert into public.attachments (id, fisioterapeuta_id, patient_id, storage_path, file_name)
  values ('x-solo', u, 'p-anx', u || '/p-anx/x-solo_doc.pdf', 'doc.pdf');
  perform pg_temp.check((public.account_data_counts(u) ->> 'attachments')::int = 1, 'anexo contado');
  perform pg_temp.assert_blocked(u, 'paciente + anexo');

  -- consentimento
  u := pg_temp.new_user();
  perform pg_temp.patient(u, 'p-cons');
  insert into public.patient_consents (fisioterapeuta_id, patient_id, channel, purpose, contact_value, source)
  values (u, 'p-cons', 'whatsapp', 'appointment_reminder', '+5562911110000', 'teste');
  perform pg_temp.check((public.account_data_counts(u) ->> 'patient_consents')::int = 1, 'consentimento contado');

  -- arquivo órfão no Storage (sem linha em attachments) também bloqueia
  u := pg_temp.new_user();
  insert into storage.objects (bucket_id, name) values ('patient-attachments', u || '/p-x/orfao_foto.jpg');
  perform pg_temp.check((public.account_data_counts(u) ->> 'storage_attachments')::int = 1, 'órfão no Storage contado');
  perform pg_temp.assert_blocked(u, 'só arquivo órfão no Storage');
  perform pg_temp.check(exists (select 1 from storage.objects where name = u || '/p-x/orfao_foto.jpg'), 'órfão preservado');

  -- avatar não é dado clínico: não bloqueia
  u := pg_temp.new_user();
  insert into storage.objects (bucket_id, name) values ('avatars', u || '/foto.jpg');
  perform pg_temp.act_as(u);
  perform pg_temp.check(pg_temp.try_delete() = 'ok', 'avatar sozinho não bloqueia');
end $$;

-- 3. Declaração de responsabilidade NÃO existe mais: RPCs de custódia foram removidas do desenho.
do $$
begin
  perform pg_temp.check(to_regprocedure('public.confirm_clinical_data_custody(text)') is null,
    'não existe RPC que libera exclusão por declaração');
  perform pg_temp.check(not exists (select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles' and column_name like 'custody%'),
    'profiles não tem colunas de custódia');
end $$;

-- 4. Sem sessão, nada funciona; anon não executa; helpers internos não são chamáveis pelo app.
do $$
begin
  perform set_config('request.jwt.claim.sub', '', true);
  begin
    perform public.check_account_deletion_allowed();
    perform pg_temp.check(false, 'sem sessão deveria falhar');
  exception when others then
    perform pg_temp.check(sqlerrm = 'not authenticated', 'sem sessão: not authenticated');
  end;
  perform pg_temp.check(pg_temp.try_delete() = 'not authenticated', 'delete_own_account sem sessão falha');
  perform pg_temp.check(not has_function_privilege('anon', 'public.delete_own_account()', 'execute'), 'anon não executa delete_own_account');
  perform pg_temp.check(not has_function_privilege('anon', 'public.check_account_deletion_allowed()', 'execute'), 'anon não executa check');
  perform pg_temp.check(not has_function_privilege('anon', 'public.record_data_export(text, jsonb)', 'execute'), 'anon não executa record_data_export');
  perform pg_temp.check(has_function_privilege('authenticated', 'public.delete_own_account()', 'execute'), 'authenticated executa delete_own_account');
  perform pg_temp.check(not has_function_privilege('authenticated', 'public.account_data_counts(uuid)', 'execute'), 'authenticated não chama account_data_counts');
  perform pg_temp.check(not has_function_privilege('authenticated', 'public.assert_account_empty(uuid)', 'execute'), 'authenticated não chama assert_account_empty');
  perform pg_temp.check(not has_table_privilege('authenticated', 'public.account_deletion_log', 'select'), 'authenticated não lê o log');
  perform pg_temp.check(not has_table_privilege('authenticated', 'public.account_deletion_log', 'insert'), 'authenticated não escreve no log');
  perform pg_temp.check(not has_table_privilege('authenticated', 'public.data_export_receipts', 'select'), 'authenticated não lê recibos');
  perform pg_temp.check(not has_table_privilege('anon', 'public.data_export_receipts', 'select'), 'anon não lê recibos');
end $$;

-- 5. Guarda estrutural: toda tabela de public com FK para auth.users precisa estar decidida (coberta pela trava
--    ou listada como configuração de integração). Uma tabela nova sem decisão FALHA este teste.
do $$
declare
  desconhecidas text[];
begin
  select array_agg(distinct c.relname order by c.relname) into desconhecidas
  from pg_constraint k
  join pg_class c on c.oid = k.conrelid
  join pg_namespace n on n.oid = c.relnamespace
  where k.contype = 'f' and k.confrelid = 'auth.users'::regclass and n.nspname = 'public'
    and c.relname not in (
      -- cobertas por account_data_counts
      'patients', 'evolution_entries', 'appointments', 'financial_entries', 'attachments',
      'patient_consents', 'whatsapp_messages',
      -- conta e configuração de integração (sem dado de paciente; metadados/credenciais removidos com a conta)
      'profiles', 'account_deletion_requests', 'whatsapp_connections', 'whatsapp_connect_attempts', 'whatsapp_inbound_messages',
      'whatsapp_connection_credentials', 'whatsapp_informative_gate', 'whatsapp_phone_registration_guard');
  perform pg_temp.check(desconhecidas is null,
    'toda tabela com FK para auth.users está classificada (novas: ' || coalesce(desconhecidas::text, '-') || ')');
end $$;

-- 6. Recibo de exportação: o servidor compara as contagens do app com as reais.
do $$
declare
  u uuid := pg_temp.new_user();
  r jsonb;
  srv jsonb;
begin
  perform pg_temp.patient(u, 'p-rec');
  perform pg_temp.act_as(u);
  srv := public.account_data_counts(u);
  r := public.record_data_export(repeat('a', 64), srv);
  perform pg_temp.check((r ->> 'matches')::boolean, 'recibo com contagens corretas: completo');
  r := public.record_data_export(repeat('b', 64), jsonb_set(srv, '{patients}', '0'));
  perform pg_temp.check((not (r ->> 'matches')::boolean) and ((r -> 'mismatches') ? 'patients'), 'recibo com paciente faltando: incompleto');
  r := public.record_data_export(repeat('c', 64), srv - 'attachments');
  perform pg_temp.check(not (r ->> 'matches')::boolean, 'recibo sem uma categoria: incompleto');
  begin
    perform public.record_data_export('nao-e-hash', srv);
    perform pg_temp.check(false, 'hash inválido deveria falhar');
  exception when others then
    perform pg_temp.check(sqlerrm = 'invalid manifest hash', 'hash inválido recusado');
  end;
  perform pg_temp.check((select count(*) from public.data_export_receipts where user_hash = encode(sha256(convert_to(u::text, 'utf8')), 'hex')) = 3,
    'recibos gravados sem id em claro');
  -- um recibo não libera a exclusão
  perform pg_temp.check(pg_temp.try_delete() = 'account_has_data', 'recibo de exportação não libera a exclusão');
end $$;

-- 7. Migration 0040: arquivo referenciado por anexo não é removível pelo usuário; órfão e avatar são.
grant usage on schema storage to authenticated;
grant execute on function storage.foldername(text) to authenticated;
grant select, delete on storage.objects to authenticated;
grant select on public.attachments to authenticated;

do $$
declare
  u uuid := pg_temp.new_user();
begin
  perform pg_temp.patient(u, 'p-sto');
  insert into storage.objects (bucket_id, name) values ('patient-attachments', u || '/p-sto/ref_doc.pdf');
  insert into storage.objects (bucket_id, name) values ('patient-attachments', u || '/p-sto/orfao.pdf');
  insert into storage.objects (bucket_id, name) values ('avatars', u || '/foto.jpg');
  insert into public.attachments (id, fisioterapeuta_id, patient_id, storage_path, file_name)
  values ('ref', u, 'p-sto', u || '/p-sto/ref_doc.pdf', 'doc.pdf');
  perform pg_temp.act_as(u);
  perform set_config('test.uid', u::text, true);
end $$;

set local role authenticated;

do $$
declare
  u text := current_setting('test.uid');
  n int;
begin
  delete from storage.objects where bucket_id = 'patient-attachments' and name = u || '/p-sto/ref_doc.pdf';
  get diagnostics n = row_count;
  perform pg_temp.check(n = 0, 'arquivo referenciado por anexo NÃO pode ser removido pelo usuário');

  delete from storage.objects where bucket_id = 'patient-attachments' and (storage.foldername(name))[1] = u;
  get diagnostics n = row_count;
  perform pg_temp.check(n = 1, 'remoção em massa só alcança o órfão (arquivo referenciado sobrevive)');

  delete from storage.objects where bucket_id = 'avatars' and name = u || '/foto.jpg';
  get diagnostics n = row_count;
  perform pg_temp.check(n = 1, 'avatar continua removível');

  -- fluxo novo do app: linha primeiro, depois o arquivo
  delete from public.attachments where id = 'ref';
  delete from storage.objects where bucket_id = 'patient-attachments' and name = u || '/p-sto/ref_doc.pdf';
  get diagnostics n = row_count;
  perform pg_temp.check(n = 1, 'apagada a linha, o arquivo pode ser removido (fluxo linha-depois-arquivo)');
end $$;

reset role;

rollback;
