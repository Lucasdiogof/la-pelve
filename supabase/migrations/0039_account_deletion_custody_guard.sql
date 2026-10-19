-- Trava de segurança da exclusão de conta (ADITIVA e idempotente; não apaga nem altera dados existentes).
--
-- Problema: delete_own_account() apaga auth.users e o ON DELETE CASCADE leva TODOS os registros clínicos
-- (inclusive pacientes já "excluídos" por soft delete) de forma irreversível, sem nenhuma etapa de custódia.
-- Prontuários podem ter dever de guarda (COFFITO 414/2012; Lei 13.787/2018) — ver docs/privacy/DATA_RETENTION.md.
--
-- Agora a exclusão só prossegue se a profissional registrou, nas últimas 24 h, que assumiu a custódia dos
-- registros (exportou ou assumiu a guarda por conta própria). A função NÃO decide a questão jurídica; ela só
-- impede a perda acidental e deixa o ato registrado.
--
-- ORDEM DE APLICAÇÃO: publicar primeiro a versão do app que chama confirm_clinical_data_custody(); só depois
-- aplicar esta migration. Versões antigas do app passam a receber o erro 'custody_not_confirmed' (falha segura)
-- ao tentar excluir a conta com registros clínicos.

alter table public.profiles
  add column if not exists custody_confirmed_at timestamptz,
  add column if not exists custody_confirmed_method text;

alter table public.profiles
  drop constraint if exists profiles_custody_method_check;
alter table public.profiles
  add constraint profiles_custody_method_check
  check (custody_confirmed_method is null
    or custody_confirmed_method in ('export_downloaded', 'declared_responsibility'));

-- Registra a custódia da própria conta. Só toca a linha de auth.uid().
create or replace function public.confirm_clinical_data_custody(p_method text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if p_method not in ('export_downloaded', 'declared_responsibility') then
    raise exception 'invalid custody method';
  end if;
  update public.profiles
     set custody_confirmed_at = now(),
         custody_confirmed_method = p_method
   where id = auth.uid();
end;
$$;

-- Levanta 'custody_not_confirmed' se há registros clínicos e a custódia não foi confirmada nas últimas 24 h.
create or replace function public.check_account_deletion_allowed()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  has_clinical boolean;
  confirmed_at timestamptz;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  select exists (select 1 from public.patients where fisioterapeuta_id = auth.uid())
      or exists (select 1 from public.evolution_entries where fisioterapeuta_id = auth.uid())
      or exists (select 1 from public.attachments where fisioterapeuta_id = auth.uid())
    into has_clinical;
  if not has_clinical then
    return;
  end if;
  select custody_confirmed_at into confirmed_at from public.profiles where id = auth.uid();
  if confirmed_at is null or confirmed_at < now() - interval '24 hours' then
    raise exception 'custody_not_confirmed' using errcode = 'P0001';
  end if;
end;
$$;

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
  perform public.check_account_deletion_allowed();
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.confirm_clinical_data_custody(text) from public, anon;
revoke all on function public.check_account_deletion_allowed() from public, anon;
revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.confirm_clinical_data_custody(text) to authenticated;
grant execute on function public.check_account_deletion_allowed() to authenticated;
grant execute on function public.delete_own_account() to authenticated;
