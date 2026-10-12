-- Testes de apply_whatsapp_message_status e apply_whatsapp_template_status
-- (migration 0033). Rodar com supabase/tests/run_sql_tests.sh. Tudo numa
-- transação desfeita. Dados fictícios.

begin;

create function pg_temp.check(cond boolean, label text) returns void
language plpgsql as $$
begin
  if cond is not true then
    raise exception 'FAIL: %', label;
  end if;
  raise notice 'PASS: %', label;
end $$;

-- Profissional + conexão + paciente com consentimento + consulta futura.
create function pg_temp.new_fisio(p_pnid text, p_waba text, p_status text default 'connected') returns uuid
language plpgsql as $$
declare v_id uuid;
begin
  insert into auth.users (email) values (gen_random_uuid() || '@teste.local') returning id into v_id;
  insert into public.whatsapp_connections (fisioterapeuta_id, waba_id, phone_number_id, status, connected_at)
  values (v_id, p_waba, p_pnid, p_status, case when p_status = 'connected' then now() end);
  return v_id;
end $$;

-- Mensagem appointment_12h já enviada (status sent, wamid gravado).
create function pg_temp.sent_message(p_fisio uuid, p_wamid text) returns uuid
language plpgsql as $$
declare
  v_pat text := 'pat-' || gen_random_uuid();
  v_appt text := 'appt-' || gen_random_uuid();
  v_local timestamp := (now() + interval '20 hours') at time zone 'America/Sao_Paulo';
  v_consent uuid;
  v_msg uuid;
begin
  insert into public.patients (id, fisioterapeuta_id, name, phone, phone_e164)
  values (v_pat, p_fisio, 'Paciente Teste', '(62) 91111-0000', '+5562911110000');
  insert into public.patient_consents (fisioterapeuta_id, patient_id, channel, purpose, contact_value, source)
  values (p_fisio, v_pat, 'whatsapp', 'appointment_reminder', '+5562911110000', 'teste')
  returning id into v_consent;
  insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status, patient_id)
  values (v_appt, p_fisio, v_local::date, date_trunc('minute', v_local)::time, 'x', 'scheduled', v_pat);
  insert into public.whatsapp_messages (fisioterapeuta_id, patient_id, appointment_id, reminder_type,
    schedule_revision, scheduled_for, destination_phone_e164, consent_id)
  values (p_fisio, v_pat, v_appt, 'appointment_12h', 0, now() - interval '1 hour', '+5562911110000', v_consent)
  returning id into v_msg;
  update public.whatsapp_messages set status = 'sent', wamid = p_wamid, sent_at = now() - interval '1 hour'
   where id = v_msg;
  return v_msg;
end $$;

do $$
declare
  a uuid := pg_temp.new_fisio('5511000000101', '9100000000001');
  b uuid := pg_temp.new_fisio('5511000000102', '9100000000002');
  m uuid := pg_temp.sent_message(a, 'wamid.T1');
  m2 uuid := pg_temp.sent_message(a, 'wamid.T2');
  m3 uuid := pg_temp.sent_message(a, 'wamid.T3');
  t0 timestamptz := now();
  r text;
  v public.whatsapp_messages%rowtype;
begin
  -- Privilégios.
  perform pg_temp.check(not has_function_privilege('anon', 'public.apply_whatsapp_message_status(text,text,text,timestamptz,integer)', 'execute'), 'anon não aplica status');
  perform pg_temp.check(not has_function_privilege('authenticated', 'public.apply_whatsapp_message_status(text,text,text,timestamptz,integer)', 'execute'), 'authenticated não aplica status');
  perform pg_temp.check(has_function_privilege('service_role', 'public.apply_whatsapp_message_status(text,text,text,timestamptz,integer)', 'execute'), 'service_role aplica status');
  perform pg_temp.check(not has_function_privilege('authenticated', 'public.apply_whatsapp_template_status(text,text,text,text,timestamptz)', 'execute'), 'authenticated não aplica template');
  perform pg_temp.check(has_function_privilege('service_role', 'public.apply_whatsapp_template_status(text,text,text,text,timestamptz)', 'execute'), 'service_role aplica template');

  -- Entradas inválidas e identidade do número.
  perform pg_temp.check(public.apply_whatsapp_message_status('pn', 'wamid.T1', 'read', t0) = 'invalid', 'phone_number_id inválido');
  perform pg_temp.check(public.apply_whatsapp_message_status('5511000000101', 'wamid.T1', 'played', t0) = 'invalid', 'status desconhecido');
  perform pg_temp.check(public.apply_whatsapp_message_status('5511000000101', 'wamid.nao.existe', 'read', t0) = 'not_found', 'wamid desconhecido');
  perform pg_temp.check(public.apply_whatsapp_message_status('5511000000102', 'wamid.T1', 'read', t0) = 'not_found', 'número de outra conexão não altera a mensagem');
  perform pg_temp.check((select status from public.whatsapp_messages where id = m) = 'sent', 'mensagem intacta após número errado');

  -- Progressão e idempotência.
  perform pg_temp.check(public.apply_whatsapp_message_status('5511000000101', 'wamid.T1', 'sent', t0) = 'unchanged', 'sent repetido é idempotente');
  perform pg_temp.check(public.apply_whatsapp_message_status('5511000000101', 'wamid.T1', 'delivered', t0 + interval '1 second') = 'updated', 'delivered');
  perform pg_temp.check(public.apply_whatsapp_message_status('5511000000101', 'wamid.T1', 'delivered', t0 + interval '2 second') = 'unchanged', 'delivered duplicado');
  perform pg_temp.check(public.apply_whatsapp_message_status('5511000000101', 'wamid.T1', 'read', t0 + interval '3 second') = 'updated', 'read');
  perform pg_temp.check(public.apply_whatsapp_message_status('5511000000101', 'wamid.T1', 'sent', t0 + interval '4 second') = 'unchanged', 'sent atrasado não rebaixa read');
  perform pg_temp.check(public.apply_whatsapp_message_status('5511000000101', 'wamid.T1', 'delivered', t0 + interval '5 second') = 'unchanged', 'delivered atrasado não rebaixa read');
  perform pg_temp.check(public.apply_whatsapp_message_status('5511000000101', 'wamid.T1', 'failed', t0 + interval '6 second', 131026) = 'unchanged', 'failed não rebaixa read');
  select * into v from public.whatsapp_messages where id = m;
  perform pg_temp.check(v.status = 'read', 'status final read');
  perform pg_temp.check(v.delivered_at = t0 + interval '1 second', 'delivered_at do primeiro delivered');
  perform pg_temp.check(v.read_at = t0 + interval '3 second', 'read_at do primeiro read');
  perform pg_temp.check(v.failed_at is null and v.error is null, 'sem erro');

  -- read direto (delivered pulado pela Meta) preenche delivered_at.
  perform pg_temp.check(public.apply_whatsapp_message_status('5511000000101', 'wamid.T2', 'read', t0) = 'updated', 'read sem delivered');
  perform pg_temp.check((select delivered_at = t0 and read_at = t0 from public.whatsapp_messages where id = m2), 'read implica entregue');

  -- failed de entrega: só código numérico; não volta para a fila.
  perform pg_temp.check(public.apply_whatsapp_message_status('5511000000101', 'wamid.T3', 'failed', t0, 131026) = 'updated', 'failed a partir de sent');
  select * into v from public.whatsapp_messages where id = m3;
  perform pg_temp.check(v.status = 'failed' and v.failed_at = t0, 'failed gravado');
  perform pg_temp.check(v.error = '{"code": "delivery_failed", "provider_code": 131026}'::jsonb, 'erro só com códigos');
  perform pg_temp.check(v.next_attempt_at is null and v.lease_token is null, 'nada agendado para reenvio');
  perform pg_temp.check(not exists (
    select 1 from public.claim_whatsapp_messages_for_dispatch(10, 60, array['appointment_12h']) c where c.id = m3
  ), 'claim nunca reserva mensagem failed');
  perform pg_temp.check(public.apply_whatsapp_message_status('5511000000101', 'wamid.T3', 'failed', t0, 131026) = 'unchanged', 'failed duplicado');
  -- Entrega comprovada depois (fora de ordem) vence o failed de entrega.
  perform pg_temp.check(public.apply_whatsapp_message_status('5511000000101', 'wamid.T3', 'delivered', t0 + interval '1 second') = 'updated', 'delivered vence failed de entrega');
  select * into v from public.whatsapp_messages where id = m3;
  perform pg_temp.check(v.status = 'delivered' and v.error is null and v.failed_at is null, 'failed limpo');

  -- failed por resultado desconhecido do envio não é tocado por status.
  update public.whatsapp_messages set status = 'failed', error = '{"code":"send_outcome_unknown"}' where id = m2;
  perform pg_temp.check(public.apply_whatsapp_message_status('5511000000101', 'wamid.T2', 'read', t0) = 'unchanged', 'send_outcome_unknown preservado');

  -- Templates: evento negativo tira de connected; aprovação nunca promove.
  perform pg_temp.check(public.apply_whatsapp_template_status('9100000000001', 'appointment_12h', 'pt_BR', 'FLAGGED', t0) = 1, 'FLAGGED registra');
  perform pg_temp.check((select status from public.whatsapp_connections where fisioterapeuta_id = a) = 'connected', 'FLAGGED não derruba');
  perform pg_temp.check(public.apply_whatsapp_template_status('9100000000001', 'appointment_12h', 'pt_BR', 'PAUSED', t0 + interval '1 minute') = 1, 'PAUSED aplica');
  perform pg_temp.check((select status = 'pending' and connected_at is null and last_error->>'code' = 'templates_pending'
                           from public.whatsapp_connections where fisioterapeuta_id = a), 'PAUSED -> pending/templates_pending');
  perform pg_temp.check((select setup_state->'templates'->'appointment_12h:pt_BR'->>'event' from public.whatsapp_connections where fisioterapeuta_id = a) = 'PAUSED', 'evento registrado no setup_state');
  perform pg_temp.check(not exists (
    select 1 from public.claim_whatsapp_messages_for_dispatch(10, 60, array['appointment_12h']) c
      join public.whatsapp_messages w on w.id = c.id where w.fisioterapeuta_id = a
  ), 'conexão pendente não despacha');
  perform pg_temp.check(public.apply_whatsapp_template_status('9100000000001', 'appointment_12h', 'pt_BR', 'APPROVED', t0 + interval '2 minute') = 1, 'APPROVED registra');
  perform pg_temp.check((select status from public.whatsapp_connections where fisioterapeuta_id = a) = 'pending', 'APPROVED NÃO promove');
  perform pg_temp.check(public.apply_whatsapp_template_status('9100000000001', 'appointment_12h', 'pt_BR', 'REJECTED', t0) = 0, 'evento mais antigo que o registrado é ignorado');
  perform pg_temp.check((select setup_state->'templates'->'appointment_12h:pt_BR'->>'event' from public.whatsapp_connections where fisioterapeuta_id = a) = 'APPROVED', 'registro não regride');
  perform pg_temp.check(public.apply_whatsapp_template_status('9100000000002', 'appointment_confirmation', 'pt_BR', 'REJECTED', t0) = 1, 'REJECTED em outra WABA');
  perform pg_temp.check((select status = 'pending' and last_error->>'code' = 'templates_rejected'
                           from public.whatsapp_connections where fisioterapeuta_id = b), 'REJECTED -> templates_rejected');
  perform pg_temp.check((select status from public.whatsapp_connections where fisioterapeuta_id = a) = 'pending', 'outra WABA não afeta');
  perform pg_temp.check(public.apply_whatsapp_template_status('91', 'appointment_12h', 'pt_BR', 'REJECTED', t0) = 0, 'WABA inválida');
  perform pg_temp.check(public.apply_whatsapp_template_status('9100000000001', 'Nome Ruim', 'pt_BR', 'REJECTED', t0) = 0, 'nome inválido');
  update public.whatsapp_connections set status = 'disconnected', connected_at = null where fisioterapeuta_id = a;
  perform pg_temp.check(public.apply_whatsapp_template_status('9100000000001', 'appointment_12h', 'pt_BR', 'DISABLED', t0 + interval '3 minute') = 0, 'conexão desconectada não muda');
end $$;

rollback;
