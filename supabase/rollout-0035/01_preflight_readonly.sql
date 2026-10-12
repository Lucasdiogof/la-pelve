-- PRE-FLIGHT da migration 0035 (flag_whatsapp_connection_token_invalid). SOMENTE LEITURA.
--   npx.cmd supabase db query -f supabase/rollout-0035/01_preflight_readonly.sql --linked --project-ref lchaboncmgcimafpupad
-- Esperado: todas PASS.
with checks(item, esperado, atual) as (
  values
    ('01 funcao ainda nao existe', 'false',
      (to_regprocedure('public.flag_whatsapp_connection_token_invalid(uuid,text)') is not null)::text),
    ('02 migration 0034 aplicada (upsert com templates_verified_at)', 'true',
      exists (select 1 from pg_proc p where p.pronamespace = 'public'::regnamespace
              and p.proname = 'upsert_whatsapp_connection_from_signup'
              and position('templates_verified_at' in pg_get_functiondef(p.oid)) > 0)::text),
    ('03 vault.decrypted_secrets existe', 'true', (to_regclass('vault.decrypted_secrets') is not null)::text),
    ('04 set_whatsapp_connection_access_token existe (token atualizado no mesmo segredo)', 'true',
      (to_regprocedure('public.set_whatsapp_connection_access_token(uuid,text)') is not null)::text),
    ('05 whatsapp_connections tem status/last_error/connected_at', '3',
      (select count(*) from information_schema.columns where table_schema='public' and table_name='whatsapp_connections'
         and column_name in ('status','last_error','connected_at'))::text)
)
select item, esperado, atual, case when esperado = atual then 'PASS' else 'FAIL' end as resultado
from checks order by item;
