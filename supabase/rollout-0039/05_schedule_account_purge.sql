-- AGENDAMENTO da purga de contas com prazo vencido (NAO e migration; NAO aplicar sem autorizacao).
-- Roda 1x por dia: pg_cron chama a Edge Function account-purge por pg_net com Authorization: Bearer <ACCOUNT_PURGE_TOKEN>.
-- Sem o cron, os pedidos de exclusao ficam pendentes (nada e apagado): e o estado seguro.
--
-- Pre-requisitos, nesta ordem:
--   1. migrations 0039, 0040 e 0041 aplicadas (pos-check PASS);
--   2. Edge Function account-purge deployada com o secret ACCOUNT_PURGE_TOKEN (>= 32 caracteres);
--   3. teste com conta descartavel: pedir exclusao, adiantar o prazo no banco de TESTE e conferir a purga.
-- Troque os <...> NO EDITOR (nunca commite os valores). URL e token ficam no Vault.

create extension if not exists pg_cron;
create extension if not exists pg_net;

select vault.create_secret('<ACCOUNT_PURGE_TOKEN>', 'account_purge_token', 'Bearer do cron para account-purge');
select vault.create_secret('https://lchaboncmgcimafpupad.supabase.co/functions/v1/account-purge',
                           'account_purge_url', 'URL da Edge Function account-purge');

select cron.schedule(
  'account-purge',
  '30 6 * * *',
  $job$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'account_purge_url'),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'account_purge_token')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 120000
  );
  $job$
);
