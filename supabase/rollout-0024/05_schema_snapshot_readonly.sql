-- SNAPSHOT DE SCHEMA read-only, para comparar ANTES/DEPOIS da 0024.
-- A 0024 só substitui o CORPO de 1 função; tudo abaixo deve sair
-- idêntico, inclusive o OID dos triggers (OID novo = trigger recriado) e
-- o OID da função (CREATE OR REPLACE preserva o OID). A única linha que
-- pode mudar é 'funcao_corpo'.
--
--   npx.cmd supabase db query -f supabase/rollout-0024/05_schema_snapshot_readonly.sql --linked --project-ref lchaboncmgcimafpupad

with tabelas as (
  select unnest(array['whatsapp_messages','patient_consents','patients','appointments','profiles','whatsapp_connections']) as nome
),
itens(categoria, linha) as (
  select 'colunas', c.table_name || '.' || c.column_name || ':' || c.data_type || ':' || c.is_nullable || ':' || coalesce(c.column_default, '')
  from information_schema.columns c join tabelas t on t.nome = c.table_name
  where c.table_schema = 'public'
  union all
  select 'constraints', conrelid::regclass::text || '.' || conname || ':' || convalidated::text || ':' || pg_get_constraintdef(oid)
  from pg_constraint
  where conrelid in (select ('public.' || nome)::regclass from tabelas)
  union all
  select 'indices', i.indexrelid::regclass::text || ':' || i.indisvalid::text || ':' || i.indisready::text || ':' || pg_get_indexdef(i.indexrelid)
  from pg_index i
  where i.indrelid in (select ('public.' || nome)::regclass from tabelas)
  union all
  select 'triggers', tgrelid::regclass::text || '.' || tgname || ':' || oid::text || ':' || tgenabled::text || ':' || tgfoid::regprocedure::text || ':' || pg_get_triggerdef(oid)
  from pg_trigger
  where not tgisinternal and tgrelid in (select ('public.' || nome)::regclass from tabelas)
  union all
  select 'rls', c.oid::regclass::text || ':' || c.relrowsecurity::text || ':' || c.relforcerowsecurity::text || ':' || coalesce(c.relacl::text, '')
  from pg_class c where c.oid in (select ('public.' || nome)::regclass from tabelas)
  union all
  select 'policies', p.tablename || '.' || p.policyname || ':' || p.cmd || ':' || p.roles::text || ':' || coalesce(p.qual, '') || ':' || coalesce(p.with_check, '')
  from pg_policies p join tabelas t on t.nome = p.tablename
  where p.schemaname = 'public'
  union all
  select 'funcao_metadados', p.oid::text || ':' || p.proowner::regrole::text || ':' || coalesce(p.proacl::text, '') || ':' ||
    coalesce(array_to_string(p.proconfig, ','), '') || ':' || p.prosecdef::text || ':' || p.provolatile::text || ':' || p.prolang::text
  from pg_proc p where p.proname = 'whatsapp_messages_validate_and_protect'
  union all
  select 'funcao_corpo', md5(p.prosrc)
  from pg_proc p where p.proname = 'whatsapp_messages_validate_and_protect'
)
select categoria, count(*)::text as itens, md5(string_agg(linha, E'\n' order by linha)) as hash
from itens
group by categoria
order by categoria;
