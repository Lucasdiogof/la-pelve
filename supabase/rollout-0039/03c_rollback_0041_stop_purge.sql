-- CONTINGENCIA da 0041: PARA a purga automatica sem apagar nada e sem aceitar novos pedidos.
-- Pedidos ja feitos ficam guardados (dados intactos); ninguem tem a conta finalizada ate a correcao.
-- Rode tambem 06_unschedule_account_purge.sql para parar o cron. Recuperacao: reaplicar a 0041 corrigida.
begin;
set local lock_timeout = '3s';
revoke execute on function public.finalize_account_deletion(uuid) from service_role;
revoke execute on function public.request_account_data_deletion(text) from authenticated;
commit;
select not has_function_privilege('service_role', 'public.finalize_account_deletion(uuid)', 'execute') as purga_parada;
