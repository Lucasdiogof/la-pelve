-- READ-ONLY. Auditoria pos-rollout PR #11. Sem valores sensiveis.
select 'cron' k, coalesce(jsonb_agg(jsonb_build_object('jobname',jobname,'schedule',schedule,'active',active)),'[]'::jsonb) v from cron.job
union all select 'cron_runs', coalesce(jsonb_agg(x),'[]'::jsonb) from (select status, count(*) n, max(start_time) last_start from cron.job_run_details where start_time > now() - interval '3 hours' group by status) x
union all select 'http_responses_3h', coalesce(jsonb_agg(x),'[]'::jsonb) from (select status_code, count(*) n, max(created) last from net._http_response where created > now() - interval '3 hours' group by status_code) x
union all select 'messages_by_status', coalesce(jsonb_agg(x),'[]'::jsonb) from (select status, count(*) n from public.whatsapp_messages group by status) x
union all select 'consents', jsonb_build_object('active',(select count(*) from public.patient_consents where revoked_at is null),'revoked',(select count(*) from public.patient_consents where revoked_at is not null))
union all select 'data', jsonb_build_object('appointments',(select count(*) from public.appointments),'patients',(select count(*) from public.patients))
union all select 'connections', coalesce(jsonb_agg(jsonb_build_object('status',status,'has_templates_hist',(setup_state ? 'templates'),'templates_verified',(setup_state ? 'templates_verified_at'))),'[]'::jsonb) from public.whatsapp_connections
union all select 'fn_0034', coalesce(jsonb_agg(jsonb_build_object('fn',p.proname,'has_templates_verified_at',position('templates_verified_at' in pg_get_functiondef(p.oid))>0,'anon_exec',has_function_privilege('anon',p.oid,'execute'),'auth_exec',has_function_privilege('authenticated',p.oid,'execute'))),'[]'::jsonb)
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('upsert_whatsapp_connection_from_signup','apply_whatsapp_template_status','list_whatsapp_template_reevaluation_candidates');
