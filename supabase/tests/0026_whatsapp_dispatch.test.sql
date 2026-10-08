-- Testes das RPCs de dispatch (migration 0026) contra o Supabase Vault real.
-- Rodar com supabase/tests/run_sql_tests.sh. Tudo numa transação desfeita.
-- Token e telefones são fictícios.

begin;

create function pg_temp.check(cond boolean, label text) returns void
language plpgsql as $$
begin
  if cond is not true then
    raise exception 'FAIL: %', label;
  end if;
  raise notice 'PASS: %', label;
end $$;

-- Profissional conectado (com token no Vault, opcional).
create function pg_temp.new_fisio(p_pnid text, p_token text default null) returns uuid
language plpgsql as $$
declare v_id uuid; v_conn uuid;
begin
  insert into auth.users (email) values (gen_random_uuid() || '@teste.local') returning id into v_id;
  insert into public.whatsapp_connections (fisioterapeuta_id, waba_id, phone_number_id, status, connected_at)
  values (v_id, 'waba-' || p_pnid, p_pnid, 'connected', now()) returning id into v_conn;
  if p_token is not null then
    perform public.set_whatsapp_connection_access_token(v_conn, p_token);
  end if;
  return v_id;
end $$;

create function pg_temp.new_patient(p_fisio uuid, p_phone text, p_name text default 'Camila Souza',
                                    p_social text default null) returns text
language plpgsql as $$
declare v_id text := 'pat-' || gen_random_uuid();
begin
  insert into public.patients (id, fisioterapeuta_id, name, social_name, phone, phone_e164)
  values (v_id, p_fisio, p_name, p_social, p_phone, p_phone);
  insert into public.patient_consents (fisioterapeuta_id, patient_id, channel, purpose, contact_value, source)
  values (p_fisio, v_id, 'whatsapp', 'appointment_reminder', p_phone, 'teste');
  return v_id;
end $$;

-- Consulta daqui a p_starts_in + mensagem 'scheduled' devida há 1 minuto.
create function pg_temp.new_message(
  p_fisio uuid, p_patient text,
  p_type text default 'appointment_12h',
  p_starts_in interval default interval '12 hours',
  p_appt_status text default 'scheduled',
  p_due_in interval default interval '-1 minute'
) returns uuid
language plpgsql as $$
declare
  v_appt text := 'appt-' || gen_random_uuid();
  v_local timestamp := (now() + p_starts_in) at time zone 'America/Sao_Paulo';
  v_consent uuid; v_phone text; v_msg uuid;
begin
  insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status, patient_id)
  values (v_appt, p_fisio, v_local::date, date_trunc('minute', v_local)::time, 'x', p_appt_status, p_patient);
  select id, contact_value into v_consent, v_phone
  from public.patient_consents where patient_id = p_patient and revoked_at is null;
  insert into public.whatsapp_messages (fisioterapeuta_id, patient_id, appointment_id, reminder_type,
    schedule_revision, scheduled_for, destination_phone_e164, consent_id)
  values (p_fisio, p_patient, v_appt, p_type, 0, now() + p_due_in, v_phone, v_consent)
  returning id into v_msg;
  return v_msg;
end $$;

create function pg_temp.claim(p_types text[] default array['appointment_confirmation','appointment_12h','appointment_rescheduled'])
returns table (message_id uuid, lease_token uuid, reminder_type text)
language sql as $$ select * from public.claim_whatsapp_messages_for_dispatch(100, 300, p_types) $$;

create function pg_temp.msg(p_id uuid) returns public.whatsapp_messages
language sql as $$ select * from public.whatsapp_messages where id = p_id $$;

create function pg_temp.lease(p_id uuid) returns uuid
language sql as $$ select lease_token from public.whatsapp_messages where id = p_id $$;

-- Isola cada teste: mensagens de testes anteriores não interferem no claim.
create function pg_temp.reset_queue() returns void
language sql as $$ update public.whatsapp_messages set status = 'cancelled' where status in ('scheduled', 'processing') $$;

-- ---------------------------------------------------------------------
-- Credencial no Vault
-- ---------------------------------------------------------------------
do $$
declare
  f uuid := pg_temp.new_fisio('100001', 'tok_teste_AAAAAAAAAAAAAAAAAAAA');
  conn uuid := (select id from public.whatsapp_connections where fisioterapeuta_id = f);
  sid uuid := (select vault_secret_id from public.whatsapp_connection_credentials where connection_id = conn);
begin
  perform pg_temp.check(sid is not null, 'CRED token gravado gera referência ao Vault');
  perform pg_temp.check(
    (select secret <> 'tok_teste_AAAAAAAAAAAAAAAAAAAA' from vault.secrets where id = sid),
    'CRED token cifrado em vault.secrets (não está em texto puro)');
  perform pg_temp.check(
    (select decrypted_secret = 'tok_teste_AAAAAAAAAAAAAAAAAAAA' from vault.decrypted_secrets where id = sid),
    'CRED Vault devolve o token decifrado');
  perform public.set_whatsapp_connection_access_token(conn, 'tok_teste_BBBBBBBBBBBBBBBBBBBB');
  perform pg_temp.check(
    (select vault_secret_id = sid from public.whatsapp_connection_credentials where connection_id = conn)
    and (select decrypted_secret = 'tok_teste_BBBBBBBBBBBBBBBBBBBB' from vault.decrypted_secrets where id = sid),
    'CRED rotação atualiza o mesmo segredo');
  perform pg_temp.check(
    not exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name in ('whatsapp_connections', 'whatsapp_connection_credentials')
        and column_name ilike '%token%'),
    'CRED nenhuma coluna de token nas tabelas públicas');
  delete from public.whatsapp_connections where id = conn;
  perform pg_temp.check(not exists (select 1 from vault.secrets where id = sid),
    'CRED apagar a conexão apaga o segredo do Vault');
end $$;

do $$
declare ok boolean := false; f uuid := pg_temp.new_fisio('100002');
begin
  begin
    perform public.set_whatsapp_connection_access_token(
      (select id from public.whatsapp_connections where fisioterapeuta_id = f), 'curto');
  exception when sqlstate 'WA003' then ok := true;
  end;
  perform pg_temp.check(ok, 'CRED token inválido é recusado (WA003)');
end $$;

-- ---------------------------------------------------------------------
-- Claim
-- ---------------------------------------------------------------------
do $$
declare
  f uuid := pg_temp.new_fisio('200001', 'tok_teste_CCCCCCCCCCCCCCCCCCCC');
  p text := pg_temp.new_patient(f, '+5562922220001');
  due uuid := pg_temp.new_message(f, p);
  future uuid := pg_temp.new_message(f, p, 'appointment_12h', interval '30 hours', 'scheduled', interval '2 hours');
  imm uuid := pg_temp.new_message(f, p, 'appointment_confirmation', interval '40 hours');
  claimed uuid[];
  again uuid[];
begin
  claimed := array(select message_id from pg_temp.claim(array['appointment_12h']));
  perform pg_temp.check(claimed = array[due], 'CLAIM só a mensagem devida do tipo pedido');
  perform pg_temp.check((pg_temp.msg(due)).status = 'processing'
    and (pg_temp.msg(due)).lease_token is not null
    and (pg_temp.msg(due)).lease_expires_at > now(), 'CLAIM marca processing com lease');
  perform pg_temp.check((pg_temp.msg(future)).status = 'scheduled', 'CLAIM não pega mensagem ainda não devida');
  perform pg_temp.check((pg_temp.msg(imm)).status = 'scheduled', 'CLAIM não pega tipo sem template configurado');
  again := array(select message_id from pg_temp.claim());
  perform pg_temp.check(not (due = any (again)), 'CLAIM segunda execução não pega a já reservada');
  perform pg_temp.check(again = array[imm], 'CLAIM segunda execução pega só o que sobrou');
  perform pg_temp.reset_queue();
end $$;

do $$
declare
  f uuid := pg_temp.new_fisio('200002', 'tok_teste_DDDDDDDDDDDDDDDDDDDD');
  p text := pg_temp.new_patient(f, '+5562922220002');
  m uuid := pg_temp.new_message(f, p);
begin
  update public.whatsapp_connections set status = 'disconnected' where fisioterapeuta_id = f;
  perform pg_temp.check(not exists (select 1 from pg_temp.claim() where message_id = m),
    'CLAIM conexão inativa: mensagem não é reservada');
  update public.whatsapp_messages set status = 'cancelled' where id = m;
  update public.whatsapp_connections set status = 'connected' where fisioterapeuta_id = f;
  perform pg_temp.check(not exists (select 1 from pg_temp.claim() where message_id = m),
    'CLAIM mensagem cancelada nunca é reservada');
end $$;

-- ---------------------------------------------------------------------
-- Prepare + complete (caminho feliz) e ligação com o inbound (0025)
-- ---------------------------------------------------------------------
do $$
declare
  f uuid := pg_temp.new_fisio('300001', 'tok_teste_EEEEEEEEEEEEEEEEEEEE');
  p text := pg_temp.new_patient(f, '+5562933330001', 'Maria Camila Souza', 'Camila Rocha');
  m uuid := pg_temp.new_message(f, p);
  lease uuid;
  prep jsonb;
  r text;
  reply jsonb;
  appt text := (select appointment_id from public.whatsapp_messages where id = m);
begin
  perform pg_temp.claim();
  lease := pg_temp.lease(m);
  perform pg_temp.check(
    public.prepare_whatsapp_message_send(m, gen_random_uuid())->>'result' = 'lease_lost',
    'PREP lease errada -> lease_lost');
  prep := public.prepare_whatsapp_message_send(m, lease);
  perform pg_temp.check(prep->>'result' = 'ready', 'PREP mensagem válida -> ready');
  perform pg_temp.check(prep->>'access_token' = 'tok_teste_EEEEEEEEEEEEEEEEEEEE', 'PREP devolve o token da conexão certa');
  perform pg_temp.check(prep->>'phone_number_id' = '300001', 'PREP devolve o phone_number_id da conexão');
  perform pg_temp.check(prep->>'destination_phone_e164' = '+5562933330001', 'PREP destino = snapshot autorizado');
  perform pg_temp.check(prep->>'patient_first_name' = 'Camila', 'PREP primeiro nome (nome social tem prioridade)');
  perform pg_temp.check(prep->>'appointment_time' ~ '^\d{2}:\d{2}$' and prep->>'time_zone' = 'America/Sao_Paulo',
    'PREP devolve horário HH:MM e fuso');
  perform pg_temp.check(not (prep ? 'medical_history') and not (prep ? 'notes'), 'PREP nada clínico');
  perform pg_temp.check((pg_temp.msg(m)).send_started_at is not null and (pg_temp.msg(m)).attempt_count = 1,
    'PREP marca send_started_at e conta a tentativa');

  r := public.complete_whatsapp_message_send(m, gen_random_uuid(), 'sent', 'wamid.X');
  perform pg_temp.check(r = 'lease_lost' and (pg_temp.msg(m)).status = 'processing',
    'COMPLETE lease errada não altera nada');
  r := public.complete_whatsapp_message_send(m, lease, 'sent', 'wamid.HBgM-teste-1', 'la_pelve_confirmacao');
  perform pg_temp.check(r = 'ok', 'COMPLETE sent -> ok');
  perform pg_temp.check((pg_temp.msg(m)).status = 'sent' and (pg_temp.msg(m)).wamid = 'wamid.HBgM-teste-1'
    and (pg_temp.msg(m)).sent_at is not null and (pg_temp.msg(m)).lease_token is null
    and (pg_temp.msg(m)).template_name = 'la_pelve_confirmacao',
    'COMPLETE grava wamid, sent_at, template e limpa a lease');
  perform pg_temp.check(public.complete_whatsapp_message_send(m, lease, 'sent', 'wamid.Y') = 'lease_lost',
    'COMPLETE repetido não sobrescreve');

  -- A paciente responde citando a mensagem enviada: o inbound (0025) confirma.
  reply := public.process_whatsapp_confirmation_reply(
    'wamid.in-teste-1', '300001', array['+5562933330001'], now(), 'button', 'wamid.HBgM-teste-1');
  perform pg_temp.check(reply->>'outcome' = 'confirmed' and reply->>'appointment_id' = appt,
    'FLUXO envio real + resposta citando o wamid confirma a consulta');
  perform pg_temp.check((select status from public.appointments where id = appt) = 'confirmed',
    'FLUXO consulta scheduled -> confirmed');
end $$;

-- ---------------------------------------------------------------------
-- Retry / failed / erro sanitizado
-- ---------------------------------------------------------------------
do $$
declare
  f uuid := pg_temp.new_fisio('400001', 'tok_teste_FFFFFFFFFFFFFFFFFFFF');
  p text := pg_temp.new_patient(f, '+5562944440001');
  m uuid := pg_temp.new_message(f, p);
  m2 uuid := pg_temp.new_message(f, p, 'appointment_confirmation', interval '20 hours');
  lease uuid; lease2 uuid;
begin
  perform pg_temp.claim();
  lease := pg_temp.lease(m); lease2 := pg_temp.lease(m2);
  perform public.prepare_whatsapp_message_send(m, lease);
  perform public.prepare_whatsapp_message_send(m2, lease2);
  perform public.complete_whatsapp_message_send(m, lease, 'retry', null, null,
    '{"code":"rate_limited","http_status":429,"provider_code":130429,"access_token":"tok_teste_FFFFFFFFFFFFFFFFFFFF","message":"texto livre da Meta"}',
    300);
  perform pg_temp.check((pg_temp.msg(m)).status = 'scheduled'
    and (pg_temp.msg(m)).next_attempt_at > now() + interval '299 seconds'
    and (pg_temp.msg(m)).send_started_at is null and (pg_temp.msg(m)).lease_token is null,
    'RETRY volta para scheduled com next_attempt_at');
  perform pg_temp.check((pg_temp.msg(m)).error = '{"code":"rate_limited","http_status":429,"provider_code":130429}'::jsonb,
    'RETRY erro gravado só com as chaves permitidas (sem token, sem texto livre)');
  perform pg_temp.check(not exists (select 1 from pg_temp.claim() where message_id = m),
    'RETRY não é reservada antes de next_attempt_at');
  perform public.complete_whatsapp_message_send(m2, lease2, 'failed', null, 'tpl',
    '{"code":"auth_error","http_status":401,"provider_code":190}');
  perform pg_temp.check((pg_temp.msg(m2)).status = 'failed' and (pg_temp.msg(m2)).failed_at is not null
    and (pg_temp.msg(m2)).error->>'code' = 'auth_error', 'FAILED grava failed_at e código');
  perform pg_temp.reset_queue();
end $$;

-- ---------------------------------------------------------------------
-- Revalidação antes do envio
-- ---------------------------------------------------------------------
do $$
declare
  f uuid := pg_temp.new_fisio('500001', 'tok_teste_GGGGGGGGGGGGGGGGGGGG');
  p_rev text := pg_temp.new_patient(f, '+5562955550001');
  p_ok text := pg_temp.new_patient(f, '+5562955550002');
  p_phone text := pg_temp.new_patient(f, '+5562955550003');
  m_rev uuid := pg_temp.new_message(f, p_rev);
  m_stale uuid := pg_temp.new_message(f, p_ok, 'appointment_12h', interval '12 hours');
  m_past uuid := pg_temp.new_message(f, p_ok, 'appointment_12h', interval '-1 hour');
  m_canc uuid := pg_temp.new_message(f, p_ok, 'appointment_12h', interval '12 hours', 'cancelled');
  m_conf12 uuid := pg_temp.new_message(f, p_ok, 'appointment_12h', interval '12 hours', 'confirmed');
  m_confimm uuid := pg_temp.new_message(f, p_ok, 'appointment_confirmation', interval '12 hours', 'confirmed');
  m_phone uuid := pg_temp.new_message(f, p_phone);
  prep jsonb;
begin
  perform pg_temp.claim();
  -- Mudanças entre o claim e o envio.
  update public.patient_consents set revoked_at = now() where patient_id = p_rev;
  update public.appointments set date = date + 1
  where id = (select appointment_id from public.whatsapp_messages where id = m_stale);
  update public.patients set phone_e164 = '+5562955559999' where id = p_phone;

  prep := public.prepare_whatsapp_message_send(m_rev, pg_temp.lease(m_rev));
  perform pg_temp.check(prep->>'result' = 'cancelled' and prep->>'code' = 'consent_revoked'
    and (pg_temp.msg(m_rev)).status = 'cancelled', 'REVAL consentimento revogado -> cancelled, não envia');
  perform pg_temp.check(not (prep ? 'access_token'), 'REVAL sem envio, sem token');

  prep := public.prepare_whatsapp_message_send(m_stale, pg_temp.lease(m_stale));
  perform pg_temp.check(prep->>'code' = 'stale_schedule_revision' and (pg_temp.msg(m_stale)).status = 'cancelled',
    'REVAL consulta remarcada -> cancelled');

  prep := public.prepare_whatsapp_message_send(m_past, pg_temp.lease(m_past));
  perform pg_temp.check(prep->>'code' = 'appointment_already_occurred' and (pg_temp.msg(m_past)).status = 'cancelled',
    'REVAL consulta já começou -> cancelled');

  prep := public.prepare_whatsapp_message_send(m_canc, pg_temp.lease(m_canc));
  perform pg_temp.check(prep->>'result' = 'deferred' and prep->>'code' = 'appointment_status_not_sendable'
    and (pg_temp.msg(m_canc)).status = 'scheduled' and (pg_temp.msg(m_canc)).next_attempt_at > now(),
    'REVAL consulta cancelada -> adiada (cancelamento é reversível)');

  prep := public.prepare_whatsapp_message_send(m_conf12, pg_temp.lease(m_conf12));
  perform pg_temp.check(prep->>'code' = 'appointment_status_not_sendable',
    'REVAL pedido de confirmação de consulta já confirmada não sai');

  prep := public.prepare_whatsapp_message_send(m_confimm, pg_temp.lease(m_confimm));
  perform pg_temp.check(prep->>'result' = 'ready', 'REVAL aviso de agendamento sai para consulta confirmada');

  prep := public.prepare_whatsapp_message_send(m_phone, pg_temp.lease(m_phone));
  perform pg_temp.check(prep->>'code' = 'destination_changed' and (pg_temp.msg(m_phone)).status = 'scheduled',
    'REVAL telefone do paciente mudou -> não envia para o número antigo');
  perform pg_temp.reset_queue();
end $$;

do $$
declare
  f uuid := pg_temp.new_fisio('600001', 'tok_teste_HHHHHHHHHHHHHHHHHHHH');
  f2 uuid := pg_temp.new_fisio('600002');
  p text := pg_temp.new_patient(f, '+5562966660001');
  p2 text := pg_temp.new_patient(f2, '+5562966660002');
  m uuid := pg_temp.new_message(f, p);
  m2 uuid := pg_temp.new_message(f2, p2);
  prep jsonb;
begin
  perform pg_temp.claim();
  update public.whatsapp_connections set status = 'disconnected' where fisioterapeuta_id = f;
  prep := public.prepare_whatsapp_message_send(m, pg_temp.lease(m));
  perform pg_temp.check(prep->>'code' = 'connection_inactive' and (pg_temp.msg(m)).status = 'scheduled',
    'REVAL conexão desativada entre claim e envio -> adiada');
  prep := public.prepare_whatsapp_message_send(m2, pg_temp.lease(m2));
  perform pg_temp.check(prep->>'result' = 'deferred' and prep->>'code' = 'credential_missing'
    and (pg_temp.msg(m2)).error = '{"code":"credential_missing"}'::jsonb,
    'REVAL sem credencial -> não envia, erro seguro');
  perform pg_temp.reset_queue();
end $$;

-- ---------------------------------------------------------------------
-- Lease vencida (worker morto)
-- ---------------------------------------------------------------------
do $$
declare
  f uuid := pg_temp.new_fisio('700001', 'tok_teste_IIIIIIIIIIIIIIIIIIII');
  p text := pg_temp.new_patient(f, '+5562977770001');
  before_send uuid := pg_temp.new_message(f, p);
  after_send uuid := pg_temp.new_message(f, p, 'appointment_confirmation', interval '20 hours');
  lease_after uuid;
  reclaimed uuid[];
begin
  perform pg_temp.claim();
  lease_after := pg_temp.lease(after_send);
  perform public.prepare_whatsapp_message_send(after_send, lease_after);
  -- Simula o worker morrer: as leases vencem.
  update public.whatsapp_messages set lease_expires_at = now() - interval '1 second'
  where id in (before_send, after_send);
  reclaimed := array(select message_id from pg_temp.claim());
  perform pg_temp.check(before_send = any (reclaimed),
    'LEASE vencida antes de chamar a Meta -> volta para a fila e é reservada de novo');
  perform pg_temp.check((pg_temp.msg(after_send)).status = 'failed'
    and (pg_temp.msg(after_send)).error->>'code' = 'send_outcome_unknown'
    and not (after_send = any (reclaimed)),
    'LEASE vencida depois de chamar a Meta -> failed, NUNCA reenviada');
  perform pg_temp.check(
    public.complete_whatsapp_message_send(after_send, lease_after, 'sent', 'wamid.tardio') = 'ok'
    and (pg_temp.msg(after_send)).status = 'sent' and (pg_temp.msg(after_send)).wamid = 'wamid.tardio',
    'LEASE complete atrasado ainda grava o wamid (inbound continua funcionando)');
  perform pg_temp.check(
    public.complete_whatsapp_message_send(before_send, lease_after, 'sent', 'wamid.z') = 'lease_lost',
    'LEASE lease de outra mensagem não serve');
  perform pg_temp.reset_queue();
end $$;

-- ---------------------------------------------------------------------
-- Parâmetros, permissões e vazamento
-- ---------------------------------------------------------------------
do $$
declare ok boolean := false;
begin
  begin
    perform public.claim_whatsapp_messages_for_dispatch(1000, 300, array['appointment_12h']);
  exception when sqlstate 'WA004' then ok := true;
  end;
  perform pg_temp.check(ok, 'PARAM limite acima de 100 -> WA004');
  ok := false;
  begin
    perform public.complete_whatsapp_message_send(gen_random_uuid(), gen_random_uuid(), 'sent', '');
  exception when sqlstate 'WA004' then ok := true;
  end;
  perform pg_temp.check(ok, 'PARAM sent sem wamid -> WA004');
end $$;

do $$
declare fn text;
begin
  foreach fn in array array[
    'public.set_whatsapp_connection_access_token(uuid, text)',
    'public.claim_whatsapp_messages_for_dispatch(integer, integer, text[])',
    'public.prepare_whatsapp_message_send(uuid, uuid)',
    'public.complete_whatsapp_message_send(uuid, uuid, text, text, text, jsonb, integer)'
  ] loop
    perform pg_temp.check(
      not has_function_privilege('anon', fn, 'execute')
      and not has_function_privilege('authenticated', fn, 'execute')
      and has_function_privilege('service_role', fn, 'execute'),
      'SEC só service_role executa ' || fn);
  end loop;
  perform pg_temp.check(
    not has_table_privilege('authenticated', 'public.whatsapp_connection_credentials', 'select')
    and not has_table_privilege('anon', 'public.whatsapp_connection_credentials', 'select'),
    'SEC app não lê whatsapp_connection_credentials');
  perform pg_temp.check(
    not exists (select 1 from public.whatsapp_messages m where m::text like '%tok_teste_%')
    and not exists (select 1 from public.whatsapp_connections c where c::text like '%tok_teste_%')
    and not exists (select 1 from public.whatsapp_connection_credentials c where c::text like '%tok_teste_%'),
    'SEC nenhum token em whatsapp_messages/connections/credentials (só no Vault)');
end $$;

rollback;
