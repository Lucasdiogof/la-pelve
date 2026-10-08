-- PRE-FLIGHT da migration 0026 (dispatch real + credenciais no Vault).
-- SOMENTE LEITURA. Não aplica nada.
--
--   npx.cmd supabase db query -f supabase/rollout-0026/01_preflight_readonly.sql --linked --project-ref lchaboncmgcimafpupad
--
-- Esperado: todas as linhas PASS. A linha 01 confirma a capacidade REAL do
-- projeto: sem supabase_vault a migration aborta (não aplicar).

with checks(item, esperado, atual) as (
  values
    ('01 extensao supabase_vault instalada', 'true',
      exists (select 1 from pg_extension where extname = 'supabase_vault')::text),
    ('02 vault.create_secret / update_secret / decrypted_secrets existem', '3',
      ((select count(*) from pg_proc
        where pronamespace = to_regnamespace('vault')
          and proname in ('create_secret', 'update_secret'))
       + (case when to_regclass('vault.decrypted_secrets') is not null then 1 else 0 end))::text),
    ('03 migration 0025 aplicada', 'true',
      (to_regclass('public.whatsapp_inbound_messages') is not null)::text),
    ('04 whatsapp_connection_credentials ainda nao existe', 'false',
      (to_regclass('public.whatsapp_connection_credentials') is not null)::text),
    ('05 nenhuma whatsapp_message em processing (sem dispatcher antigo rodando)', '0',
      (select count(*) from public.whatsapp_messages where status = 'processing')::text)
)
select item, esperado, atual,
  case when esperado = atual then 'PASS' else 'FAIL' end as resultado
from checks
order by item;

-- Informativo (não é PASS/FAIL): versão do Vault e se pg_cron/pg_net já
-- estão ativos (necessários só para 05_schedule_cron.sql).
select extname, extversion from pg_extension
where extname in ('supabase_vault', 'pg_cron', 'pg_net')
order by extname;
