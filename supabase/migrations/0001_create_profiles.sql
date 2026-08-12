-- Run this in the Supabase dashboard: SQL Editor > New query.
-- If you already ran an earlier version of this file, drop the old
-- objects first: drop table if exists public.profiles cascade;
-- drop function if exists public.get_email_by_cpf; drop function if
-- exists public.handle_new_user cascade;
--
-- Supabase Auth (auth.users) already handles email + password. This table
-- stores the extra fields collected at sign-up (nome, crefito, telefone)
-- and mirrors the email, keyed by the same id as the auth user.
--
-- Rows are created by the trigger below, not by the app: while email
-- confirmation is pending there's no active session yet, so a direct
-- insert from the app would be rejected by RLS. signUp() instead passes
-- nome/crefito/telefone as user metadata, and this SECURITY DEFINER
-- trigger copies it into profiles the moment the auth.users row exists —
-- confirmed or not.

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nome text not null,
  crefito text not null,
  telefone text not null,
  email text not null,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can view own profile"
on public.profiles for select
using (auth.uid () = id);

create policy "Users can update own profile"
on public.profiles for update
using (auth.uid () = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, nome, crefito, telefone, email)
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

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user ();
