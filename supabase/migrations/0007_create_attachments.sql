-- Run this in the Supabase dashboard: SQL Editor > New query.
--
-- Patient attachments (ficha de avaliação física + general anexos) — raw
-- bytes live in a private Storage bucket, metadata lives in this table so
-- the Anexos tab can list them without listing the bucket directly.
-- Storage paths are "{fisioterapeuta_id}/{patient_id}/{attachment_id}_{file_name}",
-- so a simple folder-prefix check is enough for Storage RLS.

insert into storage.buckets (id, name, public)
values ('patient-attachments', 'patient-attachments', false)
on conflict (id) do nothing;

create policy "Fisioterapeuta manages own attachment files"
on storage.objects for all
using (
  bucket_id = 'patient-attachments'
  and (storage.foldername(name)) [1] = auth.uid ()::text
)
with check (
  bucket_id = 'patient-attachments'
  and (storage.foldername(name)) [1] = auth.uid ()::text
);

create table public.attachments (
  id text primary key,
  fisioterapeuta_id uuid not null default auth.uid () references auth.users (id) on delete cascade,
  patient_id text not null references public.patients (id) on delete cascade,
  storage_path text not null,
  file_name text not null default '',
  content_type text not null default '',
  category text not null default 'outro',
  created_at timestamptz not null default now ()
);

alter table public.attachments enable row level security;

create policy "Fisioterapeuta manages own attachments"
on public.attachments for all
using (auth.uid () = fisioterapeuta_id)
with check (auth.uid () = fisioterapeuta_id);
