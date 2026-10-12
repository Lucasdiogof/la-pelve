select cron.alter_job(
  (select jobid from cron.job where jobname = 'la_pelve_whatsapp_dispatcher_30min'),
  schedule := '*/30 * * * *'
);
