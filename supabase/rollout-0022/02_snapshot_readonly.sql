-- SNAPSHOT read-only para comparar ANTES/DEPOIS da 0022. Roda duas vezes;
-- a saída deve ser idêntica (a 0022 não faz UPDATE em nenhuma linha).
--
--   npx.cmd supabase db query -f supabase/rollout-0022/02_snapshot_readonly.sql --linked --project-ref lchaboncmgcimafpupad

(select 'appointments' as tabela, count(*)::text as linhas,
  md5(string_agg(
    id || '|' || fisioterapeuta_id::text || '|' || date::text || '|' || time::text || '|' ||
    patient_name || '|' || status || '|' || coalesce(patient_id, '<NULL>') || '|' ||
    created_at::text || '|' || schedule_revision::text || '|' || schedule_revision_at::text,
    ',' order by id
  )) as hash_colunas
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
