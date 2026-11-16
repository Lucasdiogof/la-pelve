-- Migration 0043 -- preferências de mensagens do WhatsApp por profissional.
--   whatsapp_notify_on_booking : aviso de agendamento (appointment_confirmation/rescheduled)
--   whatsapp_reminder_12h      : lembrete de ~12 h (appointment_12h)
-- A materialização só cria o que está ligado. Ao DESLIGAR, mensagens ainda 'scheduled' do
-- tipo são canceladas (status só; cancelled é definitivo pela UNIQUE, então religar não
-- reenvia o passado). Aditiva e idempotente.
alter table public.profiles
  add column if not exists whatsapp_notify_on_booking boolean not null default true,
  add column if not exists whatsapp_reminder_12h boolean not null default true;

create or replace function public.profiles_cancel_disabled_whatsapp_messages()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.whatsapp_notify_on_booking and not new.whatsapp_notify_on_booking then
    update public.whatsapp_messages set status = 'cancelled'
    where fisioterapeuta_id = new.id and status = 'scheduled'
      and reminder_type in ('appointment_confirmation', 'appointment_rescheduled');
  end if;
  if old.whatsapp_reminder_12h and not new.whatsapp_reminder_12h then
    update public.whatsapp_messages set status = 'cancelled'
    where fisioterapeuta_id = new.id and status = 'scheduled'
      and reminder_type = 'appointment_12h';
  end if;
  return new;
end;
$$;
revoke all on function public.profiles_cancel_disabled_whatsapp_messages() from public, anon, authenticated;

drop trigger if exists profiles_cancel_disabled_whatsapp_messages on public.profiles;
create trigger profiles_cancel_disabled_whatsapp_messages
  after update of whatsapp_notify_on_booking, whatsapp_reminder_12h on public.profiles
  for each row execute function public.profiles_cancel_disabled_whatsapp_messages();
