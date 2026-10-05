-- VALIDAÇÃO LOCAL COMPLETA da 0020 (v2 — schedule_revision) contra o
-- schema real de produção, SEM aplicar nada: tudo roda dentro de uma
-- transação que termina em ROLLBACK, nunca em COMMIT.
--
--   npx.cmd supabase db query -f supabase/rollout-0020/00_dry_run_full_validation.sql --linked --project-ref lchaboncmgcimafpupad
--
-- Cobre os 20 testes pedidos. Cada bloco "raise notice 'OK ...'" só
-- aparece se a asserção correspondente passou; qualquer falha dispara
-- "raise exception 'FALHA ...'" e aborta a transação inteira (nada é
-- persistido de qualquer forma, por causa do ROLLBACK final).

begin;

-- ======================================================================
-- PARTE 1 — aplica a migration 0020 (idêntico ao arquivo real)
-- ======================================================================

alter table public.appointments
  add column if not exists schedule_revision integer not null default 0;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'appointments_schedule_revision_non_negative'
      and conrelid = 'public.appointments'::regclass
  ) then
    alter table public.appointments
      add constraint appointments_schedule_revision_non_negative
      check (schedule_revision >= 0);
  end if;
end $$;

create or replace function public.set_appointment_schedule_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.schedule_revision = 0;
  elsif tg_op = 'UPDATE' then
    if new.date is distinct from old.date or new.time is distinct from old.time then
      new.schedule_revision = old.schedule_revision + 1;
    else
      new.schedule_revision = old.schedule_revision;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists appointments_set_schedule_revision on public.appointments;
create trigger appointments_set_schedule_revision
  before insert or update on public.appointments
  for each row execute function public.set_appointment_schedule_revision();

do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_reminder_type_valid'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      drop constraint whatsapp_messages_reminder_type_valid;
  end if;
  alter table public.whatsapp_messages
    add constraint whatsapp_messages_reminder_type_valid
    check (reminder_type in ('appointment_confirmation', 'appointment_12h', 'appointment_rescheduled'));
end $$;

alter table public.whatsapp_messages
  add column if not exists schedule_revision integer not null default 0;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_schedule_revision_non_negative'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_schedule_revision_non_negative
      check (schedule_revision >= 0);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_schedule_revision_matches_type'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_schedule_revision_matches_type
      check (
        (reminder_type = 'appointment_confirmation' and schedule_revision = 0)
        or (reminder_type = 'appointment_rescheduled' and schedule_revision >= 1)
        or (reminder_type = 'appointment_12h' and schedule_revision >= 0)
      );
  end if;
end $$;

alter table public.whatsapp_messages
  drop constraint if exists whatsapp_messages_one_per_appointment_type;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_one_per_appointment_revision'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_one_per_appointment_revision
      unique (appointment_id, reminder_type, schedule_revision);
  end if;
end $$;

select 'migration aplicada (1a vez)' as fase;

-- ======================================================================
-- PARTE 2 — contexto de teste (ancorado em dados REAIS, sem modificá-los)
-- ======================================================================

create temporary table _wa_fisio as
select fisioterapeuta_id as fisio_id from public.appointments limit 1;

create temporary table _wa_target as
select a.id as appointment_id, a.patient_id, a.fisioterapeuta_id as fisio_id
from public.appointments a
where a.patient_id is not null
limit 1;

-- ======================================================================
-- PARTE 3 — testes 1 a 9: o trigger de schedule_revision em appointments
-- (usa agendamentos FICTÍCIOS e descartáveis, nunca os 65 reais)
-- ======================================================================

do $$
declare
  v_fisio uuid;
  v_rev int;
begin
  select fisio_id into v_fisio from _wa_fisio;

  -- 1) INSERT comeca em revision 0.
  insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status)
  values ('__wa0020_t1__', v_fisio, '2026-10-10', '14:00:00', 'TESTE 0020 - IGNORAR', 'scheduled');
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_t1__';
  if v_rev <> 0 then raise exception 'FALHA teste 1: esperado 0, veio %', v_rev; end if;
  raise notice 'OK teste 1: INSERT comeca em revision 0';

  -- 2) Cliente tenta inserir com revision=50 explicita -> banco forca 0.
  insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status, schedule_revision)
  values ('__wa0020_t2__', v_fisio, '2026-10-10', '14:00:00', 'TESTE 0020 - IGNORAR', 'scheduled', 50);
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_t2__';
  if v_rev <> 0 then raise exception 'FALHA teste 2: cliente conseguiu setar revision=50 no INSERT, veio %', v_rev; end if;
  raise notice 'OK teste 2: INSERT com revision=50 do cliente foi ignorado (ficou 0)';
  delete from public.appointments where id = '__wa0020_t2__';

  -- 3) Editar so patient_name -> revision igual.
  update public.appointments set patient_name = 'TESTE 0020 - RENOMEADO' where id = '__wa0020_t1__';
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_t1__';
  if v_rev <> 0 then raise exception 'FALHA teste 3: editar patient_name mudou revision para %', v_rev; end if;
  raise notice 'OK teste 3: editar patient_name nao muda revision';

  -- 4) Editar so status -> revision igual.
  update public.appointments set status = 'confirmed' where id = '__wa0020_t1__';
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_t1__';
  if v_rev <> 0 then raise exception 'FALHA teste 4: editar status mudou revision para %', v_rev; end if;
  raise notice 'OK teste 4: editar status nao muda revision';

  -- 5) Alterar date -> +1.
  update public.appointments set date = '2026-10-11' where id = '__wa0020_t1__';
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_t1__';
  if v_rev <> 1 then raise exception 'FALHA teste 5: esperado 1, veio %', v_rev; end if;
  raise notice 'OK teste 5: alterar date incrementa revision (agora %)', v_rev;

  -- 6) Alterar time -> +1.
  update public.appointments set time = '15:00:00' where id = '__wa0020_t1__';
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_t1__';
  if v_rev <> 2 then raise exception 'FALHA teste 6: esperado 2, veio %', v_rev; end if;
  raise notice 'OK teste 6: alterar time incrementa revision (agora %)', v_rev;

  -- 7) Alterar date e time juntos -> incrementa so 1 vez.
  update public.appointments set date = '2026-10-12', time = '16:00:00' where id = '__wa0020_t1__';
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_t1__';
  if v_rev <> 3 then raise exception 'FALHA teste 7: esperado 3 (incremento unico), veio %', v_rev; end if;
  raise notice 'OK teste 7: alterar date+time juntos incrementa so 1 vez (agora %)', v_rev;

  -- 8) Cliente tenta mudar revision manualmente SEM mudar horario -> banco restaura OLD.
  update public.appointments set schedule_revision = 999 where id = '__wa0020_t1__';
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_t1__';
  if v_rev <> 3 then raise exception 'FALHA teste 8: cliente conseguiu setar 999 sem mudar horario, veio %', v_rev; end if;
  raise notice 'OK teste 8: tentativa de setar revision=999 sem mudar horario foi ignorada (ficou %)', v_rev;

  -- 9) Cliente manda revision arbitraria JUNTO com mudanca de horario -> banco usa OLD+1.
  update public.appointments set date = '2026-10-13', schedule_revision = 777 where id = '__wa0020_t1__';
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_t1__';
  if v_rev <> 4 then raise exception 'FALHA teste 9: esperado OLD+1=4, veio %', v_rev; end if;
  raise notice 'OK teste 9: revision arbitraria (777) enviada junto com mudanca de horario foi ignorada; banco usou OLD+1 = %', v_rev;
end $$;

-- ======================================================================
-- PARTE 4 — teste 18: A -> B -> A -> B (feito aqui, antes dos testes de
-- whatsapp_messages, para isolar do appointment usado nos testes 10-17)
-- ======================================================================

do $$
declare
  v_fisio uuid;
  v_rev int;
begin
  select fisio_id into v_fisio from _wa_fisio;

  insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status)
  values ('__wa0020_abab__', v_fisio, '2026-10-01', '09:00:00', 'TESTE 0020 - ABAB', 'scheduled'); -- A, revision 0

  update public.appointments set date = '2026-10-02' where id = '__wa0020_abab__'; -- B, revision 1
  update public.appointments set date = '2026-10-01' where id = '__wa0020_abab__'; -- A de novo, revision 2
  update public.appointments set date = '2026-10-02' where id = '__wa0020_abab__'; -- B de novo, revision 3

  select schedule_revision into v_rev from public.appointments where id = '__wa0020_abab__';
  if v_rev <> 3 then raise exception 'FALHA teste 18: esperado revision 3 apos A->B->A->B, veio %', v_rev; end if;
  raise notice 'OK teste 18: A->B->A->B termina em revision 3 sem colisao (0,1,2,3 identificadas pelo contador, nao pelo valor de data/hora)';
end $$;

-- ======================================================================
-- PARTE 5 — testes 10 a 17: constraints de whatsapp_messages
-- (ancorados num appointment+patient REAIS, só para satisfazer as FKs
-- compostas herdadas da 0018 — nenhum dado real é alterado)
-- ======================================================================

do $$
declare
  v_appt text;
  v_patient text;
  v_fisio uuid;
begin
  select appointment_id, patient_id, fisio_id into v_appt, v_patient, v_fisio from _wa_target;

  -- 10) confirmation revision 0 -> aceita.
  insert into public.whatsapp_messages
    (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
  values (v_fisio, v_patient, v_appt, 'appointment_confirmation', 'scheduled', now(), 0);
  raise notice 'OK teste 10: appointment_confirmation revision 0 aceita';

  -- 11) confirmation revision >0 -> rejeita.
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
    values (v_fisio, v_patient, v_appt, 'appointment_confirmation', 'scheduled', now(), 1);
    raise exception 'FALHA teste 11: confirmation revision 1 deveria ter sido rejeitada';
  exception when check_violation then
    raise notice 'OK teste 11: appointment_confirmation revision 1 rejeitada pelo CHECK de coerencia';
  end;

  -- 12) rescheduled revision 0 -> rejeita.
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
    values (v_fisio, v_patient, v_appt, 'appointment_rescheduled', 'scheduled', now(), 0);
    raise exception 'FALHA teste 12: rescheduled revision 0 deveria ter sido rejeitada';
  exception when check_violation then
    raise notice 'OK teste 12: appointment_rescheduled revision 0 rejeitada pelo CHECK de coerencia';
  end;

  -- 13) rescheduled revisions 1 e 2 -> aceita.
  insert into public.whatsapp_messages
    (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
  values (v_fisio, v_patient, v_appt, 'appointment_rescheduled', 'scheduled', now(), 1);
  insert into public.whatsapp_messages
    (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
  values (v_fisio, v_patient, v_appt, 'appointment_rescheduled', 'scheduled', now(), 2);
  raise notice 'OK teste 13: appointment_rescheduled revisions 1 e 2 aceitas';

  -- 14) appointment_12h revisions 0, 1 e 2 -> aceita.
  insert into public.whatsapp_messages
    (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
  values (v_fisio, v_patient, v_appt, 'appointment_12h', 'scheduled', now(), 0);
  insert into public.whatsapp_messages
    (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
  values (v_fisio, v_patient, v_appt, 'appointment_12h', 'scheduled', now(), 1);
  insert into public.whatsapp_messages
    (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
  values (v_fisio, v_patient, v_appt, 'appointment_12h', 'scheduled', now(), 2);
  raise notice 'OK teste 14: appointment_12h revisions 0, 1 e 2 aceitas';

  -- 15) duas appointment_12h da mesma appointment+revision -> 2a rejeitada.
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
    values (v_fisio, v_patient, v_appt, 'appointment_12h', 'scheduled', now(), 0);
    raise exception 'FALHA teste 15: segunda appointment_12h na revision 0 deveria ter sido rejeitada';
  exception when unique_violation then
    raise notice 'OK teste 15: segunda appointment_12h na mesma revision rejeitada pela UNIQUE';
  end;

  -- 16) mesma appointment_12h em revisoes diferentes -> aceita (reforca o teste 14).
  if (select count(*) from public.whatsapp_messages where appointment_id = v_appt and reminder_type = 'appointment_12h') <> 3 then
    raise exception 'FALHA teste 16: deveriam existir 3 linhas de appointment_12h (revisions 0,1,2)';
  end if;
  raise notice 'OK teste 16: appointment_12h coexiste em revisoes diferentes (3 linhas)';

  -- 17) duas appointment_rescheduled na mesma revision -> 2a rejeitada.
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
    values (v_fisio, v_patient, v_appt, 'appointment_rescheduled', 'scheduled', now(), 1);
    raise exception 'FALHA teste 17: segunda appointment_rescheduled na revision 1 deveria ter sido rejeitada';
  exception when unique_violation then
    raise notice 'OK teste 17: segunda appointment_rescheduled na mesma revision rejeitada pela UNIQUE';
  end;
end $$;

-- ======================================================================
-- PARTE 6 — teste 19: aplicar a migration DE NOVO (idempotência)
-- ======================================================================

alter table public.appointments
  add column if not exists schedule_revision integer not null default 0;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'appointments_schedule_revision_non_negative'
      and conrelid = 'public.appointments'::regclass
  ) then
    alter table public.appointments
      add constraint appointments_schedule_revision_non_negative
      check (schedule_revision >= 0);
  end if;
end $$;
create or replace function public.set_appointment_schedule_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.schedule_revision = 0;
  elsif tg_op = 'UPDATE' then
    if new.date is distinct from old.date or new.time is distinct from old.time then
      new.schedule_revision = old.schedule_revision + 1;
    else
      new.schedule_revision = old.schedule_revision;
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists appointments_set_schedule_revision on public.appointments;
create trigger appointments_set_schedule_revision
  before insert or update on public.appointments
  for each row execute function public.set_appointment_schedule_revision();
do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_reminder_type_valid'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      drop constraint whatsapp_messages_reminder_type_valid;
  end if;
  alter table public.whatsapp_messages
    add constraint whatsapp_messages_reminder_type_valid
    check (reminder_type in ('appointment_confirmation', 'appointment_12h', 'appointment_rescheduled'));
end $$;
alter table public.whatsapp_messages
  add column if not exists schedule_revision integer not null default 0;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_schedule_revision_non_negative'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_schedule_revision_non_negative
      check (schedule_revision >= 0);
  end if;
end $$;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_schedule_revision_matches_type'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_schedule_revision_matches_type
      check (
        (reminder_type = 'appointment_confirmation' and schedule_revision = 0)
        or (reminder_type = 'appointment_rescheduled' and schedule_revision >= 1)
        or (reminder_type = 'appointment_12h' and schedule_revision >= 0)
      );
  end if;
end $$;
alter table public.whatsapp_messages
  drop constraint if exists whatsapp_messages_one_per_appointment_type;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_one_per_appointment_revision'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_one_per_appointment_revision
      unique (appointment_id, reminder_type, schedule_revision);
  end if;
end $$;

select 'OK teste 19: migration reaplicada uma 2a vez sem erro (idempotente)' as resultado;

-- ======================================================================
-- PARTE 7 — teste 20: rollback dentro da MESMA transação
-- ======================================================================

-- Limpa os dados de teste primeiro: a trava do rollback real recusa
-- (corretamente) apagar schedule_revision se existir qualquer appointment
-- com revision > 0 — e os de teste desta sessão têm. Isso simula
-- exatamente o estado real de produção agora (0 reagendamentos reais
-- rastreados), não um "jeito de burlar" a trava.
delete from public.whatsapp_messages where appointment_id in (select appointment_id from _wa_target);
delete from public.appointments where id in ('__wa0020_t1__', '__wa0020_abab__');

do $$
begin
  if exists (select 1 from public.whatsapp_messages where reminder_type <> 'appointment_12h') then
    raise exception 'FALHA teste 20 (setup): ainda ha whatsapp_messages de teste sobrando';
  end if;
  if exists (select 1 from public.appointments where schedule_revision > 0) then
    raise exception 'FALHA teste 20 (setup): ainda ha appointments de teste com revision > 0 sobrando';
  end if;
end $$;

-- Aplica o rollback (02_rollback.sql) na mesma transação, sem a trava
-- (já comprovamos acima que ela está limpa).
alter table public.whatsapp_messages drop constraint if exists whatsapp_messages_one_per_appointment_revision;
alter table public.whatsapp_messages drop constraint if exists whatsapp_messages_schedule_revision_matches_type;
alter table public.whatsapp_messages drop constraint if exists whatsapp_messages_schedule_revision_non_negative;
alter table public.whatsapp_messages drop column if exists schedule_revision;
do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_reminder_type_valid'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages drop constraint whatsapp_messages_reminder_type_valid;
  end if;
  alter table public.whatsapp_messages
    add constraint whatsapp_messages_reminder_type_valid
    check (reminder_type in ('appointment_12h'));
end $$;
alter table public.whatsapp_messages
  add constraint whatsapp_messages_one_per_appointment_type
  unique (appointment_id, reminder_type);

drop trigger if exists appointments_set_schedule_revision on public.appointments;
drop function if exists public.set_appointment_schedule_revision();
alter table public.appointments drop constraint if exists appointments_schedule_revision_non_negative;
alter table public.appointments drop column if exists schedule_revision;

-- Confirma que voltou exatamente ao estado pós-0019.
do $$
declare
  v_check text;
  v_appt_schedule_revision_exists boolean;
  v_wa_schedule_revision_exists boolean;
  v_old_unique_exists boolean;
  v_new_unique_exists boolean;
  v_trigger_exists boolean;
begin
  select pg_get_constraintdef(oid) into v_check
  from pg_constraint where conname = 'whatsapp_messages_reminder_type_valid' and conrelid = 'public.whatsapp_messages'::regclass;
  if v_check <> 'CHECK ((reminder_type = ''appointment_12h''::text))' then
    raise exception 'FALHA teste 20: CHECK de reminder_type nao voltou ao original (atual: %)', v_check;
  end if;

  select exists (select 1 from information_schema.columns where table_name='appointments' and column_name='schedule_revision') into v_appt_schedule_revision_exists;
  if v_appt_schedule_revision_exists then raise exception 'FALHA teste 20: appointments.schedule_revision ainda existe'; end if;

  select exists (select 1 from information_schema.columns where table_name='whatsapp_messages' and column_name='schedule_revision') into v_wa_schedule_revision_exists;
  if v_wa_schedule_revision_exists then raise exception 'FALHA teste 20: whatsapp_messages.schedule_revision ainda existe'; end if;

  select exists (select 1 from pg_constraint where conname='whatsapp_messages_one_per_appointment_type' and conrelid='public.whatsapp_messages'::regclass) into v_old_unique_exists;
  if not v_old_unique_exists then raise exception 'FALHA teste 20: UNIQUE antiga nao foi restaurada'; end if;

  select exists (select 1 from pg_constraint where conname='whatsapp_messages_one_per_appointment_revision' and conrelid='public.whatsapp_messages'::regclass) into v_new_unique_exists;
  if v_new_unique_exists then raise exception 'FALHA teste 20: UNIQUE nova ainda existe'; end if;

  select exists (select 1 from pg_trigger where tgname='appointments_set_schedule_revision' and not tgisinternal) into v_trigger_exists;
  if v_trigger_exists then raise exception 'FALHA teste 20: trigger de schedule_revision ainda existe'; end if;

  raise notice 'OK teste 20: migration + rollback na mesma transacao restauram exatamente o estado pos-0019';
end $$;

select 'rollback_ok' as resultado, 'nada disto sera persistido' as nota;

rollback;
