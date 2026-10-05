-- SNAPSHOT read-only para comparar ANTES/DEPOIS da 0024. A 0024 não toca
-- em nenhuma linha -- só substitui 1 função -- então a saída deve ser
-- idêntica nas duas execuções. Só contagens e hashes, nenhum dado real.
--
--   npx.cmd supabase db query -f supabase/rollout-0024/02_snapshot_readonly.sql --linked --project-ref lchaboncmgcimafpupad

(select 'whatsapp_messages' as tabela, count(*)::text as linhas,
  md5(coalesce(string_agg(md5(t::text), ',' order by md5(t::text)), '')) as hash
from public.whatsapp_messages t)

union all
(select 'patient_consents', count(*)::text,
  md5(coalesce(string_agg(md5(t::text), ',' order by md5(t::text)), ''))
from public.patient_consents t)

union all
(select 'patients', count(*)::text,
  md5(coalesce(string_agg(md5(t::text), ',' order by md5(t::text)), ''))
from public.patients t)

union all
(select 'appointments', count(*)::text,
  md5(coalesce(string_agg(md5(t::text), ',' order by md5(t::text)), ''))
from public.appointments t)

union all
(select 'profiles', count(*)::text,
  md5(coalesce(string_agg(md5(t::text), ',' order by md5(t::text)), ''))
from public.profiles t)

union all
(select 'whatsapp_connections', count(*)::text,
  md5(coalesce(string_agg(md5(t::text), ',' order by md5(t::text)), ''))
from public.whatsapp_connections t)

order by 1;
