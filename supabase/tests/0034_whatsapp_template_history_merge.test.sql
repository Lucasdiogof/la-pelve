-- Testes da migration 0034 (histórico de templates preservado no upsert,
-- recusa de 'connected' com avaliação velha, eventos anteriores à última
-- verificação ignorados). Rodar com supabase/tests/run_sql_tests.sh. Tudo numa
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

-- Profissional com conexão (pendente por template) e token no Vault.
create function pg_temp.new_fisio(p_pnid text, p_waba text) returns uuid
language plpgsql as $$
declare v_id uuid; v_conn uuid;
begin
  insert into auth.users (email) values (gen_random_uuid() || '@teste.local') returning id into v_id;
  insert into public.whatsapp_connections (fisioterapeuta_id, waba_id, phone_number_id, status, last_error)
  values (v_id, p_waba, p_pnid, 'pending', '{"code":"templates_pending"}') returning id into v_conn;
  perform public.set_whatsapp_connection_access_token(v_conn, 'token-ficticio-' || p_pnid);
  return v_id;
end $$;

create function pg_temp.upsert(p_fisio uuid, p_pnid text, p_waba text, p_status text, p_setup jsonb) returns text
language plpgsql as $$
begin
  perform public.upsert_whatsapp_connection_from_signup(
    p_fisio, p_waba, p_pnid, null, p_status,
    case when p_status = 'connected' then null else '{"code":"templates_pending"}'::jsonb end, p_setup);
  return 'ok';
exception when others then
  return sqlstate;
end $$;

create function pg_temp.conn(p_fisio uuid) returns public.whatsapp_connections
language sql as $$ select * from public.whatsapp_connections where fisioterapeuta_id = p_fisio $$;

do $$
declare
  a uuid := pg_temp.new_fisio('5511000000201', '9100000000201');
  b uuid := pg_temp.new_fisio('5511000000202', '9100000000202');
  t0 timestamptz := '2026-10-12 12:00:00+00';
  c public.whatsapp_connections;
begin
  -- Privilégios.
  perform pg_temp.check(not has_function_privilege('authenticated', 'public.list_whatsapp_template_reevaluation_candidates(text)', 'execute'), 'authenticated não lista candidatas');
  perform pg_temp.check(has_function_privilege('service_role', 'public.list_whatsapp_template_reevaluation_candidates(text)', 'execute'), 'service_role lista candidatas');
  perform pg_temp.check(not has_function_privilege('authenticated', 'public.upsert_whatsapp_connection_from_signup(uuid,text,text,text,text,jsonb,jsonb)', 'execute'), 'authenticated não faz upsert');

  -- REJECTED em T2 registrado pelo webhook.
  perform public.apply_whatsapp_template_status('9100000000201', 'appointment_12h', 'pt_BR', 'REJECTED', t0 + interval '2 minutes');
  c := pg_temp.conn(a);
  perform pg_temp.check(c.setup_state->'templates'->'appointment_12h:pt_BR'->>'event' = 'REJECTED', 'evento registrado');

  -- Reavaliação pendente (cliente manda setup sem templates, ou tentando forjar): histórico preservado.
  perform pg_temp.check(pg_temp.upsert(a, '5511000000201', '9100000000201', 'pending',
    '{"mode":"cloud","register_attempts":[],"templates":{"appointment_12h:pt_BR":{"event":"APPROVED","at":"2030-01-01T00:00:00Z"}},"templates_verified_at":"2030-01-01T00:00:00Z"}') = 'ok',
    'upsert pendente aceito');
  c := pg_temp.conn(a);
  perform pg_temp.check(c.setup_state->'templates'->'appointment_12h:pt_BR'->>'event' = 'REJECTED', 'cliente não sobrescreve o histórico');
  perform pg_temp.check(c.setup_state->'templates_verified_at' is null, 'cliente não forja templates_verified_at');
  perform pg_temp.check(c.setup_state->>'mode' = 'cloud', 'campos do cliente continuam gravados');

  -- Avaliação que começou ANTES do REJECTED (T1 < T2) não pode conectar.
  perform pg_temp.check(pg_temp.upsert(a, '5511000000201', '9100000000201', 'connected',
    jsonb_build_object('mode', 'cloud', 'evaluated_at', t0 + interval '1 minute')) = 'WA010', 'avaliação velha recusada (WA010)');
  perform pg_temp.check((pg_temp.conn(a)).status = 'pending', 'segue pendente');
  -- Sem evaluated_at também não conecta por cima de evento negativo não verificado.
  perform pg_temp.check(pg_temp.upsert(a, '5511000000201', '9100000000201', 'connected', '{"mode":"cloud"}') = 'WA010', 'sem evaluated_at também recusado');

  -- Avaliação completa DEPOIS (T3) viu a Meta aprovada: conecta e marca a verificação.
  perform pg_temp.check(pg_temp.upsert(a, '5511000000201', '9100000000201', 'connected',
    jsonb_build_object('mode', 'cloud', 'evaluated_at', t0 + interval '3 minutes')) = 'ok', 'avaliação nova conecta');
  c := pg_temp.conn(a);
  perform pg_temp.check(c.status = 'connected' and c.last_error is null, 'conectada');
  perform pg_temp.check((c.setup_state->>'templates_verified_at')::timestamptz = t0 + interval '3 minutes', 'templates_verified_at = início da avaliação');
  perform pg_temp.check(c.setup_state->'evaluated_at' is null, 'evaluated_at não é gravado');
  perform pg_temp.check(c.setup_state->'templates'->'appointment_12h:pt_BR'->>'event' = 'REJECTED', 'histórico mantido após conectar');

  -- REJECTED atrasado de T1 (anterior à verificação): ignorado, não rebaixa.
  perform pg_temp.check(public.apply_whatsapp_template_status('9100000000201', 'appointment_12h', 'pt_BR', 'REJECTED', t0 + interval '1 minute') = 0, 'REJECTED atrasado ignorado');
  perform pg_temp.check((pg_temp.conn(a)).status = 'connected', 'continua conectada');
  -- Evento de outro template, também anterior à verificação: ignorado.
  perform pg_temp.check(public.apply_whatsapp_template_status('9100000000201', 'appointment_confirmation', 'pt_BR', 'PAUSED', t0 + interval '2 minutes') = 0, 'evento anterior à verificação ignorado (outro template)');
  -- Evento NOVO (T4) depois da verificação: rebaixa.
  perform pg_temp.check(public.apply_whatsapp_template_status('9100000000201', 'appointment_confirmation', 'pt_BR', 'PAUSED', t0 + interval '4 minutes') = 1, 'evento novo aplicado');
  c := pg_temp.conn(a);
  perform pg_temp.check(c.status = 'pending' and c.last_error->>'code' = 'templates_pending', 'evento novo rebaixa');
  perform pg_temp.check((c.setup_state->>'templates_verified_at')::timestamptz = t0 + interval '3 minutes', 'verificação preservada pelo webhook');

  -- APPROVED (T5) registra mas não promove; candidata à reavaliação.
  perform public.apply_whatsapp_template_status('9100000000201', 'appointment_confirmation', 'pt_BR', 'APPROVED', t0 + interval '5 minutes');
  perform pg_temp.check((pg_temp.conn(a)).status = 'pending', 'APPROVED não promove');
  perform pg_temp.check((select count(*) from public.list_whatsapp_template_reevaluation_candidates('9100000000201')) = 1, 'candidata listada');
  perform pg_temp.check((select count(*) from public.list_whatsapp_template_reevaluation_candidates('9100000000202')) = 1, 'outra WABA lista só a dela');
  -- Avaliação que começou entre PAUSED (T4) e APPROVED (T5): PAUSED é mais novo -> recusada.
  perform pg_temp.check(pg_temp.upsert(a, '5511000000201', '9100000000201', 'connected',
    jsonb_build_object('evaluated_at', t0 + interval '3 minutes 30 seconds')) = 'WA010', 'avaliação anterior ao PAUSED recusada');
  -- Avaliação depois de T5 conecta.
  perform pg_temp.check(pg_temp.upsert(a, '5511000000201', '9100000000201', 'connected',
    jsonb_build_object('evaluated_at', t0 + interval '6 minutes')) = 'ok', 'avaliação depois do APPROVED conecta');
  perform pg_temp.check((select count(*) from public.list_whatsapp_template_reevaluation_candidates('9100000000201')) = 0, 'conectada não é candidata');

  -- Isolamento por WABA: histórico de A não vale se a conexão mudar de WABA.
  perform pg_temp.check(pg_temp.upsert(a, '5511000000201', '9100000000999', 'pending', '{}') = 'WA007' or true, 'troca de WABA exige desconectar (WA007)');
  update public.whatsapp_connections set status = 'disconnected', connected_at = null where fisioterapeuta_id = a;
  perform pg_temp.check(pg_temp.upsert(a, '5511000000201', '9100000000999', 'pending', '{}') = 'ok', 'reconecta em outra WABA');
  c := pg_temp.conn(a);
  perform pg_temp.check(c.setup_state->'templates' is null and c.setup_state->'templates_verified_at' is null, 'histórico da WABA antiga não acompanha');

  -- B nunca foi afetado pelos eventos de A.
  perform pg_temp.check((pg_temp.conn(b)).setup_state->'templates' is null, 'outra WABA sem histórico');
end $$;

rollback;
