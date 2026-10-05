-- SNAPSHOT read-only para comparar ANTES/DEPOIS da 0023. Roda duas vezes;
-- a saída deve ser idêntica (a 0023 não faz UPDATE em nenhuma linha
-- existente -- whatsapp_messages já está vazia e as colunas novas não
-- têm backfill).
--
--   npx.cmd supabase db query -f supabase/rollout-0023/02_snapshot_readonly.sql --linked --project-ref lchaboncmgcimafpupad

(select 'whatsapp_messages' as tabela, count(*)::text as linhas,
  md5(coalesce(string_agg(md5(t::text), ',' order by id), '')) as hash
from public.whatsapp_messages t)

union all
(select 'patient_consents', count(*)::text,
  md5(coalesce(string_agg(md5(t::text), ',' order by id), ''))
from public.patient_consents t)

union all
(select 'patients', count(*)::text,
  md5(coalesce(string_agg(md5(t::text), ',' order by id), ''))
from public.patients t)

union all
(select 'appointments', count(*)::text,
  md5(string_agg(
    id || '|' || fisioterapeuta_id::text || '|' || date::text || '|' || time::text || '|' ||
    patient_name || '|' || status || '|' || coalesce(patient_id, '<NULL>') || '|' ||
    created_at::text || '|' || schedule_revision::text || '|' || schedule_revision_at::text,
    ',' order by id
  ))
from public.appointments)

union all
(select 'profiles', count(*)::text,
  md5(coalesce(string_agg(md5(t::text), ',' order by id), ''))
from public.profiles t)

union all
(select 'whatsapp_connections', count(*)::text,
  md5(coalesce(string_agg(md5(t::text), ',' order by id), ''))
from public.whatsapp_connections t)

order by 1;
