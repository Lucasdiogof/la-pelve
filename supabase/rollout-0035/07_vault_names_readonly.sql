-- READ-ONLY: nomes/ids/datas dos segredos do Vault (NUNCA o valor) e quem os referencia.
select s.id, s.name, left(s.description, 60) as descricao, s.created_at,
  exists (select 1 from public.whatsapp_connection_credentials c where c.vault_secret_id = s.id) as ligado_a_credencial,
  s.name like 'whatsapp_phone_pin_%' as parece_pin_do_guard
from vault.secrets s order by s.created_at;
