-- Run this in the Supabase dashboard: SQL Editor > New query.
--
-- Sexo gates whether the wizard shows Histórico Ginecológico/Obstétrico
-- (see lib/features/patients/presentation/cubit/patient_form_cubit.dart).
-- Nullable: patients created before this migration have no sexo on file.

alter table public.patients
add column sexo text;
