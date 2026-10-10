-- Vincula o secret (por NOME) a conexao. So le vault.secrets.id. Idempotente; aborta se o secret nao existir exatamente 1x.
do $$
declare n int; sid uuid;
begin
  select count(*) into n from vault.secrets where name='whatsapp_connection_c7e38b29-3701-4af3-945f-716d3563d3d0';
  if n <> 1 then raise exception 'secret deve existir exatamente 1x, achei %', n; end if;
  if not exists (select 1 from public.whatsapp_connections where id='c7e38b29-3701-4af3-945f-716d3563d3d0') then
    raise exception 'conexao inexistente'; end if;
  select id into sid from vault.secrets where name='whatsapp_connection_c7e38b29-3701-4af3-945f-716d3563d3d0';
  insert into public.whatsapp_connection_credentials (connection_id, vault_secret_id)
  values ('c7e38b29-3701-4af3-945f-716d3563d3d0', sid)
  on conflict (connection_id) do nothing;
end $$;
select connection_id, vault_secret_id from public.whatsapp_connection_credentials;
