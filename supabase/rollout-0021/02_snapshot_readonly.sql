-- SNAPSHOT read-only para comparar ANTES/DEPOIS da 0021. Roda duas vezes;
-- a saída deve ser idêntica.
--
--   npx.cmd supabase db query -f supabase/rollout-0021/02_snapshot_readonly.sql --linked --project-ref lchaboncmgcimafpupad
--
-- appointments usa um hash calculado com as 9 colunas ANTIGAS (as mesmas
-- que já existiam antes da 0021: id, fisioterapeuta_id, date, time,
-- patient_name, status, patient_id, created_at, schedule_revision) —
-- só schedule_revision_at fica de fora de propósito, para o hash
-- continuar comparável antes/depois mesmo com a coluna nova existindo.

(select 'appointments' as tabela, count(*)::text as linhas,
  md5(string_agg(
    id || '|' || fisioterapeuta_id::text || '|' || date::text || '|' || time::text || '|' ||
    patient_name || '|' || status || '|' || coalesce(patient_id, '<NULL>') || '|' || created_at::text || '|' ||
    schedule_revision::text,
    ',' order by id
  )) as hash_colunas_antigas
from public.appointments)

union all
(select 'patients', count(*)::text, md5(coalesce(string_agg(md5(t::text), ',' order by id), ''))
from public.patients t)

union all
(select 'profiles', count(*)::text, md5(coalesce(string_agg(md5(t::text), ',' order by id), ''))
from public.profiles t)

union all
(select 'patient_consents', count(*)::text, md5(coalesce(string_agg(md5(t::text), ',' order by id), ''))
from public.patient_consents t)

union all
(select 'whatsapp_connections', count(*)::text, md5(coalesce(string_agg(md5(t::text), ',' order by id), ''))
from public.whatsapp_connections t)

union all
(select 'whatsapp_messages', count(*)::text, md5(coalesce(string_agg(md5(t::text), ',' order by id), ''))
from public.whatsapp_messages t)

order by 1;
