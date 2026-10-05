-- ROLLBACK da 0020 (v2 — schedule_revision). Restaura exatamente o estado
-- pós-0019 para appointments e whatsapp_messages.
--
--   npx.cmd supabase db query -f supabase/rollout-0020/02_rollback.sql --linked --project-ref lchaboncmgcimafpupad
--
-- Travas (aborta sem alterar nada se qualquer uma disparar):
--   1) qualquer whatsapp_message com reminder_type fora de
--      'appointment_12h' (o CHECK antigo rejeitaria);
--   2) qualquer par (appointment_id, reminder_type) duplicado (a UNIQUE
--      antiga, de 2 colunas, rejeitaria);
--   3) qualquer appointment com schedule_revision > 0 — indica que já
--      houve pelo menos uma remarcação real rastreada; apagar a coluna
--      destruiria essa informação de produção.
-- Idempotente quando seguro.

do $$
begin
  if exists (
    select 1 from public.whatsapp_messages
    where reminder_type <> 'appointment_12h'
  ) then
    raise exception
      'ROLLBACK ABORTADO: existem whatsapp_messages com reminder_type '
      'fora de appointment_12h (confirmation/rescheduled); o CHECK antigo '
      'as rejeitaria. Exporte/trate esses dados antes de repetir.';
  end if;

  if exists (
    select appointment_id, reminder_type
    from public.whatsapp_messages
    group by appointment_id, reminder_type
    having count(*) > 1
  ) then
    raise exception
      'ROLLBACK ABORTADO: existem pares (appointment_id, reminder_type) '
      'duplicados (legitimos sob schedule_revision); a UNIQUE antiga de '
      '2 colunas os rejeitaria. Resolva antes de repetir.';
  end if;

  if exists (
    select 1 from public.appointments where schedule_revision > 0
  ) then
    raise exception
      'ROLLBACK ABORTADO: existe pelo menos 1 appointment com '
      'schedule_revision > 0 — ja houve remarcacao real rastreada. '
      'Apagar a coluna perderia essa informacao de producao. Exporte '
      '(ex.: select id, schedule_revision from appointments where '
      'schedule_revision > 0) antes de repetir.';
  end if;
end $$;

-- ===== whatsapp_messages =====
alter table public.whatsapp_messages
  drop constraint if exists whatsapp_messages_one_per_appointment_revision;

alter table public.whatsapp_messages
  drop constraint if exists whatsapp_messages_schedule_revision_matches_type;

alter table public.whatsapp_messages
  drop constraint if exists whatsapp_messages_schedule_revision_non_negative;

alter table public.whatsapp_messages
  drop column if exists schedule_revision;

do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_reminder_type_valid'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      drop constraint whatsapp_messages_reminder_type_valid;
  end if;

  alter table public.whatsapp_messages
    add constraint whatsapp_messages_reminder_type_valid
    check (reminder_type in ('appointment_12h'));
end $$;

alter table public.whatsapp_messages
  add constraint whatsapp_messages_one_per_appointment_type
  unique (appointment_id, reminder_type);

comment on table public.whatsapp_messages is
  'Metadados de envio de lembretes (sem corpo). Regra: 12h antes, silencio 22:00-06:59 no fuso do profissional (move para 07:00), 1 envio por (appointment_id, reminder_type). Escrita so via service role.';

-- ===== appointments =====
drop trigger if exists appointments_set_schedule_revision on public.appointments;
drop function if exists public.set_appointment_schedule_revision();

alter table public.appointments
  drop constraint if exists appointments_schedule_revision_non_negative;

alter table public.appointments
  drop column if exists schedule_revision;
