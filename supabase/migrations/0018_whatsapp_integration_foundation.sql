-- Run this in the Supabase dashboard: SQL Editor > New query
-- (or: npx supabase db query -f <this file> --linked).
--
-- Camada de banco para a futura integração multi-profissional com a
-- WhatsApp Cloud API (cada fisioterapeuta conecta o próprio número).
-- Esta migration SÓ prepara o schema: não envia nada, não guarda token nem
-- segredo da Meta, e não muda o comportamento atual do app.
-- Idempotente: pode rodar de novo sem efeito colateral.
--
-- ---------------------------------------------------------------------
-- REGRAS DE PRODUTO (documentadas aqui; o scheduler vem em outra etapa)
-- ---------------------------------------------------------------------
--  * Lembrete: 12 horas antes do horário da consulta (reminder_type
--    'appointment_12h'). scheduled_for = início da consulta - 12h, no fuso
--    do profissional (profiles.timezone).
--  * Consulta criada com menos de 12h de antecedência: não recebe lembrete.
--  * Silêncio: 22:00 até 06:59 no fuso do profissional. Se scheduled_for
--    cair nesse intervalo, é movido para 07:00.
--  * Não envia quando: a consulta está cancelada; appointments.patient_id é
--    nulo; não há consentimento ativo (patient_consents com revoked_at
--    nulo, channel 'whatsapp', purpose 'appointment_reminder'); ou o
--    paciente não tem patients.phone_e164 válido.
--  * No máximo um envio por (appointment_id, reminder_type): garantido pelo
--    UNIQUE em whatsapp_messages.
--  * Horário alterado ANTES do envio: scheduled_for poderá ser recalculado.
--  * Consulta remarcada DEPOIS do envio: tratado em etapa posterior.
--  * whatsapp_messages guarda só metadados de envio, nunca o corpo.
--  * Credenciais da Meta NÃO ficam em nenhuma tabela deste schema.
--
-- ---------------------------------------------------------------------
-- 1. profiles: fuso horário do profissional
-- ---------------------------------------------------------------------
alter table public.profiles
  add column if not exists timezone text not null default 'America/Sao_Paulo';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'profiles_timezone_valid'
      and conrelid = 'public.profiles'::regclass
  ) then
    -- timezone() levanta erro para nome de fuso inexistente.
    alter table public.profiles
      add constraint profiles_timezone_valid
      check (timezone(timezone, timestamp '2000-01-01 00:00:00') is not null);
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 2. patients: telefone normalizado para WhatsApp (patients.phone intacto)
-- ---------------------------------------------------------------------
alter table public.patients
  add column if not exists phone_e164 text;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'patients_phone_e164_format'
      and conrelid = 'public.patients'::regclass
  ) then
    alter table public.patients
      add constraint patients_phone_e164_format
      check (phone_e164 is null or phone_e164 ~ '^\+[1-9][0-9]{7,14}$');
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 3. Chaves únicas auxiliares para FKs compostas (mesmo dono)
--    Uma FK simples só prova que o paciente/consulta existe, não que é do
--    mesmo fisioterapeuta. Referenciando (id, fisioterapeuta_id) o banco
--    recusa associar dados de outro profissional, mesmo com service role.
--    `id` já é PK, então estes índices únicos nunca falham.
-- ---------------------------------------------------------------------
create unique index if not exists patients_id_owner_key
  on public.patients (id, fisioterapeuta_id);

create unique index if not exists appointments_id_owner_key
  on public.appointments (id, fisioterapeuta_id);

-- ---------------------------------------------------------------------
-- 4. Função utilitária de updated_at
-- ---------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- 5. patient_consents: histórico de consentimento (nunca sobrescrito)
-- ---------------------------------------------------------------------
create table if not exists public.patient_consents (
  id uuid primary key default gen_random_uuid(),
  fisioterapeuta_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  patient_id text not null,
  channel text not null,
  purpose text not null,
  granted_at timestamptz not null default now(),
  revoked_at timestamptz,
  source text,
  created_at timestamptz not null default now(),
  constraint patient_consents_patient_owner_fkey
    foreign key (patient_id, fisioterapeuta_id)
    references public.patients (id, fisioterapeuta_id) on delete cascade,
  constraint patient_consents_revoked_after_granted
    check (revoked_at is null or revoked_at >= granted_at)
);

create index if not exists patient_consents_fisioterapeuta_id_idx
  on public.patient_consents (fisioterapeuta_id);
create index if not exists patient_consents_patient_id_idx
  on public.patient_consents (patient_id);

-- No máximo um consentimento ATIVO por paciente/canal/finalidade.
-- Revogar e conceder de novo cria uma linha nova (histórico preservado).
create unique index if not exists patient_consents_one_active_key
  on public.patient_consents (patient_id, channel, purpose)
  where revoked_at is null;

-- A única alteração permitida numa linha existente é revogar:
-- revoked_at passa de nulo para um valor. Nada mais muda, nem desfaz.
create or replace function public.patient_consents_only_revoke()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.revoked_at is not null then
    raise exception 'consent already revoked; create a new consent row instead';
  end if;
  if new.revoked_at is null then
    raise exception 'consent history is append-only; only revocation is allowed';
  end if;
  if new.id is distinct from old.id
     or new.fisioterapeuta_id is distinct from old.fisioterapeuta_id
     or new.patient_id is distinct from old.patient_id
     or new.channel is distinct from old.channel
     or new.purpose is distinct from old.purpose
     or new.granted_at is distinct from old.granted_at
     or new.source is distinct from old.source
     or new.created_at is distinct from old.created_at then
    raise exception 'consent history is append-only; only revoked_at can change';
  end if;
  return new;
end;
$$;

drop trigger if exists patient_consents_only_revoke on public.patient_consents;
create trigger patient_consents_only_revoke
  before update on public.patient_consents
  for each row execute function public.patient_consents_only_revoke();

alter table public.patient_consents enable row level security;

revoke all on public.patient_consents from anon, authenticated;
grant select, insert on public.patient_consents to authenticated;
grant update (revoked_at) on public.patient_consents to authenticated;
-- Sem DELETE para o app: o histórico só some junto com o paciente/conta
-- (cascade), nunca por exclusão direta.

drop policy if exists "Fisioterapeuta reads own consents" on public.patient_consents;
create policy "Fisioterapeuta reads own consents"
on public.patient_consents for select
using (auth.uid() = fisioterapeuta_id);

drop policy if exists "Fisioterapeuta inserts own consents" on public.patient_consents;
create policy "Fisioterapeuta inserts own consents"
on public.patient_consents for insert
with check (auth.uid() = fisioterapeuta_id);

drop policy if exists "Fisioterapeuta revokes own consents" on public.patient_consents;
create policy "Fisioterapeuta revokes own consents"
on public.patient_consents for update
using (auth.uid() = fisioterapeuta_id)
with check (auth.uid() = fisioterapeuta_id);

-- ---------------------------------------------------------------------
-- 6. whatsapp_connections: número do WhatsApp de cada profissional
--    Sem token, sem segredo. Escrita só pelo backend (service role).
-- ---------------------------------------------------------------------
create table if not exists public.whatsapp_connections (
  id uuid primary key default gen_random_uuid(),
  fisioterapeuta_id uuid not null unique
    references auth.users (id) on delete cascade,
  waba_id text,
  phone_number_id text unique,
  display_phone_number text,
  status text not null default 'pending',
  connected_at timestamptz,
  disconnected_at timestamptz,
  last_error jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint whatsapp_connections_status_valid
    check (status in ('pending', 'connected', 'disconnected', 'error')),
  constraint whatsapp_connections_connected_complete
    check (
      status <> 'connected'
      or (waba_id is not null
          and phone_number_id is not null
          and connected_at is not null)
    )
);

drop trigger if exists whatsapp_connections_touch_updated_at
  on public.whatsapp_connections;
create trigger whatsapp_connections_touch_updated_at
  before update on public.whatsapp_connections
  for each row execute function public.touch_updated_at();

alter table public.whatsapp_connections enable row level security;

revoke all on public.whatsapp_connections from anon, authenticated;
grant select on public.whatsapp_connections to authenticated;

drop policy if exists "Fisioterapeuta reads own whatsapp connection"
  on public.whatsapp_connections;
create policy "Fisioterapeuta reads own whatsapp connection"
on public.whatsapp_connections for select
using (auth.uid() = fisioterapeuta_id);

-- ---------------------------------------------------------------------
-- 7. whatsapp_messages: metadados de envio (nunca o corpo da mensagem)
--    Leitura pelo dono; escrita só pelo backend (service role).
-- ---------------------------------------------------------------------
create table if not exists public.whatsapp_messages (
  id uuid primary key default gen_random_uuid(),
  fisioterapeuta_id uuid not null
    references auth.users (id) on delete cascade,
  patient_id text not null,
  appointment_id text not null,
  reminder_type text not null,
  wamid text unique,
  template_name text,
  status text not null default 'scheduled',
  scheduled_for timestamptz not null,
  sent_at timestamptz,
  delivered_at timestamptz,
  read_at timestamptz,
  failed_at timestamptz,
  error jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint whatsapp_messages_patient_owner_fkey
    foreign key (patient_id, fisioterapeuta_id)
    references public.patients (id, fisioterapeuta_id) on delete cascade,
  -- Mesmo dono da consulta. A coerência "paciente da mensagem = paciente
  -- atual da consulta" NÃO é imposta aqui de propósito: o app pode trocar ou
  -- limpar appointments.patient_id a qualquer momento e isso não pode travar
  -- a edição da consulta. O scheduler (etapa futura) deve reler o paciente a
  -- partir da consulta no momento do envio e cancelar linhas não enviadas
  -- quando o paciente mudar.
  constraint whatsapp_messages_appointment_owner_fkey
    foreign key (appointment_id, fisioterapeuta_id)
    references public.appointments (id, fisioterapeuta_id)
    on delete cascade,
  constraint whatsapp_messages_reminder_type_valid
    check (reminder_type in ('appointment_12h')),
  constraint whatsapp_messages_status_valid
    check (status in (
      'scheduled', 'processing', 'sent', 'delivered', 'read',
      'failed', 'cancelled'
    )),
  constraint whatsapp_messages_one_per_appointment_type
    unique (appointment_id, reminder_type)
);

create index if not exists whatsapp_messages_fisioterapeuta_id_idx
  on public.whatsapp_messages (fisioterapeuta_id);
create index if not exists whatsapp_messages_patient_id_idx
  on public.whatsapp_messages (patient_id);
-- Fila do futuro scheduler: só o que ainda precisa ser processado.
create index if not exists whatsapp_messages_due_idx
  on public.whatsapp_messages (scheduled_for)
  where status in ('scheduled', 'processing');

drop trigger if exists whatsapp_messages_touch_updated_at
  on public.whatsapp_messages;
create trigger whatsapp_messages_touch_updated_at
  before update on public.whatsapp_messages
  for each row execute function public.touch_updated_at();

alter table public.whatsapp_messages enable row level security;

revoke all on public.whatsapp_messages from anon, authenticated;
grant select on public.whatsapp_messages to authenticated;

drop policy if exists "Fisioterapeuta reads own whatsapp messages"
  on public.whatsapp_messages;
create policy "Fisioterapeuta reads own whatsapp messages"
on public.whatsapp_messages for select
using (auth.uid() = fisioterapeuta_id);

comment on table public.whatsapp_messages is
  'Metadados de envio de lembretes (sem corpo). Regra: 12h antes, silencio 22:00-06:59 no fuso do profissional (move para 07:00), 1 envio por (appointment_id, reminder_type). Escrita so via service role.';
comment on table public.whatsapp_connections is
  'Conexao WhatsApp por profissional. Sem token/segredo. Escrita so via service role.';
comment on table public.patient_consents is
  'Historico append-only de consentimento. Unico UPDATE permitido: revoked_at nulo -> valor.';

-- ---------------------------------------------------------------------
-- Check (read-only):
--   tabelas novas com RLS ligada -> 3 linhas, todas rls = true
--   colunas novas                -> 2 linhas
-- ---------------------------------------------------------------------
select c.relname as tabela, c.relrowsecurity as rls
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('patient_consents', 'whatsapp_connections', 'whatsapp_messages')
order by c.relname;

select table_name, column_name
from information_schema.columns
where table_schema = 'public'
  and ((table_name = 'profiles' and column_name = 'timezone')
    or (table_name = 'patients' and column_name = 'phone_e164'))
order by table_name;
