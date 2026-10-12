-- 0036: resumo de saúde da integração WhatsApp (só agregados, sem dados de paciente).
--
-- Uma chamada responde "está tudo bem?" sem investigar o Supabase à mão:
--   select public.whatsapp_health_summary();      -- janela padrão de 24 h
--   select public.whatsapp_health_summary(72);
-- Devolve jsonb com `ok`, `problems` (códigos fixos) e contadores: mensagens por
-- status; falhas e cancelamentos recentes POR CÓDIGO (consent_revoked = barrada
-- por falta de consentimento; auth_error = token recusado pela Meta); fila
-- atrasada/travada; conexões por status e motivo (token_invalid, templates_*);
-- consentimentos; respostas recebidas por resultado; e o cron (execuções por
-- status, última execução, respostas HTTP não-2xx) quando pg_cron/pg_net existem.
-- Nunca traz ids, telefones, nomes, textos nem tokens. Só service_role executa.
-- Só leitura: nenhuma linha existente muda ao aplicar.

create or replace function public.whatsapp_health_summary(p_hours integer default 24)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_hours integer := greatest(1, least(coalesce(p_hours, 24), 720));
  v_since timestamptz := pg_catalog.now() - pg_catalog.make_interval(hours => greatest(1, least(coalesce(p_hours, 24), 720)));
  v_problems text[] := '{}';
  v_messages jsonb;
  v_failed jsonb;
  v_cancelled jsonb;
  v_overdue integer;
  v_stuck integer;
  v_connections jsonb;
  v_conn_reasons jsonb;
  v_consents jsonb;
  v_inbound jsonb;
  v_cron jsonb := null;
  v_cron_jobs jsonb;
  v_cron_runs jsonb;
  v_cron_last timestamptz;
  v_cron_failed integer := 0;
  v_http jsonb := null;
  v_http_bad integer := 0;
begin
  select coalesce(pg_catalog.jsonb_object_agg(status, n), '{}'::jsonb) into v_messages
    from (select status, pg_catalog.count(*) n from public.whatsapp_messages group by status) s;

  select coalesce(pg_catalog.jsonb_object_agg(code, n), '{}'::jsonb) into v_failed
    from (select coalesce(error->>'code', 'unknown') code, pg_catalog.count(*) n
            from public.whatsapp_messages
           where status = 'failed' and coalesce(failed_at, updated_at) >= v_since group by 1) s;

  select coalesce(pg_catalog.jsonb_object_agg(code, n), '{}'::jsonb) into v_cancelled
    from (select coalesce(error->>'code', 'unknown') code, pg_catalog.count(*) n
            from public.whatsapp_messages
           where status = 'cancelled' and updated_at >= v_since group by 1) s;

  select pg_catalog.count(*) into v_overdue
    from public.whatsapp_messages
   where status = 'scheduled'
     and scheduled_for < pg_catalog.now() - interval '2 hours'
     and (next_attempt_at is null or next_attempt_at < pg_catalog.now() - interval '2 hours');

  select pg_catalog.count(*) into v_stuck
    from public.whatsapp_messages
   where status = 'processing' and lease_expires_at < pg_catalog.now() - interval '15 minutes';

  select coalesce(pg_catalog.jsonb_object_agg(status, n), '{}'::jsonb) into v_connections
    from (select status, pg_catalog.count(*) n from public.whatsapp_connections group by status) s;

  select coalesce(pg_catalog.jsonb_object_agg(code, n), '{}'::jsonb) into v_conn_reasons
    from (select last_error->>'code' code, pg_catalog.count(*) n
            from public.whatsapp_connections where last_error->>'code' is not null group by 1) s;

  select pg_catalog.jsonb_build_object(
           'active', pg_catalog.count(*) filter (where revoked_at is null),
           'revoked', pg_catalog.count(*) filter (where revoked_at is not null))
    into v_consents from public.patient_consents;

  select coalesce(pg_catalog.jsonb_object_agg(outcome, n), '{}'::jsonb) into v_inbound
    from (select coalesce(outcome, 'pending') outcome, pg_catalog.count(*) n
            from public.whatsapp_inbound_messages where received_at >= v_since group by 1) s;

  -- pg_cron / pg_net só existem no Supabase (e em bancos de teste que os criarem).
  if pg_catalog.to_regclass('cron.job') is not null and pg_catalog.to_regclass('cron.job_run_details') is not null then
    execute $q$select coalesce(jsonb_agg(jsonb_build_object('name', jobname, 'schedule', schedule, 'active', active)), '[]'::jsonb)
               from cron.job where jobname like 'la_pelve_whatsapp%'$q$ into v_cron_jobs;
    execute $q$select coalesce(jsonb_object_agg(status, n), '{}'::jsonb), max(last_start)
               from (select d.status, count(*) n, max(d.start_time) last_start
                       from cron.job_run_details d join cron.job j on j.jobid = d.jobid
                      where j.jobname like 'la_pelve_whatsapp%' and d.start_time >= $1 group by d.status) s$q$
      into v_cron_runs, v_cron_last using v_since;
    execute $q$select count(*) from cron.job_run_details d join cron.job j on j.jobid = d.jobid
                where j.jobname like 'la_pelve_whatsapp%' and d.start_time >= $1 and d.status = 'failed'$q$
      into v_cron_failed using v_since;
    v_cron := pg_catalog.jsonb_build_object('jobs', v_cron_jobs, 'runs', v_cron_runs, 'last_run', v_cron_last);
  end if;
  if pg_catalog.to_regclass('net._http_response') is not null then
    execute $q$select coalesce(jsonb_object_agg(coalesce(status_code::text, 'sem_resposta'), n), '{}'::jsonb)
               from (select status_code, count(*) n from net._http_response where created >= $1 group by 1) s$q$
      into v_http using v_since;
    execute $q$select count(*) from net._http_response
                where created >= $1 and (status_code is null or status_code < 200 or status_code >= 300)$q$
      into v_http_bad using v_since;
  end if;

  -- Problemas (códigos fixos).
  if v_failed <> '{}'::jsonb then v_problems := pg_catalog.array_append(v_problems, 'messages_failed'::text); end if;
  if v_failed ? 'auth_error' then v_problems := pg_catalog.array_append(v_problems, 'meta_token_refused'::text); end if;
  if v_overdue > 0 then v_problems := pg_catalog.array_append(v_problems, 'queue_overdue'::text); end if;
  if v_stuck > 0 then v_problems := pg_catalog.array_append(v_problems, 'queue_stuck_processing'::text); end if;
  if v_conn_reasons ? 'token_invalid' then v_problems := pg_catalog.array_append(v_problems, 'connection_token_invalid'::text); end if;
  if coalesce((v_connections->>'error')::integer, 0) > 0 then v_problems := pg_catalog.array_append(v_problems, 'connection_error'::text); end if;
  if v_conn_reasons ? 'templates_rejected' then v_problems := pg_catalog.array_append(v_problems, 'templates_rejected'::text); end if;
  if v_cron_failed > 0 then v_problems := pg_catalog.array_append(v_problems, 'cron_failed'::text); end if;
  if v_http_bad > 0 then v_problems := pg_catalog.array_append(v_problems, 'cron_http_errors'::text); end if;
  if v_cron_jobs is not null and pg_catalog.jsonb_array_length(v_cron_jobs) > 0
     and (v_cron_last is null or v_cron_last < pg_catalog.now() - interval '2 hours') then
    v_problems := pg_catalog.array_append(v_problems, 'cron_not_running'::text);
  end if;

  return pg_catalog.jsonb_build_object(
    'generated_at', pg_catalog.now(),
    'window_hours', v_hours,
    'ok', pg_catalog.cardinality(v_problems) = 0,
    'problems', pg_catalog.to_jsonb(v_problems),
    'messages', pg_catalog.jsonb_build_object(
      'by_status', v_messages,
      'failed_by_code_in_window', v_failed,
      'cancelled_by_code_in_window', v_cancelled,
      'scheduled_overdue', v_overdue,
      'processing_stuck', v_stuck),
    'connections', pg_catalog.jsonb_build_object('by_status', v_connections, 'by_reason', v_conn_reasons),
    'consents', v_consents,
    'inbound_by_outcome_in_window', v_inbound,
    'cron', v_cron,
    'cron_http_by_status_in_window', v_http);
end;
$$;

revoke all on function public.whatsapp_health_summary(integer) from public, anon, authenticated;
grant execute on function public.whatsapp_health_summary(integer) to service_role;
