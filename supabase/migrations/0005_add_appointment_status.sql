-- Run this in the Supabase dashboard: SQL Editor > New query.
--
-- Status do agendamento: agendado, confirmado, atendido, cancelado,
-- faltou, reagendado (lib/features/agenda/domain/entities/appointment_status.dart).

alter table public.appointments
add column status text not null default 'agendado';
