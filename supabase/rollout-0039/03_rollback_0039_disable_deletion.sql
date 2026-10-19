-- CONTINGENCIA SEGURA da 0039: se a trava impedir algo legitimo ou tiver defeito, DESLIGA a exclusao de conta por completo.
-- Ninguem exclui conta ate a correcao (conta vazia tambem fica fora): perda de dado impossivel. NAO restaura o cascade.
-- Mantem tabelas de log/recibo e as funcoes de leitura. Recuperacao: reaplicar a 0039 corrigida.
begin;
set local lock_timeout = '3s';
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  raise exception 'account_deletion_disabled' using errcode = 'P0001';
end;
$$;
revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;
commit;
select pg_get_functiondef(to_regprocedure('public.delete_own_account()')) like '%account_deletion_disabled%' as exclusao_desligada;
