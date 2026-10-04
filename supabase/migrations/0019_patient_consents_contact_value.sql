-- Run this in the Supabase dashboard: SQL Editor > New query
-- (or: npx supabase db query -f <this file> --linked).
--
-- Registra QUAL destino foi autorizado no consentimento: o telefone no
-- momento da autorização. Sem isso, se o paciente trocar de número, o
-- consentimento antigo continuaria "valendo" para um número que ninguém
-- autorizou.
--
-- Para channel = 'whatsapp' (purpose = 'appointment_reminder'), contact_value
-- guarda o telefone E.164 autorizado, ex.: +5562999999999.
--
-- Pequena e aditiva: 1 coluna + 1 check em patient_consents e a nova versão
-- do trigger append-only. Não toca em nenhuma outra tabela nem em dado antigo.
-- Idempotente: pode rodar de novo sem efeito colateral.
--
-- Pré-condição: patient_consents VAZIA. É isso que permite a coluna NOT NULL
-- sem default e sem backfill. Se já houver linhas e a coluna ainda não
-- existir, a migration ABORTA em vez de inventar um valor.

do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'patient_consents'
      and column_name = 'contact_value'
  ) and exists (select 1 from public.patient_consents) then
    raise exception
      '0019 abortada: patient_consents ja tem linhas e contact_value nao existe; exigiria backfill (decisao manual).';
  end if;
end $$;

alter table public.patient_consents
  add column if not exists contact_value text not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'patient_consents_contact_value_e164'
      and conrelid = 'public.patient_consents'::regclass
  ) then
    alter table public.patient_consents
      add constraint patient_consents_contact_value_e164
      check (channel <> 'whatsapp' or contact_value ~ '^\+[1-9][0-9]{7,14}$');
  end if;
end $$;

-- Mesmo trigger da 0018 + contact_value passa a ser imutável depois de criado.
-- (O grant de UPDATE do app continua só em revoked_at; este trigger é a
-- segunda barreira, que vale também para service role e para o dono.)
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
     or new.contact_value is distinct from old.contact_value
     or new.granted_at is distinct from old.granted_at
     or new.source is distinct from old.source
     or new.created_at is distinct from old.created_at then
    raise exception 'consent history is append-only; only revoked_at can change';
  end if;
  return new;
end;
$$;

comment on column public.patient_consents.contact_value is
  'Destino autorizado no momento do consentimento (whatsapp: telefone E.164). Imutavel.';

-- Check (read-only): 1 linha para a coluna (text, NOT NULL) e 1 para a constraint.
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'patient_consents' and column_name = 'contact_value';

select conname
from pg_constraint
where conname = 'patient_consents_contact_value_e164'
  and conrelid = 'public.patient_consents'::regclass;
