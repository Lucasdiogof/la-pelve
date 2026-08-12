-- Run this in the Supabase dashboard: SQL Editor > New query.
--
-- Patients/Evolução/Financeiro/Agenda tables. Each fisioterapeuta only
-- sees their own data — RLS scoped to `auth.uid() = fisioterapeuta_id`,
-- same pattern as profiles (0001_create_profiles.sql).
--
-- `Patient`'s ~50 nested/optional anamnesis fields (anamnese, histórico
-- ginecológico/obstétrico/cirúrgico, função urinária/sexual/intestinal)
-- are stored as JSONB — they mirror the nested value classes in
-- lib/features/patients/domain/entities/patient.dart 1:1 (keys match the
-- Dart field names), so no relational modeling was worth it here.
--
-- IDs are `text`, generated client-side by generateId()
-- (lib/shared/utils/id_generator.dart) — not `uuid`/gen_random_uuid().

create table public.patients (
  id text primary key,
  fisioterapeuta_id uuid not null default auth.uid () references auth.users (id) on delete cascade,
  created_at timestamptz not null default now (),
  nome text not null default '',
  idade integer,
  telefone text not null default '',
  profissao text not null default '',
  anamnese jsonb not null default '{}'::jsonb,
  historico_ginecologico jsonb not null default '{}'::jsonb,
  historico_obstetrico jsonb not null default '{}'::jsonb,
  historico_cirurgico jsonb not null default '{}'::jsonb,
  funcao_urinaria jsonb not null default '{}'::jsonb,
  funcao_sexual jsonb not null default '{}'::jsonb,
  funcao_intestinal jsonb not null default '{}'::jsonb,
  valor_consulta numeric
);

alter table public.patients enable row level security;

create policy "Fisioterapeuta manages own patients"
on public.patients for all
using (auth.uid () = fisioterapeuta_id)
with check (auth.uid () = fisioterapeuta_id);

create table public.evolution_entries (
  id text primary key,
  patient_id text not null references public.patients (id) on delete cascade,
  fisioterapeuta_id uuid not null default auth.uid () references auth.users (id) on delete cascade,
  data date not null,
  descricao text not null,
  created_at timestamptz not null default now ()
);

alter table public.evolution_entries enable row level security;

create policy "Fisioterapeuta manages own evolutions"
on public.evolution_entries for all
using (auth.uid () = fisioterapeuta_id)
with check (auth.uid () = fisioterapeuta_id);

create table public.financial_entries (
  id text primary key,
  patient_id text not null references public.patients (id) on delete cascade,
  fisioterapeuta_id uuid not null default auth.uid () references auth.users (id) on delete cascade,
  patient_name text not null default '',
  data date not null,
  valor numeric not null,
  observacoes text not null default '',
  created_at timestamptz not null default now ()
);

alter table public.financial_entries enable row level security;

create policy "Fisioterapeuta manages own financial entries"
on public.financial_entries for all
using (auth.uid () = fisioterapeuta_id)
with check (auth.uid () = fisioterapeuta_id);

-- No FK to patients — appointments are visual-only records, per spec
-- ("apenas campos visuais, não terá ligação com o paciente em si").
create table public.appointments (
  id text primary key,
  fisioterapeuta_id uuid not null default auth.uid () references auth.users (id) on delete cascade,
  data date not null,
  hora time not null,
  nome_paciente text not null default '',
  created_at timestamptz not null default now ()
);

alter table public.appointments enable row level security;

create policy "Fisioterapeuta manages own appointments"
on public.appointments for all
using (auth.uid () = fisioterapeuta_id)
with check (auth.uid () = fisioterapeuta_id);
