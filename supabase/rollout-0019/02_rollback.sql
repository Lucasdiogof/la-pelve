-- ROLLBACK da 0019: remove SÓ contact_value e o check novo, e restaura o
-- trigger patient_consents_only_revoke exatamente como estava na 0018.
-- Não toca em nenhuma outra tabela nem em dado antigo.
--
-- Trava: se patient_consents já tem linhas, ABORTA (dropar a coluna destruiria
-- o destino autorizado de cada consentimento, que é registro legal). Exporte
-- antes e só então repita.
-- Idempotente.

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'patient_consents' and column_name = 'contact_value'
  ) and exists (select 1 from public.patient_consents) then
    raise exception 'ROLLBACK ABORTADO: patient_consents ja tem linhas; contact_value seria perdido. Exporte antes de repetir.';
  end if;
end $$;

alter table public.patient_consents
  drop constraint if exists patient_consents_contact_value_e164;

-- Restaura a função na versão da 0018 (antes de dropar a coluna que ela cita).
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

alter table public.patient_consents
  drop column if exists contact_value;
