-- PRE-FLIGHT da migration 0022 (protege appointments.created_at).
-- SOMENTE LEITURA. Não aplica nada.
--
--   npx.cmd supabase db query -f supabase/rollout-0022/01_preflight_readonly.sql --linked --project-ref lchaboncmgcimafpupad

(select '01_total_appointments' as secao, 'total' as info, count(*)::text as valor from public.appointments)

union all
(select '02_schedule_revision_dist', schedule_revision::text, count(*)::text
from public.appointments group by schedule_revision)

union all
(select '03_schedule_revision_at_nulls', 'total nulo', count(*)::text
from public.appointments where schedule_revision_at is null)

union all
(select '04_revision0_divergente', 'schedule_revision_at != created_at (revision 0)', count(*)::text
from public.appointments where schedule_revision = 0 and schedule_revision_at is distinct from created_at)

union all
(select '05_created_at_nulls', 'total nulo', count(*)::text
from public.appointments where created_at is null)

union all
(select '06_whatsapp_messages', 'total', count(*)::text from public.whatsapp_messages)

union all
(select '07_trigger_count', 'triggers de revision em appointments', count(*)::text
from pg_trigger where tgrelid='public.appointments'::regclass and not tgisinternal)

union all
(select '08_funcao_atual', 'public.set_appointment_schedule_revision existe', 'true'
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname='set_appointment_schedule_revision')

union all
(select '09_trigger_def', tgname, pg_get_triggerdef(oid)
from pg_trigger where tgname='appointments_set_schedule_revision' and not tgisinternal)

union all
(select '10_atividade', coalesce(state, '?'), count(*)::text
from pg_stat_activity
where datname = current_database() and pid <> pg_backend_pid() and backend_type = 'client backend'
group by 2)

order by 1, 2;
