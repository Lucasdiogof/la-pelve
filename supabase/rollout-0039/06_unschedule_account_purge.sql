-- Para o agendamento da purga. Os pedidos de exclusao continuam guardados (nada e apagado).
select cron.unschedule('account-purge');
