-- READ-ONLY. Nunca seleciona secret/decrypted_secret.
select id, name, created_at, (select count(*) from vault.secrets) as total_secrets,
       (select count(*) from vault.secrets where name='whatsapp_connection_c7e38b29-3701-4af3-945f-716d3563d3d0') as matches
from vault.secrets where name='whatsapp_connection_c7e38b29-3701-4af3-945f-716d3563d3d0';
