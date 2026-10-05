-- ROLLBACK da 0024. Restaura a função exatamente como ficou na 0023
-- (RAISE EXCEPTION genérico, sem SQLSTATE customizado). Não toca em
-- nenhum dado, coluna, constraint, índice ou trigger -- só CREATE OR
-- REPLACE da mesma função.
--
--   npx.cmd supabase db query -f supabase/rollout-0024/03_rollback.sql --linked --project-ref lchaboncmgcimafpupad

create or replace function public.whatsapp_messages_validate_and_protect()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if not exists (
      select 1 from public.patient_consents
      where id = new.consent_id
        and patient_id = new.patient_id
        and fisioterapeuta_id = new.fisioterapeuta_id
        and channel = 'whatsapp'
        and purpose = 'appointment_reminder'
        and revoked_at is null
        and contact_value = new.destination_phone_e164
      for share
    ) then
      raise exception 'whatsapp_messages: consentimento ativo incompativel com a mensagem';
    end if;
  elsif tg_op = 'UPDATE' then
    if new.fisioterapeuta_id is distinct from old.fisioterapeuta_id
      or new.patient_id is distinct from old.patient_id
      or new.appointment_id is distinct from old.appointment_id
      or new.reminder_type is distinct from old.reminder_type
      or new.schedule_revision is distinct from old.schedule_revision
      or new.scheduled_for is distinct from old.scheduled_for
      or new.destination_phone_e164 is distinct from old.destination_phone_e164
      or new.consent_id is distinct from old.consent_id
    then
      raise exception
        'whatsapp_messages: campos de identidade sao imutaveis apos a '
        'criacao (fisioterapeuta_id, patient_id, appointment_id, '
        'reminder_type, schedule_revision, scheduled_for, '
        'destination_phone_e164, consent_id). Uma remarcacao cria uma '
        'NOVA linha com nova schedule_revision -- nunca atualiza esta.';
    end if;
  end if;
  return new;
end;
$$;
