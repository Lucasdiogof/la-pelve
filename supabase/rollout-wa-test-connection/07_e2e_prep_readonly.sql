-- READ-ONLY. Preparacao do E2E appointment_12h.
select 'patients' k, coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name,'phone',phone,'phone_e164',phone_e164,'deleted_at',deleted_at,'created_at',created_at) order by created_at),'[]'::jsonb) v
  from public.patients where fisioterapeuta_id='4f8bfc70-9e28-4a0a-b5df-ec1ae1560d56'
union all
select 'patient_cols', jsonb_agg(jsonb_build_object('c',column_name,'t',data_type,'n',is_nullable,'d',column_default) order by ordinal_position)
  from information_schema.columns where table_schema='public' and table_name='patients'
union all
select 'consent_cols', jsonb_agg(jsonb_build_object('c',column_name,'t',data_type,'n',is_nullable,'d',column_default) order by ordinal_position)
  from information_schema.columns where table_schema='public' and table_name='patient_consents'
union all
select 'consent_constraints', jsonb_agg(jsonb_build_object('n',conname,'def',pg_get_constraintdef(oid)))
  from pg_constraint where conrelid='public.patient_consents'::regclass
union all
select 'consent_triggers', coalesce(jsonb_agg(jsonb_build_object('n',tgname,'def',pg_get_triggerdef(oid))),'[]'::jsonb)
  from pg_trigger where not tgisinternal and tgrelid='public.patient_consents'::regclass
union all
select 'appt_cols', jsonb_agg(jsonb_build_object('c',column_name,'t',data_type,'n',is_nullable,'d',column_default) order by ordinal_position)
  from information_schema.columns where table_schema='public' and table_name='appointments'
union all
select 'appt_constraints', jsonb_agg(jsonb_build_object('n',conname,'def',pg_get_constraintdef(oid)))
  from pg_constraint where conrelid='public.appointments'::regclass
union all
select 'profile', jsonb_build_object('timezone',timezone) from public.profiles where id='4f8bfc70-9e28-4a0a-b5df-ec1ae1560d56'
union all
select 'appts_future', coalesce(jsonb_agg(jsonb_build_object('id',id,'date',date,'time',time,'status',status,'patient_id',patient_id) order by date,time),'[]'::jsonb)
  from public.appointments where fisioterapeuta_id='4f8bfc70-9e28-4a0a-b5df-ec1ae1560d56' and date >= current_date - 1
union all
select 'now', jsonb_build_object('utc',now(),'sp',now() at time zone 'America/Sao_Paulo');
