-- TESTE FUNCIONAL pós-aplicação da 0020 (já aplicada de verdade). Roda
-- contra o schema JÁ migrado, mas tudo dentro de uma transação que
-- termina em ROLLBACK — nenhum dado de teste fica em produção.
--
--   npx.cmd supabase db query -f supabase/rollout-0020/07_postapply_functional_dry_run.sql --linked --project-ref lchaboncmgcimafpupad

begin;

create temporary table _wa_fisio as
select fisioterapeuta_id as fisio_id from public.appointments limit 1;

create temporary table _wa_target as
select a.id as appointment_id, a.patient_id, a.fisioterapeuta_id as fisio_id
from public.appointments a
where a.patient_id is not null
limit 1;

do $$
declare
  v_fisio uuid;
  v_rev int;
begin
  select fisio_id into v_fisio from _wa_fisio;

  -- 1) INSERT forca revision 0.
  insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status)
  values ('__wa0020_post_t1__', v_fisio, '2026-11-01', '14:00:00', 'TESTE POS-APLICACAO - IGNORAR', 'scheduled');
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_post_t1__';
  if v_rev <> 0 then raise exception 'FALHA: INSERT nao comecou em revision 0 (veio %)', v_rev; end if;
  raise notice 'OK: INSERT forca revision 0';

  -- 2) Alterar so patient_name nao incrementa.
  update public.appointments set patient_name = 'TESTE POS-APLICACAO - RENOMEADO' where id = '__wa0020_post_t1__';
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_post_t1__';
  if v_rev <> 0 then raise exception 'FALHA: patient_name incrementou revision (veio %)', v_rev; end if;
  raise notice 'OK: alterar so patient_name nao incrementa revision';

  -- 3) Alterar so status nao incrementa.
  update public.appointments set status = 'confirmed' where id = '__wa0020_post_t1__';
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_post_t1__';
  if v_rev <> 0 then raise exception 'FALHA: status incrementou revision (veio %)', v_rev; end if;
  raise notice 'OK: alterar so status nao incrementa revision';

  -- 4) Alterar date incrementa.
  update public.appointments set date = '2026-11-02' where id = '__wa0020_post_t1__';
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_post_t1__';
  if v_rev <> 1 then raise exception 'FALHA: alterar date nao incrementou para 1 (veio %)', v_rev; end if;
  raise notice 'OK: alterar date incrementa revision (agora %)', v_rev;

  -- 5) Alterar time incrementa.
  update public.appointments set time = '15:00:00' where id = '__wa0020_post_t1__';
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_post_t1__';
  if v_rev <> 2 then raise exception 'FALHA: alterar time nao incrementou para 2 (veio %)', v_rev; end if;
  raise notice 'OK: alterar time incrementa revision (agora %)', v_rev;

  -- 6) date+time no mesmo UPDATE incrementam so 1 vez.
  update public.appointments set date = '2026-11-03', time = '16:00:00' where id = '__wa0020_post_t1__';
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_post_t1__';
  if v_rev <> 3 then raise exception 'FALHA: date+time juntos nao incrementaram so 1 vez (veio %)', v_rev; end if;
  raise notice 'OK: date+time no mesmo UPDATE incrementam so 1 vez (agora %)', v_rev;

  -- 7) Tentativa manual de manipular revision eh ignorada pelo trigger.
  update public.appointments set schedule_revision = 999 where id = '__wa0020_post_t1__'; -- sem mudar horario
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_post_t1__';
  if v_rev <> 3 then raise exception 'FALHA: cliente conseguiu setar revision=999 sem mudar horario (veio %)', v_rev; end if;

  update public.appointments set date = '2026-11-04', schedule_revision = 777 where id = '__wa0020_post_t1__'; -- com mudanca de horario
  select schedule_revision into v_rev from public.appointments where id = '__wa0020_post_t1__';
  if v_rev <> 4 then raise exception 'FALHA: revision arbitraria enviada com mudanca de horario nao foi ignorada (esperado OLD+1=4, veio %)', v_rev; end if;
  raise notice 'OK: manipulacao manual de revision (com ou sem mudanca de horario) eh sempre ignorada pelo trigger';
end $$;

do $$
declare
  v_appt text;
  v_patient text;
  v_fisio uuid;
begin
  select appointment_id, patient_id, fisio_id into v_appt, v_patient, v_fisio from _wa_target;

  -- 8) confirmation revision 0 aceita.
  insert into public.whatsapp_messages
    (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
  values (v_fisio, v_patient, v_appt, 'appointment_confirmation', 'scheduled', now(), 0);
  raise notice 'OK: appointment_confirmation revision 0 aceita';

  -- 9) confirmation revision >0 rejeita.
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
    values (v_fisio, v_patient, v_appt, 'appointment_confirmation', 'scheduled', now(), 1);
    raise exception 'FALHA: confirmation revision 1 deveria ter sido rejeitada';
  exception when check_violation then
    raise notice 'OK: appointment_confirmation revision 1 rejeitada pelo CHECK';
  end;

  -- 10) rescheduled revision 0 rejeita.
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
    values (v_fisio, v_patient, v_appt, 'appointment_rescheduled', 'scheduled', now(), 0);
    raise exception 'FALHA: rescheduled revision 0 deveria ter sido rejeitada';
  exception when check_violation then
    raise notice 'OK: appointment_rescheduled revision 0 rejeitada pelo CHECK';
  end;

  -- 11) rescheduled revision >=1 aceita.
  insert into public.whatsapp_messages
    (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
  values (v_fisio, v_patient, v_appt, 'appointment_rescheduled', 'scheduled', now(), 1);
  raise notice 'OK: appointment_rescheduled revision 1 aceita';

  -- 12) appointment_12h em revisoes diferentes aceita.
  insert into public.whatsapp_messages
    (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
  values (v_fisio, v_patient, v_appt, 'appointment_12h', 'scheduled', now(), 0);
  insert into public.whatsapp_messages
    (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
  values (v_fisio, v_patient, v_appt, 'appointment_12h', 'scheduled', now(), 1);
  raise notice 'OK: appointment_12h aceito em revisoes diferentes (0 e 1)';

  -- 13) duplicata do mesmo appointment+tipo+revision rejeita.
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, status, scheduled_for, schedule_revision)
    values (v_fisio, v_patient, v_appt, 'appointment_12h', 'scheduled', now(), 0);
    raise exception 'FALHA: duplicata appointment_12h na revision 0 deveria ter sido rejeitada';
  exception when unique_violation then
    raise notice 'OK: duplicata do mesmo appointment+tipo+revision rejeitada pela UNIQUE';
  end;
end $$;

select 'rollback_ok' as resultado, 'nenhum dado de teste persistido' as nota;

rollback;
