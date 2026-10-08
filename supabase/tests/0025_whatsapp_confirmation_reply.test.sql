-- Testes de public.process_whatsapp_confirmation_reply (migration 0025).
-- Rodar com supabase/tests/run_sql_tests.sh (Postgres local descartável).
-- Tudo dentro de uma transação desfeita no final. Cada teste cria os
-- próprios dados (ids aleatórios), então os testes não interferem entre si.
-- Telefones são fictícios.

begin;

-- ---------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------
create function pg_temp.check(cond boolean, label text) returns void
language plpgsql as $$
begin
  if cond is not true then
    raise exception 'FAIL: %', label;
  end if;
  raise notice 'PASS: %', label;
end $$;

-- Profissional com número do WhatsApp conectado.
create function pg_temp.new_fisio(p_phone_number_id text) returns uuid
language plpgsql as $$
declare v_id uuid;
begin
  insert into auth.users (email) values (gen_random_uuid() || '@teste.local')
  returning id into v_id;
  insert into public.whatsapp_connections (
    fisioterapeuta_id, waba_id, phone_number_id, status, connected_at
  ) values (v_id, 'waba-' || p_phone_number_id, p_phone_number_id, 'connected', now());
  return v_id;
end $$;

-- Paciente com celular e consentimento ativo para esse celular.
create function pg_temp.new_patient(p_fisio uuid, p_phone text) returns text
language plpgsql as $$
declare v_id text := 'pat-' || gen_random_uuid();
begin
  insert into public.patients (id, fisioterapeuta_id, name, phone, phone_e164)
  values (v_id, p_fisio, 'Paciente Teste', p_phone, p_phone);
  insert into public.patient_consents (
    fisioterapeuta_id, patient_id, channel, purpose, contact_value, source
  ) values (p_fisio, v_id, 'whatsapp', 'appointment_reminder', p_phone, 'teste');
  return v_id;
end $$;

-- Consulta que começa daqui a p_starts_in + solicitação appointment_12h
-- já enviada há p_sent_ago. Devolve o id da consulta; o wamid da
-- solicitação é 'wamid-req-' || id da consulta.
create function pg_temp.new_request(
  p_fisio uuid,
  p_patient text,
  p_starts_in interval default interval '20 hours',
  p_appt_status text default 'scheduled',
  p_sent_ago interval default interval '1 hour',
  p_message_status text default 'sent'
) returns text
language plpgsql as $$
declare
  v_appt text := 'appt-' || gen_random_uuid();
  v_local timestamp := (now() + p_starts_in) at time zone 'America/Sao_Paulo';
  v_consent uuid;
  v_phone text;
  v_msg uuid;
begin
  insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status, patient_id)
  values (v_appt, p_fisio, v_local::date, date_trunc('second', v_local)::time,
          'Paciente Teste', p_appt_status, p_patient);
  select id, contact_value into v_consent, v_phone
  from public.patient_consents
  where patient_id = p_patient and revoked_at is null;
  insert into public.whatsapp_messages (
    fisioterapeuta_id, patient_id, appointment_id, reminder_type,
    schedule_revision, scheduled_for, destination_phone_e164, consent_id
  ) values (
    p_fisio, p_patient, v_appt, 'appointment_12h', 0, now() - p_sent_ago,
    v_phone, v_consent
  ) returning id into v_msg;
  if p_message_status <> 'scheduled' then
    update public.whatsapp_messages
    set status = p_message_status,
        wamid = 'wamid-req-' || v_appt,
        sent_at = now() - p_sent_ago
    where id = v_msg;
  end if;
  return v_appt;
end $$;

create function pg_temp.reply(
  p_wamid text,
  p_phone_number_id text,
  p_from text,
  p_context text default null,
  p_received_at timestamptz default now()
) returns jsonb
language sql as $$
  select public.process_whatsapp_confirmation_reply(
    p_wamid, p_phone_number_id, array[p_from], p_received_at, 'text', p_context
  )
$$;

create function pg_temp.appt_status(p_appt text) returns text
language sql as $$ select status from public.appointments where id = p_appt $$;

create function pg_temp.consumed(p_appt text) returns boolean
language sql as $$
  select confirmation_consumed_at is not null
  from public.whatsapp_messages
  where appointment_id = p_appt and reminder_type = 'appointment_12h'
$$;

-- ---------------------------------------------------------------------
-- B. Correlação
-- ---------------------------------------------------------------------

-- B1: telefone certo + solicitação pendente, sem citação -> confirma.
do $$
declare
  f uuid := pg_temp.new_fisio('pn-b1');
  p text := pg_temp.new_patient(f, '+5562911110001');
  a text := pg_temp.new_request(f, p);
  r jsonb := pg_temp.reply('in-b1', 'pn-b1', '+5562911110001');
begin
  perform pg_temp.check(r->>'outcome' = 'confirmed', 'B1 resposta sem citação confirma a única solicitação');
  perform pg_temp.check(r->>'appointment_id' = a, 'B1 devolve a consulta confirmada');
  perform pg_temp.check(pg_temp.appt_status(a) = 'confirmed', 'B1 consulta scheduled -> confirmed');
  perform pg_temp.check(pg_temp.consumed(a), 'B1 solicitação marcada como respondida');
  perform pg_temp.check(
    (select outcome = 'confirmed' and whatsapp_message_id is not null
     from public.whatsapp_inbound_messages where wamid = 'in-b1'),
    'B1 mensagem recebida registrada com o resultado');
end $$;

-- B1b: resposta citando a solicitação (context.id, caso do botão).
do $$
declare
  f uuid := pg_temp.new_fisio('pn-b1b');
  p text := pg_temp.new_patient(f, '+5562911110002');
  a text := pg_temp.new_request(f, p);
  r jsonb := pg_temp.reply('in-b1b', 'pn-b1b', '+5562911110002', 'wamid-req-' || a);
begin
  perform pg_temp.check(r->>'outcome' = 'confirmed', 'B1b resposta citando a solicitação confirma');
  perform pg_temp.check(pg_temp.appt_status(a) = 'confirmed', 'B1b consulta confirmada');
end $$;

-- B2: mesmo telefone com duas consultas pendentes, sem citação -> ambígua.
do $$
declare
  f uuid := pg_temp.new_fisio('pn-b2');
  p text := pg_temp.new_patient(f, '+5562911110003');
  a1 text := pg_temp.new_request(f, p, interval '20 hours');
  a2 text := pg_temp.new_request(f, p, interval '30 hours');
  r jsonb := pg_temp.reply('in-b2', 'pn-b2', '+5562911110003');
  r2 jsonb;
begin
  perform pg_temp.check(r->>'outcome' = 'ambiguous', 'B2 duas solicitações válidas sem citação -> ambígua');
  perform pg_temp.check(pg_temp.appt_status(a1) = 'scheduled' and pg_temp.appt_status(a2) = 'scheduled',
    'B2 nenhuma das consultas muda');
  perform pg_temp.check(not pg_temp.consumed(a1) and not pg_temp.consumed(a2),
    'B2 nenhuma solicitação consumida');
  -- Com citação, confirma exatamente a citada.
  r2 := pg_temp.reply('in-b2-ctx', 'pn-b2', '+5562911110003', 'wamid-req-' || a2);
  perform pg_temp.check(r2->>'outcome' = 'confirmed' and r2->>'appointment_id' = a2,
    'B2 citando a segunda solicitação confirma só ela');
  perform pg_temp.check(pg_temp.appt_status(a1) = 'scheduled', 'B2 a outra consulta continua scheduled');
end $$;

-- B3: solicitação expirada (consulta já começou).
do $$
declare
  f uuid := pg_temp.new_fisio('pn-b3');
  p text := pg_temp.new_patient(f, '+5562911110004');
  a text := pg_temp.new_request(f, p, interval '-1 hour', 'scheduled', interval '13 hours');
  r jsonb := pg_temp.reply('in-b3', 'pn-b3', '+5562911110004', 'wamid-req-' || a);
  r2 jsonb := pg_temp.reply('in-b3-nc', 'pn-b3', '+5562911110004');
begin
  perform pg_temp.check(r->>'outcome' = 'request_expired', 'B3 consulta que já começou -> request_expired');
  perform pg_temp.check(r2->>'outcome' = 'no_pending_request', 'B3 sem citação, expirada não conta como pendente');
  perform pg_temp.check(pg_temp.appt_status(a) = 'scheduled', 'B3 consulta não muda');
end $$;

-- B3b: mensagem velha (timestamp anterior ao envio da solicitação).
do $$
declare
  f uuid := pg_temp.new_fisio('pn-b3b');
  p text := pg_temp.new_patient(f, '+5562911110005');
  a text := pg_temp.new_request(f, p, interval '20 hours', 'scheduled', interval '1 hour');
  r jsonb := pg_temp.reply('in-b3b', 'pn-b3b', '+5562911110005', 'wamid-req-' || a, now() - interval '3 hours');
begin
  perform pg_temp.check(r->>'outcome' = 'request_expired', 'B3b resposta anterior ao envio -> request_expired');
  perform pg_temp.check(pg_temp.appt_status(a) = 'scheduled', 'B3b consulta não muda');
end $$;

-- B3c: consulta remarcada depois da solicitação (revisão mudou).
do $$
declare
  f uuid := pg_temp.new_fisio('pn-b3c');
  p text := pg_temp.new_patient(f, '+5562911110006');
  a text := pg_temp.new_request(f, p);
  r jsonb;
begin
  update public.appointments set date = date + 1 where id = a;
  r := pg_temp.reply('in-b3c', 'pn-b3c', '+5562911110006', 'wamid-req-' || a);
  perform pg_temp.check(r->>'outcome' = 'request_stale', 'B3c solicitação de horário antigo -> request_stale');
  perform pg_temp.check(pg_temp.appt_status(a) = 'scheduled', 'B3c consulta remarcada não é confirmada');
end $$;

-- B3d: paciente da consulta trocado depois da solicitação.
do $$
declare
  f uuid := pg_temp.new_fisio('pn-b3d');
  p text := pg_temp.new_patient(f, '+5562911110007');
  outra text := pg_temp.new_patient(f, '+5562911110008');
  a text := pg_temp.new_request(f, p);
  r jsonb;
begin
  update public.appointments set patient_id = outra where id = a;
  r := pg_temp.reply('in-b3d', 'pn-b3d', '+5562911110007', 'wamid-req-' || a);
  perform pg_temp.check(r->>'outcome' = 'request_stale', 'B3d paciente da consulta mudou -> request_stale');
  perform pg_temp.check(pg_temp.appt_status(a) = 'scheduled', 'B3d consulta não muda');
end $$;

-- B4: sem solicitação enviada (ainda scheduled na fila) -> não confirma.
do $$
declare
  f uuid := pg_temp.new_fisio('pn-b4');
  p text := pg_temp.new_patient(f, '+5562911110009');
  a text := pg_temp.new_request(f, p, interval '20 hours', 'scheduled', interval '1 hour', 'scheduled');
  r jsonb := pg_temp.reply('in-b4', 'pn-b4', '+5562911110009');
begin
  perform pg_temp.check(r->>'outcome' = 'no_pending_request', 'B4 solicitação não enviada -> no_pending_request');
  perform pg_temp.check(pg_temp.appt_status(a) = 'scheduled', 'B4 consulta não muda');
end $$;

-- B4b: telefone sem nenhuma solicitação.
do $$
declare
  f uuid := pg_temp.new_fisio('pn-b4b');
  r jsonb := pg_temp.reply('in-b4b', 'pn-b4b', '+5562911110010');
begin
  perform pg_temp.check(r->>'outcome' = 'no_pending_request', 'B4b telefone sem solicitação -> no_pending_request');
end $$;

-- B4c: citação certa, mas remetente diferente do destino da solicitação.
do $$
declare
  f uuid := pg_temp.new_fisio('pn-b4c');
  p text := pg_temp.new_patient(f, '+5562911110011');
  a text := pg_temp.new_request(f, p);
  r jsonb := pg_temp.reply('in-b4c', 'pn-b4c', '+5562911119999', 'wamid-req-' || a);
begin
  perform pg_temp.check(r->>'outcome' = 'no_pending_request', 'B4c outro telefone citando a solicitação -> não confirma');
  perform pg_temp.check(pg_temp.appt_status(a) = 'scheduled', 'B4c consulta não muda');
end $$;

-- B4d: mesmo telefone paciente de dois profissionais; resposta chega no
-- número do profissional A -> só a consulta de A.
do $$
declare
  fa uuid := pg_temp.new_fisio('pn-b4d-a');
  fb uuid := pg_temp.new_fisio('pn-b4d-b');
  pa text := pg_temp.new_patient(fa, '+5562911110012');
  pb text := pg_temp.new_patient(fb, '+5562911110012');
  aa text := pg_temp.new_request(fa, pa);
  ab text := pg_temp.new_request(fb, pb);
  r jsonb := pg_temp.reply('in-b4d', 'pn-b4d-a', '+5562911110012');
begin
  perform pg_temp.check(r->>'outcome' = 'confirmed' and r->>'appointment_id' = aa,
    'B4d resposta no número de A confirma a consulta de A');
  perform pg_temp.check(pg_temp.appt_status(ab) = 'scheduled', 'B4d consulta do profissional B não muda');
  -- Citar a solicitação de B no número de A não funciona.
  perform pg_temp.check(
    pg_temp.reply('in-b4d-x', 'pn-b4d-a', '+5562911110012', 'wamid-req-' || ab)->>'outcome' = 'no_pending_request',
    'B4d citar mensagem de outro profissional não confirma');
  perform pg_temp.check(pg_temp.appt_status(ab) = 'scheduled', 'B4d consulta de B continua scheduled');
end $$;

-- B4e: número que não pertence a nenhum profissional.
do $$
declare
  r jsonb := pg_temp.reply('in-b4e', 'pn-desconhecido', '+5562911110013');
begin
  perform pg_temp.check(r->>'outcome' = 'no_pending_request', 'B4e phone_number_id desconhecido -> no_pending_request');
end $$;

-- B5: consentimento revogado depois do envio -> não entra no fluxo.
do $$
declare
  f uuid := pg_temp.new_fisio('pn-b5');
  p text := pg_temp.new_patient(f, '+5562911110014');
  a text := pg_temp.new_request(f, p);
  r jsonb;
  r2 jsonb;
begin
  update public.patient_consents set revoked_at = now() where patient_id = p;
  r := pg_temp.reply('in-b5', 'pn-b5', '+5562911110014', 'wamid-req-' || a);
  r2 := pg_temp.reply('in-b5-nc', 'pn-b5', '+5562911110014');
  perform pg_temp.check(r->>'outcome' = 'consent_revoked', 'B5 consentimento revogado -> consent_revoked');
  perform pg_temp.check(r2->>'outcome' = 'no_pending_request', 'B5 sem citação, sem consentimento não há pendente');
  perform pg_temp.check(pg_temp.appt_status(a) = 'scheduled', 'B5 consulta não muda');
end $$;

-- B6: celular BR identificado pelo WhatsApp sem o 9 depois do DDD.
do $$
declare
  f uuid := pg_temp.new_fisio('pn-b6');
  p text := pg_temp.new_patient(f, '+5562911110015');
  a text := pg_temp.new_request(f, p);
  r jsonb := public.process_whatsapp_confirmation_reply(
    'in-b6', 'pn-b6', array['+556211110015', '+5562911110015'], now(), 'text', null);
begin
  perform pg_temp.check(r->>'outcome' = 'confirmed', 'B6 remetente sem o 9 casa com o celular com 9');
  perform pg_temp.check(pg_temp.appt_status(a) = 'confirmed', 'B6 consulta confirmada');
end $$;

-- ---------------------------------------------------------------------
-- C. Status
-- ---------------------------------------------------------------------

-- C2: já confirmada -> idempotente, sem UPDATE na consulta.
do $$
declare
  f uuid := pg_temp.new_fisio('pn-c2');
  p text := pg_temp.new_patient(f, '+5562911110020');
  a text := pg_temp.new_request(f, p, interval '20 hours', 'confirmed');
  xmin_before text := (select xmin::text from public.appointments where id = a);
  r jsonb := pg_temp.reply('in-c2', 'pn-c2', '+5562911110020');
begin
  perform pg_temp.check(r->>'outcome' = 'already_confirmed', 'C2 consulta já confirmada -> already_confirmed');
  perform pg_temp.check(
    (select xmin::text from public.appointments where id = a) = xmin_before,
    'C2 nenhum UPDATE na consulta já confirmada');
  perform pg_temp.check(pg_temp.consumed(a), 'C2 solicitação marcada como respondida');
end $$;

-- C3..C6: estados incompatíveis nunca mudam.
do $$
declare
  st text;
  f uuid;
  p text;
  a text;
  r jsonb;
  i int := 0;
begin
  foreach st in array array['cancelled', 'fulfilled', 'noShow', 'rescheduled', 'qualquer_outro'] loop
    i := i + 1;
    f := pg_temp.new_fisio('pn-c3-' || i);
    p := pg_temp.new_patient(f, '+55629111100' || (30 + i));
    a := pg_temp.new_request(f, p, interval '20 hours', st);
    r := pg_temp.reply('in-c3-' || i, 'pn-c3-' || i, '+55629111100' || (30 + i), 'wamid-req-' || a);
    perform pg_temp.check(r->>'outcome' = 'appointment_status_incompatible',
      'C3 status ' || st || ' -> appointment_status_incompatible');
    perform pg_temp.check(pg_temp.appt_status(a) = st, 'C3 status ' || st || ' não muda');
    perform pg_temp.check(not pg_temp.consumed(a), 'C3 status ' || st || ' não consome a solicitação');
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- Idempotência
-- ---------------------------------------------------------------------
do $$
declare
  f uuid := pg_temp.new_fisio('pn-id');
  p text := pg_temp.new_patient(f, '+5562911110040');
  a text := pg_temp.new_request(f, p);
  r1 jsonb := pg_temp.reply('in-id', 'pn-id', '+5562911110040');
  consumed_at_1 timestamptz := (select confirmation_consumed_at from public.whatsapp_messages where appointment_id = a);
  reply_id_1 uuid := (select confirmation_reply_id from public.whatsapp_messages where appointment_id = a);
  r2 jsonb := pg_temp.reply('in-id', 'pn-id', '+5562911110040');
  r3 jsonb := pg_temp.reply('in-id-2', 'pn-id', '+5562911110040');
begin
  perform pg_temp.check(r1->>'outcome' = 'confirmed', 'ID primeira resposta confirma');
  perform pg_temp.check(r2->>'outcome' = 'duplicate' and r2->>'previous_outcome' = 'confirmed',
    'ID mesmo wamid de novo -> duplicate');
  perform pg_temp.check((select count(*) from public.whatsapp_inbound_messages where wamid = 'in-id') = 1,
    'ID uma única linha por wamid');
  perform pg_temp.check(r3->>'outcome' = 'already_confirmed', 'ID segundo "sim" (outro wamid) -> already_confirmed');
  perform pg_temp.check(
    (select confirmation_consumed_at = consumed_at_1 and confirmation_reply_id = reply_id_1
     from public.whatsapp_messages where appointment_id = a),
    'ID segunda resposta não sobrescreve a primeira');
end $$;

-- ---------------------------------------------------------------------
-- Parâmetros e permissões
-- ---------------------------------------------------------------------
do $$
declare ok boolean := false;
begin
  begin
    perform public.process_whatsapp_confirmation_reply('x', 'pn', array['62999'], now(), 'text', null);
  exception when sqlstate 'WA002' then ok := true;
  end;
  perform pg_temp.check(ok, 'PARAM telefone fora de E.164 -> WA002');
  ok := false;
  begin
    perform public.process_whatsapp_confirmation_reply('x', 'pn', array['+5562911110050'], now(), 'audio', null);
  exception when sqlstate 'WA002' then ok := true;
  end;
  perform pg_temp.check(ok, 'PARAM tipo de mensagem não suportado -> WA002');
  ok := false;
  begin
    perform public.process_whatsapp_confirmation_reply('', 'pn', array['+5562911110050'], now(), 'text', null);
  exception when sqlstate 'WA002' then ok := true;
  end;
  perform pg_temp.check(ok, 'PARAM wamid vazio -> WA002');
end $$;

do $$
begin
  perform pg_temp.check(
    not has_function_privilege('anon',
      'public.process_whatsapp_confirmation_reply(text, text, text[], timestamptz, text, text)', 'execute')
    and not has_function_privilege('authenticated',
      'public.process_whatsapp_confirmation_reply(text, text, text[], timestamptz, text, text)', 'execute')
    and has_function_privilege('service_role',
      'public.process_whatsapp_confirmation_reply(text, text, text[], timestamptz, text, text)', 'execute'),
    'SEC só service_role executa a função');
  perform pg_temp.check(
    not has_table_privilege('authenticated', 'public.whatsapp_inbound_messages', 'select')
    and not has_table_privilege('anon', 'public.whatsapp_inbound_messages', 'select'),
    'SEC app não lê whatsapp_inbound_messages');
  perform pg_temp.check(
    not exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = 'whatsapp_inbound_messages'
        and column_name in ('body', 'text', 'from', 'from_phone', 'phone', 'payload')),
    'SEC nenhuma coluna de corpo/telefone em whatsapp_inbound_messages');
end $$;

rollback;
