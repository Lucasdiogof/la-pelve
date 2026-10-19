-- DRY-RUN das migrations 0039 + 0040 em producao numa transacao que e REVERTIDA no fim. Nao persiste nada.
-- NAO e 'sem impacto': dentro da transacao, CREATE INDEX em attachments bloqueia ESCRITAS nessa tabela e CREATE POLICY em
-- storage.objects pede lock na tabela, ate o ROLLBACK. lock_timeout de 3s faz o script abortar em vez de enfileirar o trafego.
-- Rode em horario calmo. Se a conexao cair no meio, o Postgres reverte a transacao aberta. Gerado de migrations/0039 + 0040.
--   npx.cmd supabase db query -f supabase/rollout-0039/02_dry_run_in_rollback.sql --linked --project-ref lchaboncmgcimafpupad
begin;
set local lock_timeout = '3s';
-- Bloqueio de exclusão de conta com dados + registros mínimos de auditoria (ADITIVA; não altera dados existentes).
--
-- Problema: delete_own_account() apagava auth.users e o ON DELETE CASCADE levava TODOS os registros clínicos
-- (inclusive pacientes já "excluídos" por soft delete) sem nenhuma salvaguarda. Prontuários podem ter dever de guarda
-- (COFFITO 414/2012; Lei 13.787/2018) — ver docs/privacy/DATA_RETENTION.md.
--
-- Decisão (2026-10-19): enquanto não existir exportação verificada + transferência de custódia, a exclusão definitiva
-- de uma conta que tenha QUALQUER dado vinculado é BLOQUEADA NO SERVIDOR. Declaração de responsabilidade NÃO libera.
-- Só contas realmente vazias podem ser excluídas. É proteção temporária, não política de retenção.
-- Contas com dados passam por encerramento assistido (docs/privacy/ASSISTED_CLOSURE.md).
--
-- Sequência de exclusão (o Storage não participa de transação do Postgres):
--   1. check_account_deletion_allowed()  -> bloqueia ANTES de qualquer ação destrutiva;
--   2. o app remove só o avatar (não clínico; falha aborta, nada clínico foi tocado);
--   3. delete_own_account()              -> trava a linha do usuário, revalida tudo e só então apaga auth.users.
-- Anexos clínicos NUNCA são removidos pelo cliente: se existirem (linha ou objeto no bucket), o passo 1 e o 3 recusam.
--
-- ORDEM DE APLICAÇÃO: ver docs/privacy/RELEASE_ORDER_0039.md. A 0040 (proteção do Storage) cobre o risco de apps
-- antigos removerem arquivos do bucket antes de chamar delete_own_account().

-- Contagem por categoria do que está vinculado ao usuário. Uso interno (sem EXECUTE para o app).
-- Cobre todas as tabelas com FK para auth.users que guardam dado de paciente/atividade profissional e os
-- objetos do bucket de anexos (inclusive "órfãos", sem linha em attachments).
create or replace function public.account_data_counts(p_user uuid)
returns jsonb
language sql
stable
security definer
set search_path = public, storage
as $$
  select jsonb_build_object(
    'patients',            (select count(*) from public.patients where fisioterapeuta_id = p_user),
    'evolution_entries',   (select count(*) from public.evolution_entries where physiotherapist_id = p_user),
    'appointments',        (select count(*) from public.appointments where fisioterapeuta_id = p_user),
    'financial_entries',   (select count(*) from public.financial_entries where fisioterapeuta_id = p_user),
    'attachments',         (select count(*) from public.attachments where fisioterapeuta_id = p_user),
    'patient_consents',    (select count(*) from public.patient_consents where fisioterapeuta_id = p_user),
    'whatsapp_messages',   (select count(*) from public.whatsapp_messages where fisioterapeuta_id = p_user),
    'storage_attachments', (select count(*) from storage.objects
                             where bucket_id = 'patient-attachments'
                               and (storage.foldername(name))[1] = p_user::text)
  )
$$;
revoke all on function public.account_data_counts(uuid) from public, anon, authenticated;

-- Levanta 'account_has_data' se há qualquer dado vinculado. Uso interno.
create or replace function public.assert_account_empty(p_user uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  c jsonb := public.account_data_counts(p_user);
  total bigint;
begin
  select coalesce(sum(value::bigint), 0) into total from jsonb_each_text(c);
  if total > 0 then
    raise exception 'account_has_data' using errcode = 'P0001';
  end if;
end;
$$;
revoke all on function public.assert_account_empty(uuid) from public, anon, authenticated;

-- Pré-checagem para o app, ANTES de qualquer ação destrutiva.
create or replace function public.check_account_deletion_allowed()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  perform public.assert_account_empty(auth.uid());
end;
$$;

-- Registro mínimo do ato. SEM FK para auth.users (o cascade o apagaria) e sem dado de saúde: só o hash do id,
-- o horário e as contagens (que, por construção, são zero). RLS ligado e sem policy: o app não lê nem escreve.
create table if not exists public.account_deletion_log (
  id bigint generated always as identity primary key,
  user_hash text not null,
  deleted_at timestamptz not null default now(),
  counts jsonb not null
);
alter table public.account_deletion_log enable row level security;
revoke all on table public.account_deletion_log from public, anon, authenticated;

-- Recibo de exportação: o app envia o hash do manifesto e as contagens que ele gerou; o servidor compara com as
-- contagens reais no momento. NÃO prova que a profissional recebeu ou guardou o arquivo, nem substitui custódia legal.
create table if not exists public.data_export_receipts (
  id bigint generated always as identity primary key,
  user_hash text not null,
  created_at timestamptz not null default now(),
  manifest_sha256 text not null,
  client_counts jsonb not null,
  server_counts jsonb not null,
  matches boolean not null
);
alter table public.data_export_receipts enable row level security;
revoke all on table public.data_export_receipts from public, anon, authenticated;

create or replace function public.record_data_export(p_manifest_sha256 text, p_counts jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  srv jsonb;
  k text;
  mismatches text[] := '{}';
  ok boolean;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if p_manifest_sha256 is null or p_manifest_sha256 !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid manifest hash';
  end if;
  if p_counts is null or jsonb_typeof(p_counts) <> 'object' then
    raise exception 'invalid counts';
  end if;
  srv := public.account_data_counts(auth.uid());
  -- Todas as categorias do servidor precisam estar no que o app declarou, com o mesmo número.
  for k in select jsonb_object_keys(srv) loop
    if (p_counts ->> k) is distinct from (srv ->> k) then
      mismatches := mismatches || k;
    end if;
  end loop;
  ok := cardinality(mismatches) = 0;
  insert into public.data_export_receipts (user_hash, manifest_sha256, client_counts, server_counts, matches)
  values (encode(sha256(convert_to(auth.uid()::text, 'utf8')), 'hex'), p_manifest_sha256, p_counts, srv, ok);
  return jsonb_build_object('matches', ok, 'mismatches', to_jsonb(mismatches), 'server_counts', srv);
end;
$$;

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;
  -- Trava a linha do usuário ANTES de checar: uma inserção concorrente de paciente/anexo precisa de FOR KEY SHARE
  -- nesta linha e espera; sem isso, dados criados entre a checagem e o DELETE seriam levados pelo cascade.
  perform 1 from auth.users where id = uid for update;
  if not found then
    return; -- já excluída (chamada repetida): idempotente
  end if;
  perform public.assert_account_empty(uid);
  insert into public.account_deletion_log (user_hash, counts)
  values (encode(sha256(convert_to(uid::text, 'utf8')), 'hex'), public.account_data_counts(uid));
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.check_account_deletion_allowed() from public, anon;
revoke all on function public.record_data_export(text, jsonb) from public, anon;
revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.check_account_deletion_allowed() to authenticated;
grant execute on function public.record_data_export(text, jsonb) to authenticated;
grant execute on function public.delete_own_account() to authenticated;

-- Protege no SERVIDOR os arquivos clínicos referenciados por uma linha em public.attachments.
--
-- Risco: o app antigo removia TODOS os arquivos do bucket 'patient-attachments' antes de chamar delete_own_account().
-- Com a trava da 0039, o RPC recusa a exclusão, mas os arquivos já teriam sido apagados: conta viva, anexos perdidos.
-- O servidor não controla a ordem das chamadas do cliente, então a regra precisa estar no Storage.
--
-- Regra: um objeto do bucket só pode ser removido por um usuário autenticado se NÃO houver mais linha em
-- attachments apontando para ele. O fluxo legítimo de excluir um anexo passa a ser "linha primeiro, arquivo depois"
-- (o app novo faz assim). Num app antigo (arquivo primeiro), a remoção do arquivo é silenciosamente ignorada pelo
-- Storage, a linha é apagada e o arquivo vira órfão: não há perda de dado, mas o arquivo permanece até a limpeza
-- assistida; órfãos também bloqueiam a exclusão da conta (0039). service_role não é afetado (bypass de RLS).
-- Aditiva e idempotente.

create index if not exists attachments_storage_path_idx on public.attachments (storage_path);

drop policy if exists "Keep referenced attachment files" on storage.objects;
create policy "Keep referenced attachment files"
on storage.objects
as restrictive
for delete
to authenticated
using (
  bucket_id <> 'patient-attachments'
  or not exists (
    select 1 from public.attachments a
    where a.storage_path = storage.objects.name
  )
);

with checks(item, esperado, atual) as (
  values
    ('01 account_data_counts existe e nao e chamavel pelo app', 'true',
      (to_regprocedure('public.account_data_counts(uuid)') is not null
       and not has_function_privilege('authenticated', 'public.account_data_counts(uuid)', 'execute')
       and not has_function_privilege('anon', 'public.account_data_counts(uuid)', 'execute'))::text),
    ('02 assert_account_empty existe e nao e chamavel pelo app', 'true',
      (to_regprocedure('public.assert_account_empty(uuid)') is not null
       and not has_function_privilege('authenticated', 'public.assert_account_empty(uuid)', 'execute'))::text),
    ('03 check_account_deletion_allowed e record_data_export para authenticated, nao anon', 'true',
      (has_function_privilege('authenticated', 'public.check_account_deletion_allowed()', 'execute')
       and has_function_privilege('authenticated', 'public.record_data_export(text, jsonb)', 'execute')
       and not has_function_privilege('anon', 'public.check_account_deletion_allowed()', 'execute')
       and not has_function_privilege('anon', 'public.record_data_export(text, jsonb)', 'execute'))::text),
    ('04 delete_own_account usa a trava e grava o log', 'true',
      coalesce((select position('assert_account_empty' in pg_get_functiondef(p.oid)) > 0
                  and position('account_deletion_log' in pg_get_functiondef(p.oid)) > 0
                  and position('for update' in lower(pg_get_functiondef(p.oid))) > 0
                from pg_proc p where p.oid = to_regprocedure('public.delete_own_account()')), false)::text),
    ('05 delete_own_account: anon sem EXECUTE, authenticated com EXECUTE', 'true',
      (not has_function_privilege('anon', 'public.delete_own_account()', 'execute')
       and has_function_privilege('authenticated', 'public.delete_own_account()', 'execute'))::text),
    ('06 log e recibos com RLS e sem acesso do app', 'true',
      (to_regclass('public.account_deletion_log') is not null and to_regclass('public.data_export_receipts') is not null
       and coalesce((select bool_and(relrowsecurity) from pg_class
                      where oid in (to_regclass('public.account_deletion_log'), to_regclass('public.data_export_receipts'))), false)
       and not has_table_privilege('authenticated', 'public.account_deletion_log', 'select')
       and not has_table_privilege('anon', 'public.account_deletion_log', 'select')
       and not has_table_privilege('authenticated', 'public.data_export_receipts', 'select')
       and not has_table_privilege('anon', 'public.data_export_receipts', 'select'))::text),
    ('07 politica de Storage que protege anexos referenciados existe', 'true',
      exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects'
                and policyname = 'Keep referenced attachment files' and permissive = 'RESTRICTIVE' and cmd = 'DELETE')::text),
    ('08 indice de attachments.storage_path existe', 'true',
      (to_regclass('public.attachments_storage_path_idx') is not null)::text),
    ('09 nenhuma coluna de custodia criada em profiles (desenho antigo nao e usado)', '0',
      (select count(*) from information_schema.columns where table_schema='public' and table_name='profiles'
         and column_name like 'custody%')::text),
    ('10 a migration nao alterou dados: log e recibos vazios antes do uso', 'info', 'info')
)
select item, esperado, atual,
       case when esperado = 'info' then 'INFO' when esperado = atual then 'PASS' else 'FAIL' end as resultado
from checks order by item;
rollback;
