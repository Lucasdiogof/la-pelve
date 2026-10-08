-- AGENDAMENTO do pipeline outbound (NÃO é migration; NÃO aplicar ainda).
--
-- Roda a cada 5 minutos: pg_cron chama a Edge Function whatsapp-dispatcher
-- por pg_net, com Authorization: Bearer <WHATSAPP_DISPATCHER_TOKEN>. Sem o
-- token certo a function responde 401 e não faz nada.
--
-- Pré-requisitos, nesta ordem:
--   1. migrations 0025 e 0026 aplicadas (pós-checks PASS);
--   2. Edge Function whatsapp-dispatcher deployada com os secrets
--      WHATSAPP_DISPATCHER_TOKEN, WHATSAPP_GRAPH_API_VERSION,
--      WHATSAPP_TEMPLATE_LANGUAGE e os WHATSAPP_TEMPLATE_* dos templates
--      já APROVADOS na Meta;
--   3. pelo menos uma whatsapp_connection 'connected' com token gravado
--      (set_whatsapp_connection_access_token).
--
-- Antes de rodar, troque os dois <...> abaixo NO EDITOR (nunca commite os
-- valores). URL e token ficam no Vault, não no texto do job.

create extension if not exists pg_cron;
create extension if not exists pg_net;

select vault.create_secret(
  '<WHATSAPP_DISPATCHER_TOKEN>',
  'whatsapp_dispatcher_token',
  'Bearer usado pelo cron para chamar whatsapp-dispatcher'
);
select vault.create_secret(
  'https://lchaboncmgcimafpupad.supabase.co/functions/v1/whatsapp-dispatcher',
  'whatsapp_dispatcher_url',
  'URL da Edge Function whatsapp-dispatcher'
);

select cron.schedule(
  'whatsapp-dispatcher',
  '*/5 * * * *',
  $job$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'whatsapp_dispatcher_url'),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets
                                     where name = 'whatsapp_dispatcher_token')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 60000
  );
  $job$
);
