-- PÓS-CHECK da migration 0025. SOMENTE LEITURA.
--
--   npx.cmd supabase db query -f supabase/rollout-0025/03_postcheck_readonly.sql --linked --project-ref lchaboncmgcimafpupad
--
-- Esperado: todas as linhas PASS.

with checks(item, esperado, atual) as (
  values
    ('01 whatsapp_inbound_messages com RLS ligada', 'true',
      (select relrowsecurity from pg_class
       where oid = 'public.whatsapp_inbound_messages'::regclass)::text),
    ('02 app (authenticated) nao le whatsapp_inbound_messages', 'false',
      has_table_privilege('authenticated', 'public.whatsapp_inbound_messages', 'select')::text),
    ('03 anon nao le whatsapp_inbound_messages', 'false',
      has_table_privilege('anon', 'public.whatsapp_inbound_messages', 'select')::text),
    ('04 colunas novas em whatsapp_messages', '2',
      (select count(*) from information_schema.columns
       where table_schema = 'public' and table_name = 'whatsapp_messages'
         and column_name in ('confirmation_reply_id', 'confirmation_consumed_at'))::text),
    ('05 funcao e security definer', 'true',
      (select prosecdef from pg_proc
       where proname = 'process_whatsapp_confirmation_reply'
         and pronamespace = 'public'::regnamespace)::text),
    ('06 anon nao executa a funcao', 'false',
      has_function_privilege('anon',
        'public.process_whatsapp_confirmation_reply(text, text, text[], timestamptz, text, text)',
        'execute')::text),
    ('07 authenticated nao executa a funcao', 'false',
      has_function_privilege('authenticated',
        'public.process_whatsapp_confirmation_reply(text, text, text[], timestamptz, text, text)',
        'execute')::text),
    ('08 service_role executa a funcao', 'true',
      has_function_privilege('service_role',
        'public.process_whatsapp_confirmation_reply(text, text, text[], timestamptz, text, text)',
        'execute')::text),
    ('09 nenhuma linha de whatsapp_messages foi alterada (colunas novas nulas)', '0',
      (select count(*) from public.whatsapp_messages
       where confirmation_consumed_at is not null or confirmation_reply_id is not null)::text)
)
select item, esperado, atual,
  case when esperado = atual then 'PASS' else 'FAIL' end as resultado
from checks
order by item;
