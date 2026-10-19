-- Testes da migration 0039 (trava de custódia na exclusão de conta). Rodar com supabase/tests/run_sql_tests.sh.
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

do $$
declare
  vazia uuid := pg_temp.new_user();
  com_dados uuid := pg_temp.new_user();
  r text;
begin
  -- conta sem registros clínicos continua podendo ser excluída
  perform pg_temp.act_as(vazia);
  perform pg_temp.check(pg_temp.try_delete() = 'ok', 'conta sem registros clínicos exclui normalmente');
  perform pg_temp.check(not exists (select 1 from auth.users where id = vazia), 'usuário vazio removido');

  -- conta com paciente (inclusive soft-deleted) é bloqueada sem custódia
  insert into public.patients (id, fisioterapeuta_id, name, deleted_at)
  values ('p-teste-1', com_dados, 'Paciente Fictícia', now());
  perform pg_temp.act_as(com_dados);
  r := pg_temp.try_delete();
  perform pg_temp.check(r = 'custody_not_confirmed', 'com registros e sem custódia: bloqueia (' || r || ')');
  perform pg_temp.check(exists (select 1 from auth.users where id = com_dados), 'usuário preservado após bloqueio');
  perform pg_temp.check(exists (select 1 from public.patients where id = 'p-teste-1'), 'paciente (soft-deleted) preservado após bloqueio');

  -- método inválido é recusado
  begin
    perform public.confirm_clinical_data_custody('qualquer');
    perform pg_temp.check(false, 'método inválido deveria falhar');
  exception when others then
    perform pg_temp.check(sqlerrm = 'invalid custody method', 'método inválido é recusado');
  end;

  -- custódia confirmada libera
  perform public.confirm_clinical_data_custody('declared_responsibility');
  perform pg_temp.check((select custody_confirmed_method from public.profiles where id = com_dados) = 'declared_responsibility', 'custódia registrada');

  -- custódia vencida (mais de 24 h) volta a bloquear
  update public.profiles set custody_confirmed_at = now() - interval '25 hours' where id = com_dados;
  r := pg_temp.try_delete();
  perform pg_temp.check(r = 'custody_not_confirmed', 'custódia com mais de 24 h bloqueia de novo');

  -- renovada, exclui
  perform public.confirm_clinical_data_custody('export_downloaded');
  perform pg_temp.check(pg_temp.try_delete() = 'ok', 'com custódia recente a exclusão prossegue');
  perform pg_temp.check(not exists (select 1 from auth.users where id = com_dados), 'usuário removido após custódia');
end $$;

-- sem sessão, nada funciona
do $$
begin
  perform set_config('request.jwt.claim.sub', '', true);
  begin
    perform public.check_account_deletion_allowed();
    perform pg_temp.check(false, 'sem sessão deveria falhar');
  exception when others then
    perform pg_temp.check(sqlerrm = 'not authenticated', 'sem sessão: not authenticated');
  end;
end $$;

-- anon não executa as funções
do $$
begin
  perform pg_temp.check(not has_function_privilege('anon', 'public.delete_own_account()', 'execute'), 'anon não executa delete_own_account');
  perform pg_temp.check(not has_function_privilege('anon', 'public.confirm_clinical_data_custody(text)', 'execute'), 'anon não executa confirm_clinical_data_custody');
  perform pg_temp.check(has_function_privilege('authenticated', 'public.delete_own_account()', 'execute'), 'authenticated executa delete_own_account');
end $$;

-- conta que só tem evolução (sem paciente próprio) também é protegida (coluna physiotherapist_id)
do $$
declare
  u uuid := pg_temp.new_user();
  outro uuid := pg_temp.new_user();
  r text;
begin
  insert into public.patients (id, fisioterapeuta_id, name) values ('p-teste-2', outro, 'Outra Fictícia');
  insert into public.evolution_entries (id, patient_id, physiotherapist_id, date, description)
  values ('e-teste-1', 'p-teste-2', u, current_date, 'ficticio');
  perform pg_temp.act_as(u);
  r := pg_temp.try_delete();
  perform pg_temp.check(r = 'custody_not_confirmed', 'só com evolução: bloqueia (' || r || ')');
end $$;

rollback;
