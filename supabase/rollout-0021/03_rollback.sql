-- ROLLBACK da 0021. Restaura exatamente o estado pós-0020:
-- schedule_revision_at removido, função set_appointment_schedule_revision()
-- de volta à versão que só conhece schedule_revision.
--
--   npx.cmd supabase db query -f supabase/rollout-0021/03_rollback.sql --linked --project-ref lchaboncmgcimafpupad
--
-- Trava obrigatória (ABORTA): existe appointment com schedule_revision > 0
-- — isso significa que já houve remarcação real rastreada, e
-- schedule_revision_at dessas linhas NÃO é reconstruível a partir de
-- created_at (que só vale para a revisão 0). Esta é a única informação
-- que este rollback pode perder de forma irreversível.
--
-- NÃO há uma segunda trava bloqueante para "revision 0 com
-- schedule_revision_at != created_at". Motivo: desde a correção do
-- trigger de INSERT (schedule_revision_at = NEW.created_at, nunca
-- clock_timestamp()), essa igualdade é garantida por construção no
-- momento da criação — mas created_at em si não tem, hoje, nenhuma
-- proteção que impeça uma correção administrativa posterior (ex.: SQL
-- manual no painel, ajustando created_at de um registro migrado de outro
-- sistema). Se isso acontecer, created_at muda mas schedule_revision_at
-- fica congelado no valor original — uma divergência legítima que NÃO
-- representa remarcação não-rastreada, e que já existia como
-- possibilidade antes desta migration (fora do escopo dela corrigir).
-- Bloquear o rollback nesse caso seria um falso positivo. Em vez disso,
-- avisa (RAISE NOTICE, não EXCEPTION) para o operador decidir com
-- contexto, sem travar uma operação seguro.
--
-- Idempotente quando seguro. Nunca roda automaticamente.

do $$
begin
  if exists (select 1 from public.appointments where schedule_revision > 0) then
    raise exception
      'ROLLBACK ABORTADO: existe pelo menos 1 appointment com '
      'schedule_revision > 0 — ja houve remarcacao real rastreada. '
      'schedule_revision_at dessas linhas nao e reconstruivel a partir '
      'de created_at. Exporte (select id, schedule_revision, '
      'schedule_revision_at from appointments where schedule_revision > 0) '
      'antes de repetir.';
  end if;
end $$;

do $$
declare
  v_divergentes int;
begin
  select count(*) into v_divergentes
  from public.appointments
  where schedule_revision = 0 and schedule_revision_at is distinct from created_at;

  if v_divergentes > 0 then
    raise notice
      'AVISO (nao bloqueia o rollback): % appointment(s) em revision 0 '
      'com schedule_revision_at != created_at. Isso pode ser legitimo '
      '(ex.: created_at foi corrigido manualmente depois da criacao) e '
      'nao representa remarcacao nao-rastreavel — a coluna que esta '
      'sendo removida (schedule_revision_at) nao carrega, em revision 0, '
      'nenhuma informacao que created_at ja nao tivesse. Revise '
      'manualmente se quiser confirmar a causa antes de continuar.',
      v_divergentes;
  end if;
end $$;

-- Restaura a função exatamente como estava na 0020 (só schedule_revision,
-- nunca toca em schedule_revision_at porque a coluna está prestes a sumir).
create or replace function public.set_appointment_schedule_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.schedule_revision = 0;
  elsif tg_op = 'UPDATE' then
    if new.date is distinct from old.date or new.time is distinct from old.time then
      new.schedule_revision = old.schedule_revision + 1;
    else
      new.schedule_revision = old.schedule_revision;
    end if;
  end if;
  return new;
end;
$$;

alter table public.appointments
  drop column if exists schedule_revision_at;
