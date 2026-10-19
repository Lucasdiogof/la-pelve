-- ROLLBACK da 0039: volta delete_own_account() ao comportamento anterior (0009 + grants da 0031) e remove as funcoes novas.
-- As colunas profiles.custody_confirmed_* PERMANECEM de proposito (sao aditivas e inofensivas; apagar coluna perderia o registro do ato).
-- ATENCAO: reverter reabre o risco de exclusao em cascata sem trava. Use so se a trava bloquear algo legitimo.
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;
revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;
drop function if exists public.check_account_deletion_allowed();
drop function if exists public.confirm_clinical_data_custody(text);
select to_regprocedure('public.check_account_deletion_allowed()') is null
   and to_regprocedure('public.confirm_clinical_data_custody(text)') is null as removidas;
