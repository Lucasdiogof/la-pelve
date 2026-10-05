-- VALIDAÇÃO LOCAL COMPLETA da 0023 (v2, com validação de consentimento no
-- INSERT) contra o schema real de produção, SEM aplicar nada de verdade:
-- tudo roda dentro de uma transação que termina em ROLLBACK.
--
--   npx.cmd supabase db query -f supabase/rollout-0023/00_dry_run_full_validation.sql --linked --project-ref lchaboncmgcimafpupad
--
-- Cobre os 32 testes pedidos. Nenhum dado real hardcoded: os 2
-- fisioterapeuta_id usados nos fixtures são lidos de public.profiles em
-- tempo de execução (limit 2).
--
-- NOTA IMPORTANTE sobre ordem de execução: o trigger novo
-- (whatsapp_messages_validate_and_protect) é BEFORE INSERT, então roda
-- ANTES das constraints estruturais (NOT NULL, CHECK, FK) serem
-- verificadas pelo Postgres. Isso significa que os testes 2-7 (campos
-- NULL, telefone invalido, consent inexistente/de outro patient/de outro
-- fisio) sao rejeitados pelo NOSSO trigger primeiro, nao pela constraint
-- estrutural equivalente -- a constraint estrutural continua existindo
-- como camada adicional de defesa (nunca é alcançada no fluxo normal,
-- mas protege contra qualquer chamada que bypassasse o trigger). Os
-- testes abaixo verificam "foi rejeitado", não um SQLSTATE específico
-- para esses casos.

begin;

do $$
begin
  if exists (select 1 from public.whatsapp_messages limit 1) then
    raise exception 'PRE-CONDICAO FALHOU: whatsapp_messages nao esta vazia -- nao valido a 0023 contra dados reais';
  end if;
end $$;

-- ======================================================================
-- PARTE 1 — aplica a migration 0023 v2 (idêntico ao arquivo real)
-- ======================================================================

alter table public.whatsapp_messages
  add column if not exists destination_phone_e164 text,
  add column if not exists consent_id uuid;

alter table public.whatsapp_messages
  alter column destination_phone_e164 set not null,
  alter column consent_id set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_destination_phone_e164_format'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_destination_phone_e164_format
      check (destination_phone_e164 ~ '^\+[1-9][0-9]{7,14}$');
  end if;
end $$;

create unique index if not exists patient_consents_id_owner_key
  on public.patient_consents (id, patient_id, fisioterapeuta_id);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_consent_owner_fkey'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_consent_owner_fkey
      foreign key (consent_id, patient_id, fisioterapeuta_id)
      references public.patient_consents (id, patient_id, fisioterapeuta_id);
  end if;
end $$;

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
      raise exception 'whatsapp_messages: campos de identidade sao imutaveis apos a criacao';
    end if;
  end if;
  return new;
end;
$$;

create or replace trigger whatsapp_messages_validate_and_protect
  before insert or update on public.whatsapp_messages
  for each row execute function public.whatsapp_messages_validate_and_protect();

select 'migration 0023 v2 aplicada (1a vez)' as fase;

-- ======================================================================
-- TESTE 25 — reaplicar a migration inteira AGORA, com whatsapp_messages
-- ainda vazia — idempotência.
-- ======================================================================

alter table public.whatsapp_messages
  add column if not exists destination_phone_e164 text,
  add column if not exists consent_id uuid;
alter table public.whatsapp_messages
  alter column destination_phone_e164 set not null,
  alter column consent_id set not null;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_destination_phone_e164_format'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_destination_phone_e164_format
      check (destination_phone_e164 ~ '^\+[1-9][0-9]{7,14}$');
  end if;
end $$;
create unique index if not exists patient_consents_id_owner_key
  on public.patient_consents (id, patient_id, fisioterapeuta_id);
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_consent_owner_fkey'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_consent_owner_fkey
      foreign key (consent_id, patient_id, fisioterapeuta_id)
      references public.patient_consents (id, patient_id, fisioterapeuta_id);
  end if;
end $$;
create or replace trigger whatsapp_messages_validate_and_protect
  before insert or update on public.whatsapp_messages
  for each row execute function public.whatsapp_messages_validate_and_protect();

select 'OK teste 25: migration reaplicada sem erro (idempotente)' as resultado;

-- ======================================================================
-- PARTE 2 — fixtures (2 fisioterapeutas REAIS só por id, dados de
-- paciente/consentimento 100% fictícios e descartáveis).
-- ======================================================================

create temporary table _wa0023_fisios as
select id as fisio_id, row_number() over (order by id) as rn from public.profiles limit 2;

do $$
begin
  if (select count(*) from _wa0023_fisios) < 2 then
    raise exception 'SETUP: preciso de pelo menos 2 profiles reais para os testes 7/8 (consent de outro fisioterapeuta)';
  end if;
end $$;

insert into public.patients (id, fisioterapeuta_id, phone_e164)
select '__wa0023_patient_a1__', fisio_id, '+5562911111111' from _wa0023_fisios where rn = 1;
insert into public.patients (id, fisioterapeuta_id, phone_e164)
select '__wa0023_patient_a2__', fisio_id, '+5562922222222' from _wa0023_fisios where rn = 1;
insert into public.patients (id, fisioterapeuta_id, phone_e164)
select '__wa0023_patient_b1__', fisio_id, '+5562933333333' from _wa0023_fisios where rn = 2;

insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, patient_id, status)
select '__wa0023_appt_a__', fisio_id, '2026-12-01', '10:00:00', 'TESTE 0023 - IGNORAR', '__wa0023_patient_a1__', 'scheduled'
from _wa0023_fisios where rn = 1;
insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, patient_id, status)
select '__wa0023_appt_a2__', fisio_id, '2026-12-02', '11:00:00', 'TESTE 0023 - IGNORAR 2', '__wa0023_patient_a1__', 'scheduled'
from _wa0023_fisios where rn = 1;

-- consent_a1: ativo, whatsapp, appointment_reminder, p/ patient_a1 -- o
-- consentimento "correto" usado nos testes de sucesso.
insert into public.patient_consents (id, patient_id, fisioterapeuta_id, channel, purpose, contact_value, revoked_at)
select 'aaaaaaaa-0000-0000-0000-00000000a001', '__wa0023_patient_a1__', fisio_id, 'whatsapp', 'appointment_reminder', '+5562911111111', null
from _wa0023_fisios where rn = 1;
-- consent_a2: ativo, whatsapp, appointment_reminder, p/ patient_a2 (outro paciente).
insert into public.patient_consents (id, patient_id, fisioterapeuta_id, channel, purpose, contact_value, revoked_at)
select 'aaaaaaaa-0000-0000-0000-00000000a002', '__wa0023_patient_a2__', fisio_id, 'whatsapp', 'appointment_reminder', '+5562922222222', null
from _wa0023_fisios where rn = 1;
-- consent_b1: ativo, whatsapp, appointment_reminder, p/ patient_b1 (outro fisio).
insert into public.patient_consents (id, patient_id, fisioterapeuta_id, channel, purpose, contact_value, revoked_at)
select 'bbbbbbbb-0000-0000-0000-00000000b001', '__wa0023_patient_b1__', fisio_id, 'whatsapp', 'appointment_reminder', '+5562933333333', null
from _wa0023_fisios where rn = 2;
-- consent_a3: patient_a1, channel='sms' (não whatsapp) -- teste 27.
insert into public.patient_consents (id, patient_id, fisioterapeuta_id, channel, purpose, contact_value, revoked_at)
select 'aaaaaaaa-0000-0000-0000-00000000a003', '__wa0023_patient_a1__', fisio_id, 'sms', 'appointment_reminder', '+5562911111111', null
from _wa0023_fisios where rn = 1;
-- consent_a4: patient_a1, purpose='marketing' (não appointment_reminder) -- teste 28.
insert into public.patient_consents (id, patient_id, fisioterapeuta_id, channel, purpose, contact_value, revoked_at)
select 'aaaaaaaa-0000-0000-0000-00000000a004', '__wa0023_patient_a1__', fisio_id, 'whatsapp', 'marketing', '+5562911111111', null
from _wa0023_fisios where rn = 1;
-- consent_a5: patient_a1, whatsapp, appointment_reminder, MAS já revogado -- teste 29.
insert into public.patient_consents (id, patient_id, fisioterapeuta_id, channel, purpose, contact_value, revoked_at)
select 'aaaaaaaa-0000-0000-0000-00000000a005', '__wa0023_patient_a1__', fisio_id, 'whatsapp', 'appointment_reminder', '+5562911111111', now()
from _wa0023_fisios where rn = 1;

select 'fixtures criados' as fase;

-- ======================================================================
-- TESTES 1 e 8 — INSERT válido, destination_phone_e164 E.164 + consent
-- correto (mesmo patient/fisio, mesmo telefone, ativo, whatsapp,
-- appointment_reminder) -> aceita.
-- ======================================================================

insert into public.whatsapp_messages
  (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
   destination_phone_e164, consent_id)
select fisio_id, '__wa0023_patient_a1__', '__wa0023_appt_a__', 'appointment_confirmation', 0, now() + interval '1 day',
  '+5562911111111', 'aaaaaaaa-0000-0000-0000-00000000a001'
from _wa0023_fisios where rn = 1;

do $$
declare v_count int;
begin
  select count(*) into v_count from public.whatsapp_messages
  where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;
  if v_count <> 1 then raise exception 'FALHA testes 1/8: INSERT valido nao foi aceito'; end if;
  raise notice 'OK testes 1/8: INSERT valido com destination_phone_e164 E.164 + consent correto foi aceito';
end $$;

-- ======================================================================
-- TESTE 2 — destination_phone_e164 NULL -> rejeitado (pelo trigger, que
-- roda antes do NOT NULL: o EXISTS com contact_value=NULL nunca é
-- verdadeiro).
-- ======================================================================

do $$
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0023_patient_a1__', '__wa0023_appt_a__', 'appointment_12h', 0, now() + interval '1 day',
      null, 'aaaaaaaa-0000-0000-0000-00000000a001'
    from _wa0023_fisios where rn = 1;
    raise exception 'FALHA teste 2: destination_phone_e164 NULL foi aceito';
  exception
    when others then
      if sqlerrm like '%consentimento ativo incompativel%' or sqlerrm like '%null value%' then
        raise notice 'OK teste 2: destination_phone_e164 NULL foi rejeitado (%)', sqlerrm;
      else raise; end if;
  end;
end $$;

-- ======================================================================
-- TESTE 3 — consent_id NULL -> rejeitado.
-- ======================================================================

do $$
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0023_patient_a1__', '__wa0023_appt_a__', 'appointment_12h', 0, now() + interval '1 day',
      '+5562911111111', null
    from _wa0023_fisios where rn = 1;
    raise exception 'FALHA teste 3: consent_id NULL foi aceito';
  exception
    when others then
      if sqlerrm like '%consentimento ativo incompativel%' or sqlerrm like '%null value%' then
        raise notice 'OK teste 3: consent_id NULL foi rejeitado (%)', sqlerrm;
      else raise; end if;
  end;
end $$;

-- ======================================================================
-- TESTE 4 — telefone fora do formato E.164 -> rejeitado (trigger: não
-- bate com contact_value de nenhum consent ativo real).
-- ======================================================================

do $$
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0023_patient_a1__', '__wa0023_appt_a__', 'appointment_12h', 0, now() + interval '1 day',
      '5562911111111', 'aaaaaaaa-0000-0000-0000-00000000a001' -- sem '+'
    from _wa0023_fisios where rn = 1;
    raise exception 'FALHA teste 4: telefone fora do formato E.164 foi aceito';
  exception
    when others then
      if sqlerrm like '%consentimento ativo incompativel%' or sqlerrm like '%violates check constraint%' then
        raise notice 'OK teste 4: telefone fora do formato E.164 foi rejeitado (%)', sqlerrm;
      else raise; end if;
  end;
end $$;

-- ======================================================================
-- TESTE 5 — consent_id inexistente -> rejeitado.
-- ======================================================================

do $$
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0023_patient_a1__', '__wa0023_appt_a__', 'appointment_12h', 0, now() + interval '1 day',
      '+5562911111111', 'ffffffff-ffff-ffff-ffff-ffffffffffff' -- nunca inserido
    from _wa0023_fisios where rn = 1;
    raise exception 'FALHA teste 5: consent_id inexistente foi aceito';
  exception
    when others then
      if sqlerrm like '%consentimento ativo incompativel%' or sqlerrm like '%foreign key%' then
        raise notice 'OK teste 5: consent_id inexistente foi rejeitado (%)', sqlerrm;
      else raise; end if;
  end;
end $$;

-- ======================================================================
-- TESTE 6 — consent de OUTRO patient (mesmo fisio) -> rejeitado.
-- ======================================================================

do $$
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0023_patient_a1__', '__wa0023_appt_a__', 'appointment_12h', 0, now() + interval '1 day',
      '+5562911111111', 'aaaaaaaa-0000-0000-0000-00000000a002' -- consent do patient_a2
    from _wa0023_fisios where rn = 1;
    raise exception 'FALHA teste 6: consent de outro patient foi aceito';
  exception
    when others then
      if sqlerrm like '%consentimento ativo incompativel%' or sqlerrm like '%foreign key%' then
        raise notice 'OK teste 6: consent de outro patient (mesmo fisio) foi rejeitado (%)', sqlerrm;
      else raise; end if;
  end;
end $$;

-- ======================================================================
-- TESTE 7 — consent de OUTRO fisioterapeuta -> rejeitado.
-- ======================================================================

do $$
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0023_patient_a1__', '__wa0023_appt_a__', 'appointment_12h', 0, now() + interval '1 day',
      '+5562911111111', 'bbbbbbbb-0000-0000-0000-00000000b001' -- consent do fisio B
    from _wa0023_fisios where rn = 1;
    raise exception 'FALHA teste 7: consent de outro fisioterapeuta foi aceito';
  exception
    when others then
      if sqlerrm like '%consentimento ativo incompativel%' or sqlerrm like '%foreign key%' then
        raise notice 'OK teste 7: consent de outro fisioterapeuta foi rejeitado (%)', sqlerrm;
      else raise; end if;
  end;
end $$;

-- ======================================================================
-- TESTE 26 — consent correto, mas destination_phone_e164 diferente de
-- contact_value -> rejeitado.
-- ======================================================================

do $$
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0023_patient_a1__', '__wa0023_appt_a__', 'appointment_12h', 0, now() + interval '1 day',
      '+5562999999999', 'aaaaaaaa-0000-0000-0000-00000000a001' -- consent_a1.contact_value e +5562911111111
    from _wa0023_fisios where rn = 1;
    raise exception 'FALHA teste 26: destination_phone_e164 diferente de contact_value foi aceito';
  exception
    when others then
      if sqlerrm like '%consentimento ativo incompativel%' then
        raise notice 'OK teste 26: destination_phone_e164 != contact_value foi rejeitado';
      else raise; end if;
  end;
end $$;

-- ======================================================================
-- TESTE 27 — consent correto do paciente/fisio, mas channel != whatsapp
-- -> rejeitado.
-- ======================================================================

do $$
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0023_patient_a1__', '__wa0023_appt_a__', 'appointment_12h', 0, now() + interval '1 day',
      '+5562911111111', 'aaaaaaaa-0000-0000-0000-00000000a003' -- channel='sms'
    from _wa0023_fisios where rn = 1;
    raise exception 'FALHA teste 27: consent de channel != whatsapp foi aceito';
  exception
    when others then
      if sqlerrm like '%consentimento ativo incompativel%' then
        raise notice 'OK teste 27: consent com channel != whatsapp foi rejeitado';
      else raise; end if;
  end;
end $$;

-- ======================================================================
-- TESTE 28 — consent correto do paciente/fisio, mas purpose !=
-- appointment_reminder -> rejeitado.
-- ======================================================================

do $$
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0023_patient_a1__', '__wa0023_appt_a__', 'appointment_12h', 0, now() + interval '1 day',
      '+5562911111111', 'aaaaaaaa-0000-0000-0000-00000000a004' -- purpose='marketing'
    from _wa0023_fisios where rn = 1;
    raise exception 'FALHA teste 28: consent de purpose != appointment_reminder foi aceito';
  exception
    when others then
      if sqlerrm like '%consentimento ativo incompativel%' then
        raise notice 'OK teste 28: consent com purpose != appointment_reminder foi rejeitado';
      else raise; end if;
  end;
end $$;

-- ======================================================================
-- TESTE 29 — consent já revoked_at != NULL -> rejeitado.
-- ======================================================================

do $$
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0023_patient_a1__', '__wa0023_appt_a__', 'appointment_12h', 0, now() + interval '1 day',
      '+5562911111111', 'aaaaaaaa-0000-0000-0000-00000000a005' -- ja revogado
    from _wa0023_fisios where rn = 1;
    raise exception 'FALHA teste 29: consent ja revogado foi aceito';
  exception
    when others then
      if sqlerrm like '%consentimento ativo incompativel%' then
        raise notice 'OK teste 29: consent ja revogado (revoked_at != NULL) foi rejeitado';
      else raise; end if;
  end;
end $$;

-- ======================================================================
-- TESTE 30 — consent ativo + whatsapp + appointment_reminder +
-- contact_value exatamente igual -> aceito (2a linha válida, tipo diferente).
-- ======================================================================

insert into public.whatsapp_messages
  (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
   destination_phone_e164, consent_id)
select fisio_id, '__wa0023_patient_a1__', '__wa0023_appt_a__', 'appointment_12h', 0, now() + interval '12 hours',
  '+5562911111111', 'aaaaaaaa-0000-0000-0000-00000000a001'
from _wa0023_fisios where rn = 1;

do $$
declare v_count int;
begin
  select count(*) into v_count from public.whatsapp_messages
  where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_12h' and schedule_revision = 0;
  if v_count <> 1 then raise exception 'FALHA teste 30: INSERT valido (consent ativo+whatsapp+appointment_reminder+telefone igual) nao foi aceito'; end if;
  raise notice 'OK teste 30: consent ativo + whatsapp + appointment_reminder + contact_value igual -> aceito';
end $$;

-- ======================================================================
-- TESTES 9-15 — tentativas de UPDATE nos 8 campos de identidade ->
-- todas bloqueadas pelo trigger (RAISE EXCEPTION).
-- ======================================================================

do $$
begin
  begin
    update public.whatsapp_messages set fisioterapeuta_id = (select fisio_id from _wa0023_fisios where rn = 2)
    where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;
    raise exception 'FALHA teste 9: UPDATE de fisioterapeuta_id foi aceito';
  exception
    when others then
      if sqlerrm like '%imutaveis%' then raise notice 'OK teste 9: UPDATE de fisioterapeuta_id bloqueado pelo trigger';
      else raise; end if;
  end;
end $$;

do $$
begin
  begin
    update public.whatsapp_messages set patient_id = '__wa0023_patient_a2__'
    where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;
    raise exception 'FALHA teste 10: UPDATE de patient_id foi aceito';
  exception
    when others then
      if sqlerrm like '%imutaveis%' then raise notice 'OK teste 10: UPDATE de patient_id bloqueado pelo trigger';
      else raise; end if;
  end;
end $$;

do $$
begin
  begin
    update public.whatsapp_messages set appointment_id = '__wa0023_appt_a2__'
    where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;
    raise exception 'FALHA teste 12: UPDATE de appointment_id foi aceito';
  exception
    when others then
      if sqlerrm like '%imutaveis%' then raise notice 'OK teste 12: UPDATE de appointment_id bloqueado pelo trigger';
      else raise; end if;
  end;
end $$;

do $$
begin
  begin
    update public.whatsapp_messages set reminder_type = 'appointment_rescheduled'
    where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;
    raise exception 'FALHA teste 13: UPDATE de reminder_type foi aceito';
  exception
    when others then
      if sqlerrm like '%imutaveis%' then raise notice 'OK teste 13: UPDATE de reminder_type bloqueado pelo trigger';
      else raise; end if;
  end;
end $$;

do $$
begin
  begin
    update public.whatsapp_messages set schedule_revision = 1
    where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;
    raise exception 'FALHA teste 14: UPDATE de schedule_revision foi aceito';
  exception
    when others then
      if sqlerrm like '%imutaveis%' then raise notice 'OK teste 14: UPDATE de schedule_revision bloqueado pelo trigger';
      else raise; end if;
  end;
end $$;

do $$
begin
  begin
    update public.whatsapp_messages set scheduled_for = now() + interval '30 days'
    where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;
    raise exception 'FALHA teste 15: UPDATE de scheduled_for foi aceito';
  exception
    when others then
      if sqlerrm like '%imutaveis%' then raise notice 'OK teste 15: UPDATE de scheduled_for bloqueado pelo trigger';
      else raise; end if;
  end;
end $$;

do $$
begin
  begin
    update public.whatsapp_messages set destination_phone_e164 = '+5562999999999'
    where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;
    raise exception 'FALHA (destination_phone_e164): UPDATE foi aceito';
  exception
    when others then
      if sqlerrm like '%imutaveis%' then raise notice 'OK: UPDATE de destination_phone_e164 bloqueado pelo trigger';
      else raise; end if;
  end;
end $$;

do $$
begin
  begin
    update public.whatsapp_messages set consent_id = 'aaaaaaaa-0000-0000-0000-00000000a002'
    where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;
    raise exception 'FALHA (consent_id): UPDATE foi aceito';
  exception
    when others then
      if sqlerrm like '%imutaveis%' then raise notice 'OK: UPDATE de consent_id bloqueado pelo trigger';
      else raise; end if;
  end;
end $$;

-- ======================================================================
-- TESTES 16-21 — campos operacionais continuam livremente atualizáveis.
-- ======================================================================

update public.whatsapp_messages set status = 'processing'
where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;

do $$
declare v_status text;
begin
  select status into v_status from public.whatsapp_messages
  where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;
  if v_status <> 'processing' then raise exception 'FALHA teste 17: UPDATE status scheduled->processing nao foi aplicado'; end if;
  raise notice 'OK teste 17: UPDATE status scheduled->processing continua permitido';
end $$;

update public.whatsapp_messages set status = 'cancelled'
where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;

do $$
declare v_status text;
begin
  select status into v_status from public.whatsapp_messages
  where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;
  if v_status <> 'cancelled' then raise exception 'FALHA teste 16: UPDATE status ->cancelled nao foi aplicado'; end if;
  raise notice 'OK teste 16: UPDATE status ->cancelled continua permitido';
end $$;

update public.whatsapp_messages set wamid = 'wamid-teste-0023'
where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;

update public.whatsapp_messages
set sent_at = now(), delivered_at = now(), read_at = now(), failed_at = now()
where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;

update public.whatsapp_messages
set error = '{"motivo":"teste"}'::jsonb, template_name = 'template_teste'
where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;

do $$
declare v_updated_at timestamptz; v_template text;
begin
  -- NOTA: touch_updated_at() usa now(), fixo durante toda esta transacao
  -- de teste -- por isso nao comparamos updated_at antes/depois
  -- numericamente aqui. Em producao cada UPDATE via PostgREST e sua
  -- PROPRIA transacao.
  update public.whatsapp_messages set template_name = 'template_teste_2'
  where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;

  select updated_at, template_name into v_updated_at, v_template from public.whatsapp_messages
  where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;

  if v_updated_at is null then raise exception 'FALHA teste 21: updated_at ficou nulo'; end if;
  if v_template <> 'template_teste_2' then raise exception 'FALHA teste 20: template_name nao foi atualizado'; end if;

  raise notice 'OK testes 18/19/20/21: wamid, sent_at/delivered_at/read_at/failed_at, error/template_name continuam atualizaveis; touch_updated_at continua disparando sem erro junto com o novo trigger (updated_at=%)', v_updated_at;
end $$;

-- ======================================================================
-- TESTE 22 — UNIQUE appointment_id+reminder_type+schedule_revision
-- continua intacta. (Precisa rodar ANTES de revogar consent_a1 no teste
-- 31 -- senão esta tentativa seria rejeitada pela validacao de
-- consentimento, nao pela UNIQUE, mascarando o que este teste quer provar.)
-- ======================================================================

do $$
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0023_patient_a1__', '__wa0023_appt_a__', 'appointment_confirmation', 0, now() + interval '1 day',
      '+5562911111111', 'aaaaaaaa-0000-0000-0000-00000000a001'
    from _wa0023_fisios where rn = 1;
    raise exception 'FALHA teste 22: UNIQUE appointment_id+reminder_type+schedule_revision nao impediu duplicata';
  exception
    when unique_violation then
      raise notice 'OK teste 22: UNIQUE appointment_id+reminder_type+schedule_revision continua intacta (bloqueou duplicata)';
  end;
end $$;

-- ======================================================================
-- TESTES 23 e 24 — RLS/policies/grants inalterados.
-- ======================================================================

do $$
declare
  v_policy_count int;
  v_rls boolean;
  v_write_grants int;
begin
  select count(*) into v_policy_count from pg_policies where schemaname='public' and tablename='whatsapp_messages';
  select relrowsecurity into v_rls from pg_class where oid='public.whatsapp_messages'::regclass;
  select count(*) into v_write_grants from information_schema.table_privileges
    where table_schema='public' and table_name='whatsapp_messages' and grantee='authenticated'
    and privilege_type in ('INSERT','UPDATE','DELETE');

  if v_policy_count <> 1 then raise exception 'FALHA teste 23: numero de policies mudou (esperado 1, veio %)', v_policy_count; end if;
  if v_rls is not true then raise exception 'FALHA teste 23: RLS nao esta mais ligada'; end if;
  raise notice 'OK teste 23: RLS/policies de whatsapp_messages inalteradas (1 policy, RLS ligada)';

  if v_write_grants <> 0 then raise exception 'FALHA teste 24: authenticated ganhou grant de escrita (%)', v_write_grants; end if;
  raise notice 'OK teste 24: authenticated continua sem INSERT/UPDATE/DELETE em whatsapp_messages';
end $$;

-- ======================================================================
-- TESTE: ordem entre os 2 triggers BEFORE UPDATE não interfere (seção 4
-- do pedido) — um UPDATE operacional (ex.: status) continua funcionando
-- normalmente com os DOIS triggers ativos (já provado acima nos testes
-- 16-21, que rodaram com os dois triggers presentes); confirmando
-- explicitamente a lista de triggers esperada.
-- ======================================================================

do $$
declare v_trigger_count int;
begin
  select count(*) into v_trigger_count from pg_trigger
  where tgrelid = 'public.whatsapp_messages'::regclass and not tgisinternal;
  if v_trigger_count <> 2 then
    raise exception 'FALHA: esperava exatamente 2 triggers em whatsapp_messages (touch_updated_at + validate_and_protect), veio %', v_trigger_count;
  end if;
  raise notice 'OK: exatamente 2 triggers em whatsapp_messages (whatsapp_messages_touch_updated_at + whatsapp_messages_validate_and_protect), sem duplicação';
end $$;

-- ======================================================================
-- TESTES 31 e 32 — revogar o consentimento DEPOIS que a mensagem já
-- existe continua permitido e não viola a FK; a mensagem histórica
-- mantém destination_phone_e164/consent_id originais.
-- ======================================================================

do $$
declare
  v_destination_antes text;
  v_consent_antes uuid;
  v_destination_depois text;
  v_consent_depois uuid;
begin
  select destination_phone_e164, consent_id into v_destination_antes, v_consent_antes
  from public.whatsapp_messages
  where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_12h' and schedule_revision = 0;

  -- TESTE 31: revogar consent_a1 agora que já existe mensagem
  -- referenciando-o -- não deve violar a FK composta nem nenhuma outra
  -- constraint (a FK de whatsapp_messages_consent_owner_fkey não depende
  -- de revoked_at).
  update public.patient_consents set revoked_at = now()
  where id = 'aaaaaaaa-0000-0000-0000-00000000a001';

  raise notice 'OK teste 31: revogar o consentimento depois da mensagem existir foi permitido (sem violar FK)';

  -- TESTE 32: a linha histórica continua com os valores originais.
  select destination_phone_e164, consent_id into v_destination_depois, v_consent_depois
  from public.whatsapp_messages
  where appointment_id = '__wa0023_appt_a__' and reminder_type = 'appointment_12h' and schedule_revision = 0;

  if v_destination_depois is distinct from v_destination_antes or v_consent_depois is distinct from v_consent_antes then
    raise exception 'FALHA teste 32: destination_phone_e164/consent_id da mensagem historica mudaram apos a revogacao';
  end if;
  raise notice 'OK teste 32: mensagem historica continua com destination_phone_e164=% e consent_id=% (inalterados apos a revogacao)', v_destination_depois, v_consent_depois;
end $$;

select 'rollback_ok' as resultado, 'nada disto sera persistido' as nota;

rollback;
