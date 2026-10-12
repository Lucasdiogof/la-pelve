-- Testes da migration 0035 (invalidação atômica de conexão vinculada ao hash do
-- token recusado). Rodar com supabase/tests/run_sql_tests.sh. Tudo numa
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

create function pg_temp.sha(p_token text) returns text
language sql as $$ select encode(sha256(convert_to(p_token, 'UTF8')), 'hex') $$;

create function pg_temp.new_fisio(p_pnid text, p_status text) returns uuid
language plpgsql as $$
declare v_id uuid; v_conn uuid;
begin
  insert into auth.users (id, email) values (gen_random_uuid(), gen_random_uuid() || '@teste.local') returning id into v_id;
  insert into public.whatsapp_connections (fisioterapeuta_id, waba_id, phone_number_id, status, connected_at)
  values (v_id, '9100000000' || right(p_pnid, 3), p_pnid, p_status,
          case when p_status = 'connected' then now() end) returning id into v_conn;
  perform public.set_whatsapp_connection_access_token(v_conn, 'token-ficticio-' || p_pnid);
  return v_id;
end $$;

create function pg_temp.conn(p_fisio uuid) returns public.whatsapp_connections
language sql as $$ select * from public.whatsapp_connections where fisioterapeuta_id = p_fisio $$;

create function pg_temp.flag(p_fisio uuid, p_hash text) returns text
language plpgsql as $$
begin
  return public.flag_whatsapp_connection_token_invalid(p_fisio, p_hash);
exception when others then
  return sqlstate;
end $$;

do $$
declare
  a uuid := pg_temp.new_fisio('5511000000301', 'connected');
  b uuid := pg_temp.new_fisio('5511000000302', 'connected');
  c uuid := pg_temp.new_fisio('5511000000303', 'connected');
  d uuid := pg_temp.new_fisio('5511000000304', 'pending');
  e uuid := pg_temp.new_fisio('5511000000305', 'connected');
  f uuid := pg_temp.new_fisio('5511000000306', 'connected');
  r public.whatsapp_connections;
  conn_c uuid;
begin
  -- Privilégios.
  perform pg_temp.check(not has_function_privilege('authenticated', 'public.flag_whatsapp_connection_token_invalid(uuid,text)', 'execute'), 'authenticated não executa');
  perform pg_temp.check(not has_function_privilege('anon', 'public.flag_whatsapp_connection_token_invalid(uuid,text)', 'execute'), 'anon não executa');
  perform pg_temp.check(has_function_privilege('service_role', 'public.flag_whatsapp_connection_token_invalid(uuid,text)', 'execute'), 'service_role executa');

  -- Hash malformado é recusado e nada muda.
  perform pg_temp.check(pg_temp.flag(a, 'nao-e-hash') = 'WA011', 'hash malformado: WA011');
  perform pg_temp.check((pg_temp.conn(a)).status = 'connected', 'hash malformado não altera a conexão');

  -- Token atual = token recusado: marca.
  perform pg_temp.check(pg_temp.flag(a, pg_temp.sha('token-ficticio-5511000000301')) = 'flagged', 'token atual recusado: flagged');
  r := pg_temp.conn(a);
  perform pg_temp.check(r.status = 'error' and r.connected_at is null and r.last_error = '{"code":"token_invalid"}'::jsonb, 'conexão vira error/token_invalid sem connected_at');
  perform pg_temp.check((pg_temp.conn(b)).status = 'connected', 'outra profissional não é afetada');

  -- Idempotente: já está em error -> skipped, last_error preservado.
  perform pg_temp.check(pg_temp.flag(a, pg_temp.sha('token-ficticio-5511000000301')) = 'skipped', 'repetir é skipped');

  -- Reconexão: token trocado no mesmo segredo; resposta velha (hash do token antigo) NÃO derruba.
  perform public.set_whatsapp_connection_access_token((pg_temp.conn(b)).id, 'token-novo-5511000000302');
  perform pg_temp.check(pg_temp.flag(b, pg_temp.sha('token-ficticio-5511000000302')) = 'stale', 'hash do token antigo após reconexão: stale');
  perform pg_temp.check((pg_temp.conn(b)).status = 'connected' and (pg_temp.conn(b)).last_error is null, 'conexão renovada continua intacta');
  -- Mas o token novo recusado de fato marca.
  perform pg_temp.check(pg_temp.flag(b, pg_temp.sha('token-novo-5511000000302')) = 'flagged', 'token novo recusado marca');

  -- Desconectada (credencial apagada): skipped, status preservado.
  conn_c := (pg_temp.conn(c)).id;
  delete from public.whatsapp_connection_credentials where connection_id = conn_c;
  update public.whatsapp_connections set status = 'disconnected', connected_at = null, disconnected_at = now() where id = conn_c;
  perform pg_temp.check(pg_temp.flag(c, pg_temp.sha('token-ficticio-5511000000303')) = 'skipped', 'desconectada: skipped');
  perform pg_temp.check((pg_temp.conn(c)).status = 'disconnected' and (pg_temp.conn(c)).last_error is null, 'desconectada não é alterada');

  -- Pendente com o token recusado: marca.
  perform pg_temp.check(pg_temp.flag(d, pg_temp.sha('token-ficticio-5511000000304')) = 'flagged', 'pendente com token recusado marca');

  -- Erro por outro motivo: não é sobrescrito.
  update public.whatsapp_connections set status = 'error', connected_at = null, last_error = '{"code":"account_disabled"}' where fisioterapeuta_id = e;
  perform pg_temp.check(pg_temp.flag(e, pg_temp.sha('token-ficticio-5511000000305')) = 'skipped', 'erro por outro motivo: skipped');
  perform pg_temp.check((pg_temp.conn(e)).last_error = '{"code":"account_disabled"}'::jsonb, 'motivo original preservado');

  -- Conexão trocada de número (substituída): hash do token velho não casa com o token da nova.
  perform public.set_whatsapp_connection_access_token((pg_temp.conn(f)).id, 'token-do-outro-numero-0001');
  update public.whatsapp_connections set phone_number_id = '5511000000399' where fisioterapeuta_id = f;
  perform pg_temp.check(pg_temp.flag(f, pg_temp.sha('token-ficticio-5511000000306')) = 'stale', 'conexão substituída: stale');

  -- Sem conexão / sem credencial.
  perform pg_temp.check(pg_temp.flag(gen_random_uuid(), pg_temp.sha('x')) = 'skipped', 'profissional sem conexão: skipped');
  delete from public.whatsapp_connection_credentials where connection_id = (pg_temp.conn(f)).id;
  perform pg_temp.check(pg_temp.flag(f, pg_temp.sha('token-do-outro-numero-0001')) = 'skipped', 'sem credencial: skipped');
end $$;

rollback;
