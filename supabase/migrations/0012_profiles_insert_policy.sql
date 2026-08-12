-- Run this in the Supabase dashboard: SQL Editor > New query.
--
-- profiles only had select/update RLS policies (rows are normally created
-- by the handle_new_user() trigger, which is SECURITY DEFINER and bypasses
-- RLS). Added an insert policy so the app can self-heal: if a signed-in
-- user's profiles row is missing (e.g. an account created before this
-- table/trigger existed), ProfileRepositorySupabase.getCurrent() now
-- creates a minimal row on the fly instead of failing.

create policy "Users can insert own profile"
on public.profiles for insert
with check (auth.uid () = id);
