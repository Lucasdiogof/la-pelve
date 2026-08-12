-- Run this in the Supabase dashboard: SQL Editor > New query.
--
-- Lançamentos no longer require picking an existing patient — the
-- fisioterapeuta can type a name freely instead. patient_id stays as an
-- optional link (FK + cascade delete still apply when it is set).

alter table public.financial_entries
alter column patient_id drop not null;
