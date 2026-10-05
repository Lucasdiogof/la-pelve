-- PRE-FLIGHT da migration 0021 (appointments.schedule_revision_at).
-- SOMENTE LEITURA. Não aplica nada.
--
--   npx.cmd supabase db query -f supabase/rollout-0021/01_preflight_readonly.sql --linked --project-ref lchaboncmgcimafpupad

(select '01_created_at_def' as secao, column_name,
  data_type || case when is_nullable='NO' then ' NOT NULL' else ' NULLABLE' end as info
from information_schema.columns
where table_schema='public' and table_name='appointments' and column_name='created_at')

union all
(select '02_created_at_default', 'column_default', coalesce(column_default, '<sem default>')
from information_schema.columns
where table_schema='public' and table_name='appointments' and column_name='created_at')

union all
(select '03_created_at_nulls', 'total nulo', count(*)::text
from public.appointments where created_at is null)

union all
(select '04_total_appointments', 'total', count(*)::text from public.appointments)

union all
(select '05_schedule_revision_dist', schedule_revision::text, count(*)::text
from public.appointments group by schedule_revision)

union all
(select '06_whatsapp_messages', 'total', count(*)::text from public.whatsapp_messages)

union all
(select '07_colisao_coluna', 'appointments.schedule_revision_at',
  (exists (select 1 from information_schema.columns
    where table_schema='public' and table_name='appointments' and column_name='schedule_revision_at'))::text)

union all
(select '08_funcao_atual', 'public.set_appointment_schedule_revision existe', 'true'
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname='set_appointment_schedule_revision')

union all
(select '09_trigger_atual', tgname, pg_get_triggerdef(oid)
from pg_trigger where tgname='appointments_set_schedule_revision' and not tgisinternal)

union all
(select '10_atividade', coalesce(state, '?'), count(*)::text
from pg_stat_activity
where datname = current_database() and pid <> pg_backend_pid() and backend_type = 'client backend'
group by 2)

order by 1, 2;
