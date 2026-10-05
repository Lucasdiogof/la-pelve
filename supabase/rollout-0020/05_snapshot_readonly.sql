-- SNAPSHOT read-only das tabelas relevantes, para comparar ANTES/DEPOIS
-- da aplicação da 0020. Roda duas vezes (antes e depois); a saída deve
-- ser idêntica, exceto o aparecimento de schedule_revision depois.
--
--   npx.cmd supabase db query -f supabase/rollout-0020/05_snapshot_readonly.sql --linked --project-ref lchaboncmgcimafpupad
--
-- appointments usa um hash calculado só com as 8 colunas ANTIGAS (id,
-- fisioterapeuta_id, date, time, patient_name, status, patient_id,
-- created_at), de propósito, para que o valor seja comparável
-- antes/depois mesmo depois de schedule_revision passar a existir.

(select 'appointments' as tabela, count(*)::text as linhas,
  md5(string_agg(
    id || '|' || fisioterapeuta_id::text || '|' || date::text || '|' || time::text || '|' ||
    patient_name || '|' || status || '|' || coalesce(patient_id, '<NULL>') || '|' || created_at::text,
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
