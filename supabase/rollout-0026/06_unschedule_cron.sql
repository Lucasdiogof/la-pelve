-- Desliga o agendamento criado por 05_schedule_cron.sql (o pipeline para
-- de rodar; nada é apagado da fila). Os segredos do Vault ficam; para
-- removê-los: delete from vault.secrets where name in
-- ('whatsapp_dispatcher_token', 'whatsapp_dispatcher_url');

select cron.unschedule('whatsapp-dispatcher')
where exists (select 1 from cron.job where jobname = 'whatsapp-dispatcher');
