-- Run this in the Supabase dashboard: SQL Editor > New query.
--
-- Audit trail for evolution entries: "createdBy" is already covered by the
-- existing fisioterapeuta_id column (just wasn't read back into the app
-- before), and created_at already exists too — only updated_at is new,
-- set explicitly by the app whenever an evolution entry is edited.

alter table public.evolution_entries
add column updated_at timestamptz;
