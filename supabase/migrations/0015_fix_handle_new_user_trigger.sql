-- Run this in the Supabase dashboard: SQL Editor > New query.
--
-- Migration 0011 renamed profiles.nome -> name and profiles.telefone -> phone,
-- but ALTER TABLE ... RENAME COLUMN does not rewrite the body of PL/pgSQL
-- functions (unlike views/policies, which Postgres tracks as dependent
-- objects). handle_new_user() still inserted into the old column names,
-- so every sign-up since that migration has been failing inside the
-- trigger (the auth.users insert rolls back with "column nome of
-- relation profiles does not exist").

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name, crefito, phone, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nome', ''),
    coalesce(new.raw_user_meta_data ->> 'crefito', ''),
    coalesce(new.raw_user_meta_data ->> 'telefone', ''),
    new.email
  );
  return new;
end;
$$;
