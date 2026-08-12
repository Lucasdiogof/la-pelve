-- Run this in the Supabase dashboard: SQL Editor > New query.
--
-- Agendamentos podem ser vinculados a um paciente cadastrado, mas continuam
-- aceitando nome livre (mesmo padrão já usado em financial_entries).

alter table public.appointments
add column patient_id text references public.patients (id) on delete cascade;
