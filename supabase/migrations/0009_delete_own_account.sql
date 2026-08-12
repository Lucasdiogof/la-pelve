-- Run this in the Supabase dashboard: SQL Editor > New query.
--
-- Lets a logged-in fisioterapeuta delete their own account from the app
-- (Perfil > Excluir minha conta). The Flutter client only has the
-- publishable/anon key, which can't call auth.admin.deleteUser() directly
-- (that needs the service_role key) — so this SECURITY DEFINER function
-- does the deletion on the client's behalf, restricted to auth.uid()'s
-- own row. Every app table already has
-- "references auth.users(id) on delete cascade", so deleting the
-- auth.users row cascades to profiles/patients/evolution_entries/
-- financial_entries/appointments/attachments automatically. Storage
-- objects (actual files) are NOT covered by that cascade — the app
-- deletes them client-side, best-effort, before calling this function.

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

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;
