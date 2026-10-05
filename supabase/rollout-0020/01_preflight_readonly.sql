-- PRE-FLIGHT (v2) da migration 0020 — agora com schedule_revision em vez de
-- event_key. SOMENTE LEITURA. Não aplica nada.
--
--   npx.cmd supabase db query -f supabase/rollout-0020/01_preflight_readonly.sql --linked --project-ref lchaboncmgcimafpupad

(select '01_whatsapp_messages_linhas' as secao, 'total' as item, count(*)::text as valor
from public.whatsapp_messages)

union all
(select '02_appointments_linhas', 'total', count(*)::text from public.appointments)
union all
(select '02_appointments_linhas', 'com date/time nulo (nao deveria existir)',
  count(*)::text from public.appointments where date is null or time is null)
union all
(select '02_appointments_linhas', 'por status', status || '=' || count(*)::text
from public.appointments group by status)

union all
(select '03_colisao_coluna', 'appointments.schedule_revision',
  (exists (select 1 from information_schema.columns
    where table_schema='public' and table_name='appointments' and column_name='schedule_revision'))::text)
union all
(select '03_colisao_coluna', 'whatsapp_messages.schedule_revision',
  (exists (select 1 from information_schema.columns
    where table_schema='public' and table_name='whatsapp_messages' and column_name='schedule_revision'))::text)
union all
(select '03_colisao_coluna', 'whatsapp_messages.event_key (deve ser false; nunca existiu de verdade)',
  (exists (select 1 from information_schema.columns
    where table_schema='public' and table_name='whatsapp_messages' and column_name='event_key'))::text)

union all
(select '04_colisao_funcao', 'public.set_appointment_schedule_revision',
  (exists (select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='set_appointment_schedule_revision'))::text)
union all
(select '04_colisao_trigger', 'appointments_set_schedule_revision',
  (exists (select 1 from pg_trigger where tgname='appointments_set_schedule_revision' and not tgisinternal))::text)
union all
(select '04_colisao_constraint', conname, 'JA EXISTE'
from pg_constraint
where conname in (
  'appointments_schedule_revision_non_negative',
  'whatsapp_messages_schedule_revision_non_negative',
  'whatsapp_messages_schedule_revision_matches_type',
  'whatsapp_messages_one_per_appointment_revision'
))

union all
(select '05_constraint_reminder_type_atual', conname, pg_get_constraintdef(oid)
from pg_constraint
where conrelid = 'public.whatsapp_messages'::regclass
  and conname = 'whatsapp_messages_reminder_type_valid')
union all
(select '06_unique_atual', conname, pg_get_constraintdef(oid)
from pg_constraint
where conrelid = 'public.whatsapp_messages'::regclass
  and conname = 'whatsapp_messages_one_per_appointment_type')

union all
(select '07_triggers_existentes_em_appointments', tgname, pg_get_triggerdef(oid)
from pg_trigger
where tgrelid = 'public.appointments'::regclass and not tgisinternal)

union all
(select '08_atividade', coalesce(state, '?'), count(*)::text
from pg_stat_activity
where datname = current_database() and pid <> pg_backend_pid() and backend_type = 'client backend'
group by 2)

order by 1, 2;
