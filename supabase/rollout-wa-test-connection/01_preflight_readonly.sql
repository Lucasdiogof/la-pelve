-- READ-ONLY. Preflight da whatsapp_connection de teste.
-- npx.cmd supabase db query -f supabase/rollout-wa-test-connection/01_preflight_readonly.sql --linked --project-ref lchaboncmgcimafpupad
select 'columns' k, jsonb_agg(jsonb_build_object('t',table_name,'c',column_name,'type',data_type,'null',is_nullable,'def',column_default) order by table_name, ordinal_position) v
from information_schema.columns where table_schema='public' and table_name in ('whatsapp_connections','whatsapp_connection_credentials')
union all
select 'constraints', jsonb_agg(jsonb_build_object('t',conrelid::regclass::text,'n',conname,'def',pg_get_constraintdef(oid)))
from pg_constraint where conrelid in ('public.whatsapp_connections'::regclass,'public.whatsapp_connection_credentials'::regclass)
union all
select 'triggers', jsonb_agg(jsonb_build_object('t',tgrelid::regclass::text,'n',tgname,'def',pg_get_triggerdef(oid)))
from pg_trigger where not tgisinternal and tgrelid in ('public.whatsapp_connections'::regclass,'public.whatsapp_connection_credentials'::regclass)
union all
select 'counts', jsonb_build_object('connections',(select count(*) from public.whatsapp_connections),'credentials',(select count(*) from public.whatsapp_connection_credentials),
 'vault_secrets',(select count(*) from vault.secrets),'messages',(select count(*) from public.whatsapp_messages),
 'consents',(select count(*) from public.patient_consents),'appointments',(select count(*) from public.appointments))
union all
select 'profiles', jsonb_agg(to_jsonb(p) order by p.created_at) from public.profiles p;
