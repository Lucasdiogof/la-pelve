-- NÃO APLICAR antes de: (1) migration 0028 aplicada; (2) dry-run
-- 01_dryrun_rollback.sql com legacy_after_gate = 0.
-- Troca a frequência do cron existente de 30 para 5 minutos (mesmo job,
-- mesma URL e mesmo token no Vault; nada é recriado).
select cron.alter_job(
  (select jobid from cron.job where jobname = 'la_pelve_whatsapp_dispatcher_30min'),
  schedule := '*/5 * * * *'
);
