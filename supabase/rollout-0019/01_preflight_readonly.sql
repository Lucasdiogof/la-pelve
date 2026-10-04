-- PRE-FLIGHT da migration 0019 (patient_consents.contact_value). SOMENTE LEITURA.
--
--   npx.cmd supabase db query -f supabase/rollout-0019/01_preflight_readonly.sql --linked --project-ref lchaboncmgcimafpupad
--
-- Esperado:
--   01_patient_consents   linhas = 0     (a coluna NOT NULL sem default só entra em tabela vazia)
--   02..03                zero linhas    (contact_value e a constraint ainda não existem)
--   04_trigger_fn         md5 igual ao da 0018 (rollback restaura exatamente esta versão)
--   05_tabelas_novas      as 3 existem; whatsapp_* vazias
--   06_dependencias       trigger e RLS presentes

select '01_patient_consents' as secao, 'linhas' as item, count(*)::text as valor
from public.patient_consents

union all
select '02_colisao_coluna', table_name||'.'||column_name, 'JA EXISTE'
from information_schema.columns
where table_schema = 'public' and table_name = 'patient_consents' and column_name = 'contact_value'

union all
select '03_colisao_constraint', conname||' on '||conrelid::regclass::text, 'JA EXISTE'
from pg_constraint
where conname = 'patient_consents_contact_value_e164'

union all
select '04_trigger_fn', 'md5(prosrc) de patient_consents_only_revoke',
  md5(p.prosrc)
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'patient_consents_only_revoke'

union all
select '05_tabelas_novas', 'patient_consents existe', (to_regclass('public.patient_consents') is not null)::text
union all
select '05_tabelas_novas', 'whatsapp_connections linhas', count(*)::text from public.whatsapp_connections
union all
select '05_tabelas_novas', 'whatsapp_messages linhas', count(*)::text from public.whatsapp_messages

union all
select '06_dependencias', 'trigger patient_consents_only_revoke ativo',
  exists (select 1 from pg_trigger where tgname = 'patient_consents_only_revoke' and not tgisinternal)::text
union all
select '06_dependencias', 'RLS ligada em patient_consents',
  (select relrowsecurity from pg_class where oid = 'public.patient_consents'::regclass)::text
union all
select '06_dependencias', 'privilegio de UPDATE do app (colunas)',
  coalesce((select string_agg(column_name, ',') from information_schema.column_privileges
    where table_schema='public' and table_name='patient_consents' and grantee='authenticated' and privilege_type='UPDATE'), 'nenhum')

union all
select '07_atividade', coalesce(state, '?'), count(*)::text
from pg_stat_activity
where datname = current_database() and pid <> pg_backend_pid() and backend_type = 'client backend'
group by 2
order by 1, 2;
