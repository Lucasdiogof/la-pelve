-- Migration 0028 -- trava de segurança das mensagens informativas.
--
-- Contexto: whatsapp_messages já guarda avisos `appointment_confirmation`
-- antigos (status 'scheduled'), materializados quando o tipo ainda não tinha
-- template. Ao configurar o template, o claim os reservaria e enviaria
-- avisos de consultas passadas. Esta migration cria a trava:
--   * enabled_after: só mensagens CRIADAS depois do corte são elegíveis
--     (padrão = instante em que a migration é aplicada);
--   * max_lateness: mensagem informativa atrasada além disso nunca sai.
-- Só o claim muda (mesma assinatura e grants da 0026). `appointment_12h` não
-- é afetado. Nenhuma linha existente é alterada. Idempotente.
-- Rollback: supabase/rollout-0028/02_rollback.sql.

create table if not exists public.whatsapp_informative_gate (
  singleton boolean primary key default true check (singleton),
  enabled_after timestamptz not null default now(),
  max_lateness interval not null default interval '30 minutes'
    check (max_lateness > interval '0' and max_lateness <= interval '6 hours')
);
insert into public.whatsapp_informative_gate (singleton) values (true)
  on conflict do nothing;
alter table public.whatsapp_informative_gate enable row level security;
revoke all on public.whatsapp_informative_gate from public, anon, authenticated;

create or replace function public.claim_whatsapp_messages_for_dispatch(
  p_limit integer,
  p_lease_seconds integer,
  p_reminder_types text[]
)
returns table (message_id uuid, lease_token uuid, reminder_type text)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  if p_limit is null or p_limit not between 1 and 100
     or p_lease_seconds is null or p_lease_seconds not between 30 and 900
     or p_reminder_types is null then
    raise exception using errcode = 'WA004',
      message = 'claim_whatsapp_messages_for_dispatch: parametros invalidos';
  end if;

  -- Lease vencida antes de chamar a Meta: volta para a fila.
  update public.whatsapp_messages m
  set status = 'scheduled',
      lease_token = null,
      lease_expires_at = null
  where m.status = 'processing'
    and m.lease_expires_at < now()
    and m.send_started_at is null;

  -- Lease vencida depois de chamar a Meta: resultado desconhecido. Não
  -- reenvia. Mantém lease_token para um complete atrasado ainda gravar o
  -- wamid se a Meta tiver aceitado.
  update public.whatsapp_messages m
  set status = 'failed',
      failed_at = now(),
      lease_expires_at = null,
      error = jsonb_build_object('code', 'send_outcome_unknown')
  where m.status = 'processing'
    and m.lease_expires_at < now()
    and m.send_started_at is not null;

  return query
  with due as (
    select m.id
    from public.whatsapp_messages m
    where m.status = 'scheduled'
      and m.scheduled_for <= now()
      and (m.next_attempt_at is null or m.next_attempt_at <= now())
      and m.reminder_type = any (p_reminder_types)
      -- Mensagens informativas (aviso de agendamento / remarcação) só valem
      -- logo depois de criadas: nada anterior ao corte de ativação e nada
      -- atrasado além da tolerância. Nunca reenvia backlog antigo.
      and (
        m.reminder_type not in ('appointment_confirmation', 'appointment_rescheduled')
        or exists (
          select 1 from public.whatsapp_informative_gate g
          where m.created_at >= g.enabled_after
            and m.scheduled_for >= now() - g.max_lateness
        )
      )
      and exists (
        select 1 from public.whatsapp_connections c
        where c.fisioterapeuta_id = m.fisioterapeuta_id
          and c.status = 'connected'
          and c.phone_number_id is not null
      )
    order by m.scheduled_for, m.id
    limit p_limit
    for update of m skip locked
  )
  update public.whatsapp_messages m
  set status = 'processing',
      lease_token = gen_random_uuid(),
      lease_expires_at = now() + make_interval(secs => p_lease_seconds),
      send_started_at = null
  from due
  where m.id = due.id
  returning m.id, m.lease_token, m.reminder_type;
end;
$$;

revoke all on function public.claim_whatsapp_messages_for_dispatch(integer, integer, text[])
  from public, anon, authenticated;
grant execute on function public.claim_whatsapp_messages_for_dispatch(integer, integer, text[]) to service_role;
