-- READ-ONLY.
select 'connection' k, to_jsonb(c) v from public.whatsapp_connections c
union all select 'conn_for_user', jsonb_build_object('count',(select count(*) from public.whatsapp_connections where fisioterapeuta_id='4f8bfc70-9e28-4a0a-b5df-ec1ae1560d56'),'total',(select count(*) from public.whatsapp_connections))
union all select 'counts', jsonb_build_object('credentials',(select count(*) from public.whatsapp_connection_credentials),'vault_secrets',(select count(*) from vault.secrets),
  'messages',(select count(*) from public.whatsapp_messages),'consents',(select count(*) from public.patient_consents),'appointments',(select count(*) from public.appointments));
