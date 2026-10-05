-- PRE-FLIGHT da migration 0023 (destination_phone_e164 + consent_id em
-- whatsapp_messages). SOMENTE LEITURA. Não aplica nada.
--
--   npx.cmd supabase db query -f supabase/rollout-0023/01_preflight_readonly.sql --linked --project-ref lchaboncmgcimafpupad
--
-- Se '01_whatsapp_messages_total' não vier '0', PARE: a migration real
-- vai abortar sozinha (ela tem a mesma trava embutida), mas não faz
-- sentido nem tentar sem investigar por que deixou de estar vazia.

(select '01_whatsapp_messages_total' as secao, 'total' as info, count(*)::text as valor
from public.whatsapp_messages)

union all
(select '02_colisao_colunas', 'destination_phone_e164 existe?',
  (exists (select 1 from information_schema.columns
    where table_schema='public' and table_name='whatsapp_messages' and column_name='destination_phone_e164'))::text)

union all
(select '02_colisao_colunas', 'consent_id existe?',
  (exists (select 1 from information_schema.columns
    where table_schema='public' and table_name='whatsapp_messages' and column_name='consent_id'))::text)

union all
(select '03_colisao_constraint', 'whatsapp_messages_consent_owner_fkey existe?',
  (exists (select 1 from pg_constraint where conname='whatsapp_messages_consent_owner_fkey'))::text)

union all
(select '03_colisao_constraint', 'whatsapp_messages_destination_phone_e164_format existe?',
  (exists (select 1 from pg_constraint where conname='whatsapp_messages_destination_phone_e164_format'))::text)

union all
(select '04_colisao_indice', 'patient_consents_id_owner_key existe?',
  (exists (select 1 from pg_indexes where indexname='patient_consents_id_owner_key'))::text)

union all
(select '05_colisao_trigger', 'whatsapp_messages_validate_and_protect existe?',
  (exists (select 1 from pg_trigger where tgname='whatsapp_messages_validate_and_protect'))::text)

union all
(select '06_patient_consents_total', 'total', count(*)::text from public.patient_consents)

union all
(select '07_patients_total', 'total', count(*)::text from public.patients)

union all
(select '08_atividade', coalesce(state, '?'), count(*)::text
from pg_stat_activity
where datname = current_database() and pid <> pg_backend_pid() and backend_type = 'client backend'
group by 2)

order by 1, 2;
