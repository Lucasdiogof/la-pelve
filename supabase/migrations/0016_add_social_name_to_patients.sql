-- Run this in the Supabase dashboard: SQL Editor > New query.
--
-- Adds an optional social name field, separate from the legal name.
-- Nullable: existing patients have no social name on file.

alter table public.patients
add column social_name text;
