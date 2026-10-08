-- ROLLBACK da 0026.
--
--   npx.cmd supabase db query -f supabase/rollout-0026/02_rollback.sql --linked --project-ref lchaboncmgcimafpupad
--
-- Antes: desagende o cron (06_unschedule_cron.sql) e pare a Edge Function
-- whatsapp-dispatcher.
-- ATENÇÃO: apaga as credenciais (e, pelo trigger, os segredos no Vault) e
-- as colunas de controle de envio. Mensagens já enviadas continuam como
-- estão (status/wamid/sent_at são da 0018). Mensagens em 'processing' voltam
-- para 'scheduled' só se nunca chegaram a chamar a Meta; as demais viram
-- 'failed' (nunca reenvie algo que pode ter saído).

begin;

update public.whatsapp_messages
set status = case when send_started_at is null then 'scheduled' else 'failed' end,
    failed_at = case when send_started_at is null then failed_at else now() end
where status = 'processing';

drop function if exists public.complete_whatsapp_message_send(uuid, uuid, text, text, text, jsonb, integer);
drop function if exists public.prepare_whatsapp_message_send(uuid, uuid);
drop function if exists public.claim_whatsapp_messages_for_dispatch(integer, integer, text[]);
drop function if exists public.set_whatsapp_connection_access_token(uuid, text);
drop function if exists public.whatsapp_sanitize_dispatch_error(jsonb);

-- O trigger apaga cada segredo do Vault junto com a linha.
delete from public.whatsapp_connection_credentials;
drop table if exists public.whatsapp_connection_credentials;
drop function if exists public.whatsapp_connection_credentials_delete_secret();

drop index if exists public.whatsapp_messages_processing_lease_idx;
alter table public.whatsapp_messages
  drop constraint if exists whatsapp_messages_processing_has_lease,
  drop constraint if exists whatsapp_messages_attempt_count_non_negative,
  drop column if exists attempt_count,
  drop column if exists next_attempt_at,
  drop column if exists lease_token,
  drop column if exists lease_expires_at,
  drop column if exists send_started_at;

commit;
