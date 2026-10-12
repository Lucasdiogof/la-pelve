-- Insere a conexao de TESTE (idempotente). Sem token, sem credentials, sem Vault.
-- npx.cmd supabase db query -f supabase/rollout-wa-test-connection/02_insert_test_connection.sql --linked --project-ref lchaboncmgcimafpupad
with ins as (
  insert into public.whatsapp_connections
    (fisioterapeuta_id, waba_id, phone_number_id, display_phone_number, status, connected_at)
  select '4f8bfc70-9e28-4a0a-b5df-ec1ae1560d56'::uuid, '1118307474103479', '1440584945795727',
         '+1 (555) 637-7568', 'connected', now()
  where exists (select 1 from auth.users where id = '4f8bfc70-9e28-4a0a-b5df-ec1ae1560d56')
    and not exists (select 1 from public.whatsapp_connections
                    where fisioterapeuta_id = '4f8bfc70-9e28-4a0a-b5df-ec1ae1560d56'
                       or phone_number_id = '1440584945795727')
  returning id
)
select (select count(*) from ins) as inserted,
       (select id from ins) as new_connection_id,
       (select id from public.whatsapp_connections where fisioterapeuta_id='4f8bfc70-9e28-4a0a-b5df-ec1ae1560d56') as existing_connection_id;
