-- ROLLBACK da 0022. Restaura exatamente a função da 0021 (created_at volta
-- a não ser controlado pelo trigger).
--
--   npx.cmd supabase db query -f supabase/rollout-0022/03_rollback.sql --linked --project-ref lchaboncmgcimafpupad
--
-- A 0022 não cria coluna nem dado histórico novo (só substitui a função),
-- então este rollback não precisa de trava: não há nenhum dado que fique
-- irrecuperável ao reverter. Ele REMOVE a proteção de created_at (um
-- cliente authenticated via PostgREST manual volta a conseguir
-- definir/alterar created_at), mas não perde nenhum dado — todas as linhas
-- existentes mantêm seus valores atuais de created_at, schedule_revision e
-- schedule_revision_at exatamente como estão.
-- Idempotente. Nunca roda automaticamente.

create or replace function public.set_appointment_schedule_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.schedule_revision = 0;
    new.schedule_revision_at = new.created_at;
  elsif tg_op = 'UPDATE' then
    if new.date is distinct from old.date or new.time is distinct from old.time then
      new.schedule_revision = old.schedule_revision + 1;
      new.schedule_revision_at = clock_timestamp();
    else
      new.schedule_revision = old.schedule_revision;
      new.schedule_revision_at = old.schedule_revision_at;
    end if;
  end if;
  return new;
end;
$$;

comment on column public.appointments.created_at is
  'Instante em que o appointment foi criado. DEFAULT now(); nao ha mais '
  'proteção de trigger contra alteração pelo cliente (rollback da 0022).';
