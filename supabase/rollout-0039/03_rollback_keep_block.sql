-- ROLLBACK SEGURO da 0039 (padrao): se a trava nova atrapalhar algo legitimo, NAO volte ao cascade sem trava.
-- Esta versao mantem delete_own_account() bloqueando contas com registros clinicos (erro 'account_deletion_disabled')
-- e permite apenas contas vazias. Remove as RPCs de custodia. Preserva colunas e account_deletion_log (evidencia).
-- Consequencia: ninguem com dados exclui a conta ate a correcao; nada e apagado. Recuperacao: reaplicar a 0039 corrigida.
begin;
set local lock_timeout = '3s';
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
  if exists (select 1 from public.patients where fisioterapeuta_id = auth.uid())
     or exists (select 1 from public.evolution_entries where physiotherapist_id = auth.uid())
     or exists (select 1 from public.attachments where fisioterapeuta_id = auth.uid())
     or exists (select 1 from public.appointments where fisioterapeuta_id = auth.uid())
     or exists (select 1 from public.financial_entries where fisioterapeuta_id = auth.uid()) then
    raise exception 'account_deletion_disabled' using errcode = 'P0001';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;
revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;
drop function if exists public.check_account_deletion_allowed();
drop function if exists public.confirm_clinical_data_custody(text);
commit;
select to_regprocedure('public.check_account_deletion_allowed()') is null
   and to_regprocedure('public.confirm_clinical_data_custody(text)') is null as removidas;
