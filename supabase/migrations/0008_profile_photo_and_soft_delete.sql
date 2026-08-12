-- Run this in the Supabase dashboard: SQL Editor > New query.
--
-- Two independent changes:
-- 1) Profile photo: profiles.foto_path (Storage path, same private-bucket +
--    signed-URL pattern as patient-attachments) for the new Perfil screen.
-- 2) Soft delete for patients: prontuário records must not be hard-deleted
--    (retention requirement), so "Excluir paciente" now sets deleted_at
--    instead of removing the row. Reads filter deleted_at is null.

alter table public.patients
add column deleted_at timestamptz;

alter table public.profiles
add column foto_path text;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', false)
on conflict (id) do nothing;

create policy "Fisioterapeuta manages own avatar"
on storage.objects for all
using (
  bucket_id = 'avatars'
  and (storage.foldername(name)) [1] = auth.uid ()::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name)) [1] = auth.uid ()::text
);
