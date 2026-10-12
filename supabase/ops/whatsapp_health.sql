-- Saúde da integração WhatsApp em uma consulta (só agregados; sem dados de paciente).
--   npx.cmd supabase db query -f supabase/ops/whatsapp_health.sql --linked --project-ref lchaboncmgcimafpupad
-- `ok: true` e `problems: []` = nada a fazer. Cada item de `problems` é um código fixo:
--   messages_failed / meta_token_refused      falhas de envio (token recusado pela Meta = erro 190)
--   queue_overdue / queue_stuck_processing    fila atrasada ou travada
--   connection_token_invalid / connection_error   reconectar o WhatsApp pelo app
--   templates_rejected                        a Meta recusou/pausou um template
--   cron_failed / cron_http_errors / cron_not_running   o agendador não está disparando o dispatcher
-- Mensagens barradas por falta de consentimento: messages.cancelled_by_code_in_window.consent_revoked.
select public.whatsapp_health_summary(24) as saude;
