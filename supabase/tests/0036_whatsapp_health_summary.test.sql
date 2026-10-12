-- Testes da migration 0036 (resumo de saúde do WhatsApp). Rodar com
-- supabase/tests/run_sql_tests.sh. Tudo numa transação desfeita. Dados fictícios.

begin;

create function pg_temp.check(cond boolean, label text) returns void
language plpgsql as $$
begin
  if cond is not true then
    raise exception 'FAIL: %', label;
  end if;
  raise notice 'PASS: %', label;
end $$;

do $$
declare
  v_id uuid;
  s jsonb;
begin
  perform pg_temp.check(not has_function_privilege('authenticated', 'public.whatsapp_health_summary(integer)', 'execute'), 'authenticated não executa');
  perform pg_temp.check(not has_function_privilege('anon', 'public.whatsapp_health_summary(integer)', 'execute'), 'anon não executa');
  perform pg_temp.check(has_function_privilege('service_role', 'public.whatsapp_health_summary(integer)', 'execute'), 'service_role executa');

  s := public.whatsapp_health_summary(24);
  perform pg_temp.check(jsonb_typeof(s) = 'object' and s ? 'ok' and s ? 'problems' and s ? 'messages' and s ? 'connections' and s ? 'consents', 'estrutura do resumo');
  perform pg_temp.check((s->>'window_hours')::int = 24, 'janela padrão de 24 h');
  perform pg_temp.check((public.whatsapp_health_summary(100000)->>'window_hours')::int = 720, 'janela limitada a 720 h');
  perform pg_temp.check((public.whatsapp_health_summary(0)->>'window_hours')::int = 1, 'janela mínima de 1 h');

  -- Conexão em erro por token inválido aparece nos problemas.
  insert into auth.users (id, email) values (gen_random_uuid(), gen_random_uuid() || '@teste.local') returning id into v_id;
  insert into public.whatsapp_connections (fisioterapeuta_id, waba_id, phone_number_id, status, last_error)
  values (v_id, '9100000000401', '5511000000401', 'error', '{"code":"token_invalid"}');
  s := public.whatsapp_health_summary(24);
  perform pg_temp.check((s->>'ok')::boolean = false, 'ok=false com conexão inválida');
  perform pg_temp.check(s->'problems' ? 'connection_token_invalid' and s->'problems' ? 'connection_error', 'problemas de conexão listados');
  perform pg_temp.check((s->'connections'->'by_reason'->>'token_invalid')::int >= 1, 'motivo agregado');

  -- Sem dados identificáveis no resumo.
  perform pg_temp.check(position('5511000000401' in s::text) = 0 and position(v_id::text in s::text) = 0, 'sem telefone nem id no resumo');
end $$;

rollback;
