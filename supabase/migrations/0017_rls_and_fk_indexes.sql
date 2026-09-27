-- Run this in the Supabase dashboard: SQL Editor > New query.
--
-- Indexes for the columns every RLS policy and every cascade filters on.
-- Each clinical table's policy is `auth.uid() = fisioterapeuta_id`
-- (`physiotherapist_id` on evolution_entries), and
-- deleting a patient cascades through `patient_id`; without an index both
-- scan the whole table, which grows with every evolution/appointment.
-- No behavior change. Idempotent (`if not exists`), safe to run again.

create index if not exists patients_fisioterapeuta_id_idx
  on public.patients (fisioterapeuta_id);

-- evolution_entries is the one table 0011 renamed to physiotherapist_id.
create index if not exists evolution_entries_physiotherapist_id_idx
  on public.evolution_entries (physiotherapist_id);
create index if not exists evolution_entries_patient_id_idx
  on public.evolution_entries (patient_id);

create index if not exists financial_entries_fisioterapeuta_id_idx
  on public.financial_entries (fisioterapeuta_id);
create index if not exists financial_entries_patient_id_idx
  on public.financial_entries (patient_id);

create index if not exists appointments_fisioterapeuta_id_idx
  on public.appointments (fisioterapeuta_id);
create index if not exists appointments_patient_id_idx
  on public.appointments (patient_id);

create index if not exists attachments_fisioterapeuta_id_idx
  on public.attachments (fisioterapeuta_id);
create index if not exists attachments_patient_id_idx
  on public.attachments (patient_id);

-- Check (read-only): should return 9 rows.
select indexname
from pg_indexes
where schemaname = 'public'
  and indexname in (
    'patients_fisioterapeuta_id_idx',
    'evolution_entries_physiotherapist_id_idx',
    'evolution_entries_patient_id_idx',
    'financial_entries_fisioterapeuta_id_idx',
    'financial_entries_patient_id_idx',
    'appointments_fisioterapeuta_id_idx',
    'appointments_patient_id_idx',
    'attachments_fisioterapeuta_id_idx',
    'attachments_patient_id_idx'
  )
order by indexname;
