-- Run this in the Supabase dashboard: SQL Editor > New query
-- (or: npx supabase db query -f <this file> --linked).
--
-- Migration MÍNIMA: substitui SOMENTE a função
-- public.whatsapp_messages_validate_and_protect() (já criada na 0023) para
-- que a rejeição de INSERT por consentimento incompatível use um SQLSTATE
-- CUSTOMIZADO e inequívoco, em vez do P0001 genérico (o código que o
-- Postgres atribui a QUALQUER `RAISE EXCEPTION` sem código explícito em
-- PL/pgSQL -- não específico desta validação).
--
-- NÃO altera dados, colunas, constraints ou triggers. NÃO recria o
-- trigger (ele já referencia a função por nome; substituir a função já é
-- suficiente). A branch de UPDATE (proteção dos 8 campos de identidade)
-- continua com RAISE EXCEPTION sem código customizado, de propósito: a
-- camada de materialização nunca faz UPDATE, então não há ambiguidade a
-- resolver ali nesta etapa.
--
-- SQLSTATE escolhido: 'WA001'.
--   - 5 caracteres, maiúsculas/dígitos, como exige o Postgres;
--   - "WA" (WhatsApp) não corresponde a nenhuma classe de erro padrão do
--     Postgres (as classes padrão usam dígitos 0-9 e um conjunto
--     específico de letras documentado no Apêndice A da documentação --
--     "08","09","0A","20"-"2F","34","38","39","3B"-"3F","40","42","44",
--     "53"-"58","72","F0","HV","P0","XX" etc. -- "WA" não aparece nessa
--     lista);
--   - P0001-P0004 explicitamente evitados (são os códigos nativos do
--     PL/pgSQL: raise_exception, no_data_found, too_many_rows,
--     assert_failure);
--   - reservo WA002+ para eventuais outras validações desta tabela no
--     futuro, se precisarem de um código próprio e distinto deste.

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
      raise exception using
        errcode = 'WA001',
        message = 'whatsapp_messages: consentimento ativo incompativel com a mensagem';
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

-- ---------------------------------------------------------------------
-- Check (read-only):
--   01_check   definição atual da função (deve conter errcode = 'WA001')
--   02_check   trigger continua único, BEFORE INSERT OR UPDATE
-- ---------------------------------------------------------------------
select '01_check' as secao, pg_get_functiondef(oid) as def
from pg_proc where proname = 'whatsapp_messages_validate_and_protect';

select '02_check' as secao, tgname, pg_get_triggerdef(oid)
from pg_trigger
where tgrelid = 'public.whatsapp_messages'::regclass and not tgisinternal
order by tgname;
