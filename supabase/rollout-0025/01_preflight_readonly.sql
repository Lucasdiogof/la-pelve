-- PRE-FLIGHT da migration 0025 (confirmação de consulta pela resposta no
-- WhatsApp). SOMENTE LEITURA. Não aplica nada.
--
--   npx.cmd supabase db query -f supabase/rollout-0025/01_preflight_readonly.sql --linked --project-ref lchaboncmgcimafpupad
--
-- Esperado: todas as linhas PASS. Qualquer FAIL: PARE e investigue.

with checks(item, esperado, atual) as (
  values
    ('01 migration 0024 aplicada (WA001 na validacao de consentimento)', 'true',
      (select position('WA001' in prosrc) > 0 from pg_proc
       where proname = 'whatsapp_messages_validate_and_protect'
         and pronamespace = 'public'::regnamespace)::text),
    ('02 whatsapp_inbound_messages ainda nao existe', 'false',
      (to_regclass('public.whatsapp_inbound_messages') is not null)::text),
    ('03 colunas novas ainda nao existem em whatsapp_messages', '0',
      (select count(*) from information_schema.columns
       where table_schema = 'public' and table_name = 'whatsapp_messages'
         and column_name in ('confirmation_reply_id', 'confirmation_consumed_at'))::text),
    ('04 funcao nova ainda nao existe', '0',
      (select count(*) from pg_proc
       where proname = 'process_whatsapp_confirmation_reply'
         and pronamespace = 'public'::regnamespace)::text),
    ('05 profiles.timezone existe (usado para o inicio da consulta)', '1',
      (select count(*) from information_schema.columns
       where table_schema = 'public' and table_name = 'profiles'
         and column_name = 'timezone')::text),
    ('06 role service_role existe', 'true',
      exists (select 1 from pg_roles where rolname = 'service_role')::text)
)
select item, esperado, atual,
  case when esperado = atual then 'PASS' else 'FAIL' end as resultado
from checks
order by item;
