-- ROLLBACK da 0025. Remove a função, as colunas novas de
-- whatsapp_messages e a tabela whatsapp_inbound_messages.
--
--   npx.cmd supabase db query -f supabase/rollout-0025/02_rollback.sql --linked --project-ref lchaboncmgcimafpupad
--
-- ATENÇÃO: apaga o histórico de respostas recebidas e a marcação de
-- "solicitação respondida". NÃO desfaz consultas que já foram confirmadas
-- (appointments.status = 'confirmed' continua; é um status válido do app).
-- Antes de aplicar, desligue o processamento no webhook (volte a versão
-- anterior da Edge Function), senão os POSTs passam a falhar com 500.

begin;

drop function if exists public.process_whatsapp_confirmation_reply(
  text, text, text[], timestamptz, text, text
);

drop index if exists public.whatsapp_messages_confirmation_lookup_idx;

alter table public.whatsapp_messages
  drop constraint if exists whatsapp_messages_confirmation_only_on_request,
  drop column if exists confirmation_reply_id,
  drop column if exists confirmation_consumed_at;

drop table if exists public.whatsapp_inbound_messages;

commit;
