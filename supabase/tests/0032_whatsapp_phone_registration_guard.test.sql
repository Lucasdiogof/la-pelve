-- Testes do guard de registro de número (migration 0032) contra o Supabase
-- Vault real. Rodar com supabase/tests/run_sql_tests.sh. Tudo numa transação
-- desfeita. Ids fictícios.

begin;

create function pg_temp.check(cond boolean, label text) returns void
language plpgsql as $$
begin
  if cond is not true then
    raise exception 'FAIL: %', label;
  end if;
  raise notice 'PASS: %', label;
end $$;

create function pg_temp.new_fisio(p_pnid text, p_status text default 'pending') returns uuid
language plpgsql as $$
declare v_id uuid;
begin
  insert into auth.users (email) values (gen_random_uuid() || '@teste.local') returning id into v_id;
  insert into public.whatsapp_connections (fisioterapeuta_id, waba_id, phone_number_id, status, connected_at)
  values (v_id, 'waba-' || p_pnid, p_pnid, p_status,
          case when p_status = 'connected' then now() end);
  return v_id;
end $$;

-- Os testes manipulam o relógio do guard direto na linha.
create function pg_temp.rewind(p_pnid text, p_by interval) returns void
language sql as $$
  update public.whatsapp_phone_registration_guard
     set last_attempt_at = last_attempt_at - p_by,
         register_attempts = array(select t - p_by from unnest(register_attempts) t),
         blocked_until = blocked_until - p_by
   where phone_number_id = p_pnid
$$;

do $$
declare
  a uuid := pg_temp.new_fisio('5511000000001');
  b uuid := pg_temp.new_fisio('5511000000002', 'connected');
  r jsonb;
  pin1 text;
  secrets_before int;
begin
  -- Privilégios e RLS.
  perform pg_temp.check(not has_function_privilege('anon', 'public.reserve_whatsapp_phone_registration(uuid,text,boolean)', 'execute'), 'anon não reserva');
  perform pg_temp.check(not has_function_privilege('authenticated', 'public.reserve_whatsapp_phone_registration(uuid,text,boolean)', 'execute'), 'authenticated não reserva');
  perform pg_temp.check(has_function_privilege('service_role', 'public.reserve_whatsapp_phone_registration(uuid,text,boolean)', 'execute'), 'service_role reserva');
  perform pg_temp.check(not has_function_privilege('authenticated', 'public.mark_whatsapp_phone_registration_limited(uuid,text)', 'execute'), 'authenticated não marca limite');
  perform pg_temp.check(not has_table_privilege('authenticated', 'public.whatsapp_phone_registration_guard', 'select'), 'authenticated não lê o guard');
  perform pg_temp.check(not has_table_privilege('anon', 'public.whatsapp_phone_registration_guard', 'select'), 'anon não lê o guard');
  perform pg_temp.check((select relrowsecurity from pg_class where oid = 'public.whatsapp_phone_registration_guard'::regclass), 'RLS ligada no guard');

  -- Entradas inválidas e conexões que não podem registrar.
  perform pg_temp.check(public.reserve_whatsapp_phone_registration(a, 'abc', false)->>'status' = 'error', 'id inválido');
  perform pg_temp.check(public.reserve_whatsapp_phone_registration(a, '5511000000002', false)->>'status' = 'error', 'número de outra profissional');
  perform pg_temp.check(public.reserve_whatsapp_phone_registration(b, '5511000000002', false)->>'status' = 'error', 'conexão já connected não registra');
  perform pg_temp.check(public.reserve_whatsapp_phone_registration(gen_random_uuid(), '5511000000001', false)->>'status' = 'error', 'sem conexão não registra');

  -- 2FA de terceiros: sem PIN guardado, nada é criado.
  r := public.reserve_whatsapp_phone_registration(a, '5511000000001', true);
  perform pg_temp.check(r->>'status' = 'pin_unknown', 'PIN desconhecido com 2FA ligada');
  perform pg_temp.check(not exists (select 1 from public.whatsapp_phone_registration_guard where phone_number_id = '5511000000001'), 'nenhum guard criado sem PIN');

  -- Primeira reserva: cria PIN de 6 dígitos no Vault e conta a tentativa.
  select count(*) into secrets_before from vault.secrets;
  r := public.reserve_whatsapp_phone_registration(a, '5511000000001', false);
  pin1 := r->>'pin';
  perform pg_temp.check(r->>'status' = 'reserved', 'primeira reserva');
  perform pg_temp.check(pin1 ~ '^[0-9]{6}$', 'PIN de 6 dígitos');
  perform pg_temp.check((select count(*) from vault.secrets) = secrets_before + 1, 'um segredo novo no Vault');
  perform pg_temp.check((select secret from vault.secrets s join public.whatsapp_phone_registration_guard g on g.pin_secret_id = s.id where g.phone_number_id = '5511000000001') <> pin1, 'PIN cifrado em repouso');
  perform pg_temp.check((select cardinality(register_attempts) from public.whatsapp_phone_registration_guard where phone_number_id = '5511000000001') = 1, 'tentativa contada antes da chamada');
  perform pg_temp.check((select setup_state::text from public.whatsapp_connections where fisioterapeuta_id = a) not like '%' || pin1 || '%', 'PIN fora do setup_state');

  -- Intervalo mínimo.
  r := public.reserve_whatsapp_phone_registration(a, '5511000000001', false);
  perform pg_temp.check(r->>'status' = 'cooldown' and r->'pin' is null, 'cooldown sem PIN');

  -- Depois do intervalo: mesmo PIN, inclusive no modo só-PIN-existente (reconexão).
  perform pg_temp.rewind('5511000000001', interval '11 minutes');
  r := public.reserve_whatsapp_phone_registration(a, '5511000000001', true);
  perform pg_temp.check(r->>'status' = 'reserved' and r->>'pin' = pin1, 'mesmo PIN na reconexão com 2FA');
  perform pg_temp.check((select count(*) from vault.secrets) = secrets_before + 1, 'nenhum segredo extra');

  -- Limite de 8 em 72 h.
  for i in 1..6 loop
    perform pg_temp.rewind('5511000000001', interval '11 minutes');
    perform pg_temp.check(public.reserve_whatsapp_phone_registration(a, '5511000000001', false)->>'status' = 'reserved', 'reserva ' || (i + 2));
  end loop;
  perform pg_temp.rewind('5511000000001', interval '11 minutes');
  r := public.reserve_whatsapp_phone_registration(a, '5511000000001', false);
  perform pg_temp.check(r->>'status' = 'limited', '9ª tentativa em 72 h bloqueada');
  perform pg_temp.check((select blocked_until from public.whatsapp_phone_registration_guard where phone_number_id = '5511000000001') is not null, 'bloqueio gravado');

  -- Janela de 72 h expira.
  perform pg_temp.rewind('5511000000001', interval '73 hours');
  perform pg_temp.check(public.reserve_whatsapp_phone_registration(a, '5511000000001', false)->>'status' = 'reserved', 'libera depois de 72 h');

  -- 133016 da Meta: 72 h a partir de agora, mesmo após desconectar/reconectar.
  perform pg_temp.check(public.mark_whatsapp_phone_registration_limited(a, '5511000000001'), 'marca limite');
  perform pg_temp.check(not public.mark_whatsapp_phone_registration_limited(b, '5511000000001'), 'outra profissional não marca');
  update public.whatsapp_connections set status = 'disconnected' where fisioterapeuta_id = a;
  update public.whatsapp_connections set status = 'pending' where fisioterapeuta_id = a;
  perform pg_temp.rewind('5511000000001', interval '1 hour');
  perform pg_temp.check(public.reserve_whatsapp_phone_registration(a, '5511000000001', false)->>'status' = 'limited', 'reconectar não zera o bloqueio');

  -- Conexão em erro (conta reabilitada) também pode registrar.
  perform pg_temp.rewind('5511000000001', interval '72 hours');
  update public.whatsapp_connections set status = 'error' where fisioterapeuta_id = a;
  perform pg_temp.check(public.reserve_whatsapp_phone_registration(a, '5511000000001', false)->>'status' = 'reserved', 'status error reserva');
end $$;

rollback;
