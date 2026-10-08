-- PÓS-CHECK da migration 0026. SOMENTE LEITURA.
--
--   npx.cmd supabase db query -f supabase/rollout-0026/03_postcheck_readonly.sql --linked --project-ref lchaboncmgcimafpupad

with fns(sig) as (
  values
    ('public.set_whatsapp_connection_access_token(uuid, text)'),
    ('public.claim_whatsapp_messages_for_dispatch(integer, integer, text[])'),
    ('public.prepare_whatsapp_message_send(uuid, uuid)'),
    ('public.complete_whatsapp_message_send(uuid, uuid, text, text, text, jsonb, integer)')
),
checks(item, esperado, atual) as (
  values
    ('01 whatsapp_connection_credentials com RLS ligada', 'true',
      (select relrowsecurity from pg_class
       where oid = 'public.whatsapp_connection_credentials'::regclass)::text),
    ('02 app (authenticated/anon) nao le credenciais', 'false',
      (has_table_privilege('authenticated', 'public.whatsapp_connection_credentials', 'select')
       or has_table_privilege('anon', 'public.whatsapp_connection_credentials', 'select'))::text),
    ('03 colunas de controle em whatsapp_messages', '5',
      (select count(*) from information_schema.columns
       where table_schema = 'public' and table_name = 'whatsapp_messages'
         and column_name in ('attempt_count', 'next_attempt_at', 'lease_token',
                             'lease_expires_at', 'send_started_at'))::text),
    ('04 RPCs: nenhuma executavel por anon/authenticated', '0',
      (select count(*) from fns
       where has_function_privilege('anon', sig, 'execute')
          or has_function_privilege('authenticated', sig, 'execute'))::text),
    ('05 RPCs: todas executaveis por service_role', '4',
      (select count(*) from fns where has_function_privilege('service_role', sig, 'execute'))::text),
    ('06 nenhuma credencial ainda (nada provisionado nesta etapa)', '0',
      (select count(*) from public.whatsapp_connection_credentials)::text),
    ('07 nenhuma linha antiga alterada (attempt_count = 0 em todas)', '0',
      (select count(*) from public.whatsapp_messages where attempt_count <> 0)::text)
)
select item, esperado, atual,
  case when esperado = atual then 'PASS' else 'FAIL' end as resultado
from checks
order by item;
