-- READ-ONLY. Auditoria de privilégios/RLS/cron/consentimento. Sem valores sensíveis.
select 'definer_exec_anon_auth' k, coalesce(jsonb_agg(jsonb_build_object('fn', p.proname, 'anon', has_function_privilege('anon', p.oid, 'execute'), 'auth', has_function_privilege('authenticated', p.oid, 'execute')) order by p.proname), '[]'::jsonb) v
  from pg_proc p where p.pronamespace = 'public'::regnamespace and p.prosecdef and (has_function_privilege('anon', p.oid, 'execute') or has_function_privilege('authenticated', p.oid, 'execute'))
union all
select 'definer_no_search_path', coalesce(jsonb_agg(p.proname order by p.proname), '[]'::jsonb)
  from pg_proc p where p.pronamespace = 'public'::regnamespace and p.prosecdef and not exists (select 1 from unnest(coalesce(p.proconfig, '{}')) c where c like 'search_path=%')
union all
select 'rls_whatsapp_tables', coalesce(jsonb_agg(jsonb_build_object('t', c.relname, 'rls', c.relrowsecurity, 'force', c.relforcerowsecurity) order by c.relname), '[]'::jsonb)
  from pg_class c where c.relnamespace = 'public'::regnamespace and c.relkind = 'r' and (c.relname like 'whatsapp%' or c.relname = 'patient_consents')
union all
select 'policies_whatsapp', coalesce(jsonb_agg(jsonb_build_object('t', tablename, 'name', policyname, 'cmd', cmd, 'roles', roles) order by tablename, policyname), '[]'::jsonb)
  from pg_policies where schemaname = 'public' and (tablename like 'whatsapp%' or tablename = 'patient_consents')
union all
select 'table_grants_anon_auth', coalesce(jsonb_agg(jsonb_build_object('t', table_name, 'grantee', grantee, 'priv', privilege_type) order by table_name, grantee, privilege_type), '[]'::jsonb)
  from information_schema.role_table_grants where table_schema = 'public' and table_name in ('whatsapp_connection_credentials','whatsapp_phone_registration_guard','whatsapp_connect_attempts') and grantee in ('anon','authenticated')
union all
select 'cron', coalesce(jsonb_agg(jsonb_build_object('name', jobname, 'schedule', schedule, 'active', active)), '[]'::jsonb) from cron.job
union all
select 'cron_runs_24h', coalesce(jsonb_agg(x), '[]'::jsonb) from (select status, count(*) n, min(start_time) first, max(start_time) last from cron.job_run_details where start_time > now() - interval '24 hours' group by status) x
union all
select 'http_24h', coalesce(jsonb_agg(x), '[]'::jsonb) from (select status_code, count(*) n from net._http_response where created > now() - interval '24 hours' group by status_code) x
union all
select 'queue', coalesce(jsonb_agg(x), '[]'::jsonb) from (select status, count(*) n from public.whatsapp_messages group by status) x
union all
select 'consents', jsonb_build_object('active', (select count(*) from public.patient_consents where revoked_at is null), 'revoked', (select count(*) from public.patient_consents where revoked_at is not null))
union all
select 'connections', coalesce(jsonb_agg(jsonb_build_object('status', status, 'last_error', last_error->>'code')), '[]'::jsonb) from public.whatsapp_connections
union all
select 'vault_secrets', jsonb_build_object('n', (select count(*) from vault.secrets), 'credentials', (select count(*) from public.whatsapp_connection_credentials));
