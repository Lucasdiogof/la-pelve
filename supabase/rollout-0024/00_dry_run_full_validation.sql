-- VALIDAÇÃO LOCAL COMPLETA da 0024 contra o schema real de produção, SEM
-- aplicar nada de verdade: tudo roda dentro de uma transação que termina
-- em ROLLBACK.
--
--   npx.cmd supabase db query -f supabase/rollout-0024/00_dry_run_full_validation.sql --linked --project-ref lchaboncmgcimafpupad
--
-- Cobre os 10 testes pedidos + 11-13 (BEFORE INSERT x ON CONFLICT, ver
-- adapter da materialização). Nenhum dado real hardcoded.

begin;

do $$
begin
  if exists (select 1 from public.whatsapp_messages limit 1) then
    raise exception 'PRE-CONDICAO FALHOU: whatsapp_messages nao esta vazia -- nao valido a 0024 contra dados reais';
  end if;
end $$;

-- Snapshot das linhas reais ANTES de qualquer fixture (comparado no teste 10).
create temporary table _wa0024_snapshot_antes as
select 'whatsapp_messages' as tabela, count(*) as linhas,
  md5(coalesce(string_agg(md5(t::text), ',' order by id), '')) as hash
from public.whatsapp_messages t
union all
select 'patient_consents', count(*), md5(coalesce(string_agg(md5(t::text), ',' order by id), ''))
from public.patient_consents t
union all
select 'patients', count(*), md5(coalesce(string_agg(md5(t::text), ',' order by id), ''))
from public.patients t
union all
select 'appointments', count(*), md5(coalesce(string_agg(md5(t::text), ',' order by id), ''))
from public.appointments t;

create temporary table _wa0024_ok (n serial, msg text);

-- ======================================================================
-- PARTE 1 — aplica a migration 0024 (idêntico ao arquivo real)
-- ======================================================================

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

select 'migration 0024 aplicada' as fase;

-- ======================================================================
-- TESTE 9 (parte 1) — triggers continuam exatamente os 2 esperados.
-- ======================================================================

do $$
declare v_count int;
begin
  select count(*) into v_count from pg_trigger
  where tgrelid='public.whatsapp_messages'::regclass and not tgisinternal;
  if v_count <> 2 then raise exception 'FALHA teste 9: esperava 2 triggers, veio %', v_count; end if;
  insert into _wa0024_ok(msg) values ('OK teste 9: exatamente 2 triggers em whatsapp_messages'); raise notice 'OK teste 9: exatamente 2 triggers em whatsapp_messages';
end $$;

-- ======================================================================
-- PARTE 2 — fixtures (1 fisioterapeuta REAL só por id; dados de
-- paciente/consentimento 100% fictícios e descartáveis).
-- ======================================================================

create temporary table _wa0024_fisios as
select id as fisio_id, row_number() over (order by id) as rn from public.profiles limit 1;

insert into public.patients (id, fisioterapeuta_id, phone_e164)
select '__wa0024_patient_a__', fisio_id, '+5562911111111' from _wa0024_fisios where rn = 1;

insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, patient_id, status)
select '__wa0024_appt_a__', fisio_id, '2026-12-05', '10:00:00', 'TESTE 0024 - IGNORAR', '__wa0024_patient_a__', 'scheduled'
from _wa0024_fisios where rn = 1;

-- consent ativo correto
insert into public.patient_consents (id, patient_id, fisioterapeuta_id, channel, purpose, contact_value, revoked_at)
select 'cccccccc-0000-0000-0000-00000000c001', '__wa0024_patient_a__', fisio_id, 'whatsapp', 'appointment_reminder', '+5562911111111', null
from _wa0024_fisios where rn = 1;
-- consent channel errado
insert into public.patient_consents (id, patient_id, fisioterapeuta_id, channel, purpose, contact_value, revoked_at)
select 'cccccccc-0000-0000-0000-00000000c002', '__wa0024_patient_a__', fisio_id, 'sms', 'appointment_reminder', '+5562911111111', null
from _wa0024_fisios where rn = 1;
-- consent purpose errado
insert into public.patient_consents (id, patient_id, fisioterapeuta_id, channel, purpose, contact_value, revoked_at)
select 'cccccccc-0000-0000-0000-00000000c003', '__wa0024_patient_a__', fisio_id, 'whatsapp', 'marketing', '+5562911111111', null
from _wa0024_fisios where rn = 1;
-- consent já revogado
insert into public.patient_consents (id, patient_id, fisioterapeuta_id, channel, purpose, contact_value, revoked_at)
select 'cccccccc-0000-0000-0000-00000000c004', '__wa0024_patient_a__', fisio_id, 'whatsapp', 'appointment_reminder', '+5562911111111', now()
from _wa0024_fisios where rn = 1;

select 'fixtures criados' as fase;

-- ======================================================================
-- TESTE 1 — INSERT válido continua aceitando.
-- ======================================================================

insert into public.whatsapp_messages
  (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
   destination_phone_e164, consent_id)
select fisio_id, '__wa0024_patient_a__', '__wa0024_appt_a__', 'appointment_confirmation', 0, now() + interval '1 day',
  '+5562911111111', 'cccccccc-0000-0000-0000-00000000c001'
from _wa0024_fisios where rn = 1;

do $$
declare v_count int;
begin
  select count(*) into v_count from public.whatsapp_messages
  where appointment_id = '__wa0024_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;
  if v_count <> 1 then raise exception 'FALHA teste 1: INSERT valido nao foi aceito'; end if;
  insert into _wa0024_ok(msg) values ('OK teste 1: INSERT valido continua aceitando'); raise notice 'OK teste 1: INSERT valido continua aceitando';
end $$;

-- ======================================================================
-- Helper repetido: tenta um INSERT que deveria ser rejeitado, e confirma
-- o SQLSTATE EXATO 'WA001' via GET STACKED DIAGNOSTICS (nao por texto).
-- ======================================================================

-- TESTE 2 — consentimento revogado -> rejeita com SQLSTATE 'WA001'.
do $$
declare v_sqlstate text;
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0024_patient_a__', '__wa0024_appt_a__', 'appointment_12h', 0, now() + interval '1 day',
      '+5562911111111', 'cccccccc-0000-0000-0000-00000000c004' -- revogado
    from _wa0024_fisios where rn = 1;
    raise exception 'FALHA teste 2: consentimento revogado foi aceito';
  exception
    when others then
      get stacked diagnostics v_sqlstate = returned_sqlstate;
      if v_sqlstate <> 'WA001' then
        raise exception 'FALHA teste 2: esperava SQLSTATE WA001, veio % (%)', v_sqlstate, sqlerrm;
      end if;
      insert into _wa0024_ok(msg) values ('OK teste 2: consentimento revogado rejeitado com SQLSTATE exato WA001'); raise notice 'OK teste 2: consentimento revogado rejeitado com SQLSTATE exato WA001';
  end;
end $$;

-- TESTE 3 — consentimento inexistente -> mesmo SQLSTATE.
do $$
declare v_sqlstate text;
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0024_patient_a__', '__wa0024_appt_a__', 'appointment_12h', 0, now() + interval '1 day',
      '+5562911111111', 'ffffffff-ffff-ffff-ffff-ffffffffffff' -- nunca inserido
    from _wa0024_fisios where rn = 1;
    raise exception 'FALHA teste 3: consentimento inexistente foi aceito';
  exception
    when others then
      get stacked diagnostics v_sqlstate = returned_sqlstate;
      if v_sqlstate <> 'WA001' then
        raise exception 'FALHA teste 3: esperava SQLSTATE WA001, veio % (%)', v_sqlstate, sqlerrm;
      end if;
      insert into _wa0024_ok(msg) values ('OK teste 3: consentimento inexistente rejeitado com SQLSTATE exato WA001'); raise notice 'OK teste 3: consentimento inexistente rejeitado com SQLSTATE exato WA001';
  end;
end $$;

-- TESTE 4 — destination_phone_e164 diferente de contact_value -> mesmo SQLSTATE.
do $$
declare v_sqlstate text;
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0024_patient_a__', '__wa0024_appt_a__', 'appointment_12h', 0, now() + interval '1 day',
      '+5562999999999', 'cccccccc-0000-0000-0000-00000000c001' -- contact_value real e +5562911111111
    from _wa0024_fisios where rn = 1;
    raise exception 'FALHA teste 4: telefone divergente foi aceito';
  exception
    when others then
      get stacked diagnostics v_sqlstate = returned_sqlstate;
      if v_sqlstate <> 'WA001' then
        raise exception 'FALHA teste 4: esperava SQLSTATE WA001, veio % (%)', v_sqlstate, sqlerrm;
      end if;
      insert into _wa0024_ok(msg) values ('OK teste 4: telefone divergente rejeitado com SQLSTATE exato WA001'); raise notice 'OK teste 4: telefone divergente rejeitado com SQLSTATE exato WA001';
  end;
end $$;

-- TESTE 5 — channel errado -> mesmo SQLSTATE.
do $$
declare v_sqlstate text;
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0024_patient_a__', '__wa0024_appt_a__', 'appointment_12h', 0, now() + interval '1 day',
      '+5562911111111', 'cccccccc-0000-0000-0000-00000000c002' -- channel='sms'
    from _wa0024_fisios where rn = 1;
    raise exception 'FALHA teste 5: channel errado foi aceito';
  exception
    when others then
      get stacked diagnostics v_sqlstate = returned_sqlstate;
      if v_sqlstate <> 'WA001' then
        raise exception 'FALHA teste 5: esperava SQLSTATE WA001, veio % (%)', v_sqlstate, sqlerrm;
      end if;
      insert into _wa0024_ok(msg) values ('OK teste 5: channel errado rejeitado com SQLSTATE exato WA001'); raise notice 'OK teste 5: channel errado rejeitado com SQLSTATE exato WA001';
  end;
end $$;

-- TESTE 6 — purpose errado -> mesmo SQLSTATE.
do $$
declare v_sqlstate text;
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0024_patient_a__', '__wa0024_appt_a__', 'appointment_12h', 0, now() + interval '1 day',
      '+5562911111111', 'cccccccc-0000-0000-0000-00000000c003' -- purpose='marketing'
    from _wa0024_fisios where rn = 1;
    raise exception 'FALHA teste 6: purpose errado foi aceito';
  exception
    when others then
      get stacked diagnostics v_sqlstate = returned_sqlstate;
      if v_sqlstate <> 'WA001' then
        raise exception 'FALHA teste 6: esperava SQLSTATE WA001, veio % (%)', v_sqlstate, sqlerrm;
      end if;
      insert into _wa0024_ok(msg) values ('OK teste 6: purpose errado rejeitado com SQLSTATE exato WA001'); raise notice 'OK teste 6: purpose errado rejeitado com SQLSTATE exato WA001';
  end;
end $$;

-- ======================================================================
-- TESTE 7 — UPDATE de campo imutável continua rejeitado.
-- ======================================================================

do $$
declare v_sqlstate text;
begin
  begin
    update public.whatsapp_messages set schedule_revision = 5
    where appointment_id = '__wa0024_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;
    raise exception using errcode = 'XX000', message = 'FALHA teste 7: UPDATE de schedule_revision foi aceito';
  exception
    when others then
      get stacked diagnostics v_sqlstate = returned_sqlstate;
      -- A branch de UPDATE fica como na 0023 (P0001 genérico) -- e NUNCA
      -- pode ser confundida com a rejeição de consentimento (WA001).
      if v_sqlstate = 'P0001' and sqlerrm like '%imutaveis%' then
        insert into _wa0024_ok(msg) values ('OK teste 7: UPDATE de campo imutavel continua rejeitado (SQLSTATE P0001, nao WA001)'); raise notice 'OK teste 7: UPDATE de campo imutavel continua rejeitado (SQLSTATE P0001, nao WA001)';
      else
        raise exception 'FALHA teste 7: veio SQLSTATE % (%)', v_sqlstate, sqlerrm;
      end if;
  end;
end $$;

-- ======================================================================
-- TESTE 8 — UPDATE permitido continua funcionando.
-- ======================================================================

update public.whatsapp_messages set status = 'cancelled'
where appointment_id = '__wa0024_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;

do $$
declare v_status text;
begin
  select status into v_status from public.whatsapp_messages
  where appointment_id = '__wa0024_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;
  if v_status <> 'cancelled' then raise exception 'FALHA teste 8: UPDATE de status nao foi aplicado'; end if;
  insert into _wa0024_ok(msg) values ('OK teste 8: UPDATE permitido (status) continua funcionando'); raise notice 'OK teste 8: UPDATE permitido (status) continua funcionando';
end $$;

-- ======================================================================
-- TESTE 11 — PROBLEMA 2, parte 1: conflito com consentimento ATIVO.
-- A tripla (appt_a, appointment_confirmation, 0) já existe (teste 1) e
-- c001 continua ativo -> INSERT ... ON CONFLICT DO NOTHING passa pelo
-- trigger, colide na UNIQUE e insere 0 linhas, sem erro e sem tocar a
-- linha existente. É o caminho da corrida entre dois schedulers.
-- ======================================================================

do $$
declare v_rows int; v_antes text; v_depois text;
begin
  select md5(t::text) into v_antes from public.whatsapp_messages t
  where appointment_id = '__wa0024_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;

  insert into public.whatsapp_messages
    (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
     destination_phone_e164, consent_id)
  select fisio_id, '__wa0024_patient_a__', '__wa0024_appt_a__', 'appointment_confirmation', 0, now() + interval '9 days',
    '+5562911111111', 'cccccccc-0000-0000-0000-00000000c001'
  from _wa0024_fisios where rn = 1
  on conflict (appointment_id, reminder_type, schedule_revision) do nothing;
  get diagnostics v_rows = row_count;

  select md5(t::text) into v_depois from public.whatsapp_messages t
  where appointment_id = '__wa0024_appt_a__' and reminder_type = 'appointment_confirmation' and schedule_revision = 0;

  if v_rows <> 0 then raise exception 'FALHA teste 11: ON CONFLICT DO NOTHING inseriu % linhas', v_rows; end if;
  if v_antes is distinct from v_depois then raise exception 'FALHA teste 11: linha existente foi alterada'; end if;
  insert into _wa0024_ok(msg) values ('OK teste 11: conflito com consentimento ativo -> 0 linhas, sem erro, linha original intacta'); raise notice 'OK teste 11: conflito com consentimento ativo -> 0 linhas, sem erro, linha original intacta';
end $$;

-- ======================================================================
-- TESTE 12 — PROBLEMA 2, parte 2 (ordem real do Postgres): a MESMA
-- tripla já existe, MAS o consentimento foi revogado depois. Um INSERT
-- ... ON CONFLICT DO NOTHING direto NÃO devolve "0 linhas": o trigger
-- BEFORE INSERT roda ANTES da checagem de conflito e levanta WA001.
-- É por isso que o adapter faz o SELECT pre-check antes do INSERT.
-- ======================================================================

update public.patient_consents set revoked_at = now()
where id = 'cccccccc-0000-0000-0000-00000000c001';

do $$
declare v_sqlstate text;
begin
  begin
    insert into public.whatsapp_messages
      (fisioterapeuta_id, patient_id, appointment_id, reminder_type, schedule_revision, scheduled_for,
       destination_phone_e164, consent_id)
    select fisio_id, '__wa0024_patient_a__', '__wa0024_appt_a__', 'appointment_confirmation', 0, now() + interval '1 day',
      '+5562911111111', 'cccccccc-0000-0000-0000-00000000c001'
    from _wa0024_fisios where rn = 1
    on conflict (appointment_id, reminder_type, schedule_revision) do nothing;
    raise exception 'FALHA teste 12: esperava WA001 do trigger antes do ON CONFLICT, mas o INSERT passou (ordem diferente da documentada)';
  exception
    when others then
      get stacked diagnostics v_sqlstate = returned_sqlstate;
      if v_sqlstate <> 'WA001' then
        raise exception 'FALHA teste 12: esperava WA001, veio % (%)', v_sqlstate, sqlerrm;
      end if;
      insert into _wa0024_ok(msg) values ('OK teste 12: CONFIRMADO -- BEFORE INSERT dispara antes do ON CONFLICT (linha existente + consentimento revogado -> WA001 no INSERT direto)'); raise notice 'OK teste 12: CONFIRMADO -- BEFORE INSERT dispara antes do ON CONFLICT (linha existente + consentimento revogado -> WA001 no INSERT direto)';
  end;
end $$;

-- ======================================================================
-- TESTE 13 — CASO A do adapter: o pre-check (SELECT só pela tripla)
-- encontra a linha mesmo com o consentimento revogado -> already_exists,
-- sem INSERT. Reproduz exatamente a consulta do adapter.
-- ======================================================================

do $$
declare v_found int;
begin
  select count(*) into v_found from (
    select id from public.whatsapp_messages
    where appointment_id = '__wa0024_appt_a__'
      and reminder_type = 'appointment_confirmation'
      and schedule_revision = 0
    limit 1
  ) s;
  if v_found <> 1 then raise exception 'FALHA teste 13: pre-check nao encontrou a linha existente'; end if;
  insert into _wa0024_ok(msg) values ('OK teste 13: pre-check encontra a linha (consentimento revogado e irrelevante) -> already_exists sem INSERT'); raise notice 'OK teste 13: pre-check encontra a linha (consentimento revogado e irrelevante) -> already_exists sem INSERT';
end $$;

-- ======================================================================
-- TESTE 9 (parte 2) — triggers continuam exatamente os 2 esperados
-- depois de todos os testes.
-- ======================================================================

do $$
declare v_names text;
begin
  select string_agg(tgname, ',' order by tgname) into v_names from pg_trigger
  where tgrelid = 'public.whatsapp_messages'::regclass and not tgisinternal;
  if v_names is distinct from 'whatsapp_messages_touch_updated_at,whatsapp_messages_validate_and_protect' then
    raise exception 'FALHA teste 9: triggers inesperados: %', v_names;
  end if;
  insert into _wa0024_ok(msg) values ('OK teste 9 (fim): triggers continuam ' || v_names); raise notice 'OK teste 9: %', v_names;
end $$;

-- ======================================================================
-- TESTE 10 — nenhuma linha pré-existente foi alterada: compara o hash de
-- todas as linhas reais (excluindo só os fixtures desta transação) com o
-- snapshot tirado no início, antes de qualquer fixture.
-- ======================================================================

do $$
declare v_diff int;
begin
  select count(*) into v_diff
  from _wa0024_snapshot_antes a
  full join (
    select 'whatsapp_messages' as tabela, count(*) as linhas,
      md5(coalesce(string_agg(md5(t::text), ',' order by id), '')) as hash
    from public.whatsapp_messages t where appointment_id not like '\_\_wa0024\_%'
    union all
    select 'patient_consents', count(*), md5(coalesce(string_agg(md5(t::text), ',' order by id), ''))
    from public.patient_consents t where id::text not like 'cccccccc-0000-0000-0000-00000000c00%'
    union all
    select 'patients', count(*), md5(coalesce(string_agg(md5(t::text), ',' order by id), ''))
    from public.patients t where id not like '\_\_wa0024\_%'
    union all
    select 'appointments', count(*), md5(coalesce(string_agg(md5(t::text), ',' order by id), ''))
    from public.appointments t where id not like '\_\_wa0024\_%'
  ) d using (tabela)
  where a.linhas is distinct from d.linhas or a.hash is distinct from d.hash;

  if v_diff <> 0 then raise exception 'FALHA teste 10: % tabela(s) com linhas reais alteradas', v_diff; end if;
  insert into _wa0024_ok(msg) values ('OK teste 10: hash das linhas reais de whatsapp_messages/patient_consents/patients/appointments identico ao snapshot inicial'); raise notice 'OK teste 10: hash das linhas reais de whatsapp_messages/patient_consents/patients/appointments identico ao snapshot inicial';
end $$;

select n, msg from _wa0024_ok
union all
select 99, 'rollback_ok: nada disto sera persistido'
order by 1;

rollback;
