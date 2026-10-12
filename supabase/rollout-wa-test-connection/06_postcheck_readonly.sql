-- READ-ONLY. Sem valores sensiveis.
select 'link' k, jsonb_build_object('connection_id',cr.connection_id,'vault_secret_id',cr.vault_secret_id,'secret_name',s.name,
  'conn_ok',(cr.connection_id='c7e38b29-3701-4af3-945f-716d3563d3d0'),'name_ok',(s.name='whatsapp_connection_c7e38b29-3701-4af3-945f-716d3563d3d0')) v
from public.whatsapp_connection_credentials cr left join vault.secrets s on s.id=cr.vault_secret_id
union all select 'counts', jsonb_build_object('connections',(select count(*) from public.whatsapp_connections),'credentials',(select count(*) from public.whatsapp_connection_credentials),
 'vault_secrets',(select count(*) from vault.secrets),'messages',(select count(*) from public.whatsapp_messages),
 'consents',(select count(*) from public.patient_consents),'appointments',(select count(*) from public.appointments));
