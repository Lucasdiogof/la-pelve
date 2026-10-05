-- ROLLBACK da 0023. Remove tudo que a migration adicionou, restaurando
-- exatamente o estado anterior.
--
--   npx.cmd supabase db query -f supabase/rollout-0023/03_rollback.sql --linked --project-ref lchaboncmgcimafpupad
--
-- Como a aplicação futura da 0023 só é permitida com whatsapp_messages
-- vazia (trava embutida na própria migration), este rollback nunca perde
-- dado real: as colunas sendo removidas nunca tiveram nenhuma linha
-- gravada. Mesmo assim, por segurança, aborta se encontrar qualquer linha
-- -- sinal de que algo persistiu depois da 0023 ser aplicada, o que
-- tornaria o rollback destrutivo de verdade.
-- Idempotente. Nunca roda automaticamente.

do $$
begin
  if exists (select 1 from public.whatsapp_messages limit 1) then
    raise exception
      'ROLLBACK ABORTADO: whatsapp_messages tem linhas. Remover '
      'destination_phone_e164/consent_id agora destruiria o snapshot de '
      'destino/consentimento de mensagens reais. Investigue antes de '
      'repetir.';
  end if;
end $$;

drop trigger if exists whatsapp_messages_validate_and_protect on public.whatsapp_messages;
drop function if exists public.whatsapp_messages_validate_and_protect();

alter table public.whatsapp_messages
  drop constraint if exists whatsapp_messages_consent_owner_fkey;

alter table public.whatsapp_messages
  drop constraint if exists whatsapp_messages_destination_phone_e164_format;

drop index if exists public.patient_consents_id_owner_key;

alter table public.whatsapp_messages
  drop column if exists destination_phone_e164,
  drop column if exists consent_id;
