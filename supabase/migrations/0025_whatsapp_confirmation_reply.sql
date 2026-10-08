-- Run this in the Supabase dashboard: SQL Editor > New query
-- (or: npx supabase db query -f <this file> --linked).
--
-- Confirmação de consulta pela resposta da paciente no WhatsApp.
--
-- Fluxo: o lembrete appointment_12h (whatsapp_messages, já existente) é a
-- SOLICITAÇÃO DE CONFIRMAÇÃO. A paciente responde ("Sim, confirmo!" ou o
-- botão de resposta rápida do template); o whatsapp-webhook valida a
-- assinatura, classifica a resposta e, só para respostas de confirmação
-- inequívocas, chama public.process_whatsapp_confirmation_reply (abaixo),
-- que decide e aplica TUDO numa única transação.
--
-- O que esta migration cria:
--   1. whatsapp_inbound_messages: uma linha por mensagem recebida que o
--      webhook tentou processar como confirmação. Chave de idempotência =
--      id da mensagem na Meta (wamid). NÃO guarda o texto da mensagem nem o
--      telefone do remetente -- só ids técnicos, tipo, horário e o resultado.
--   2. whatsapp_messages.confirmation_reply_id / confirmation_consumed_at:
--      marcam que aquela solicitação de confirmação já foi respondida.
--   3. public.process_whatsapp_confirmation_reply(...): correlação +
--      mudança de status, idempotente, executável só pelo service_role.
--
-- Regra de correlação (nunca "o próximo agendamento daquele telefone"):
--   resposta recebida no número do profissional (phone_number_id ->
--   whatsapp_connections) + remetente == destination_phone_e164 da
--   solicitação + solicitação appointment_12h efetivamente enviada
--   (sent/delivered/read) + consentimento daquela solicitação ainda ativo +
--   revisão de horário da solicitação == revisão atual da consulta +
--   paciente da consulta == paciente da solicitação + resposta depois do
--   envio e antes do início da consulta (e a consulta ainda não começou).
--   Se a resposta cita a mensagem (context.id da Meta, sempre presente no
--   botão de resposta rápida), só aquela solicitação é considerada. Sem
--   citação, confirma apenas se existir EXATAMENTE UMA solicitação válida
--   para aquele remetente naquele número; duas ou mais = ambígua, nada muda.
--
-- Status: só 'scheduled' -> 'confirmed'. 'confirmed' = já confirmado (sem
-- UPDATE). cancelled/fulfilled/noShow/rescheduled ou qualquer outro valor:
-- nada muda.
--
-- Idempotente: pode rodar de novo sem efeito colateral. Puramente aditiva:
-- nenhuma linha existente é alterada (colunas novas nascem nulas).
-- Rollback: supabase/rollout-0025/02_rollback.sql.

-- ---------------------------------------------------------------------
-- 1. whatsapp_inbound_messages
-- ---------------------------------------------------------------------
create table if not exists public.whatsapp_inbound_messages (
  id uuid primary key default gen_random_uuid(),
  -- id da mensagem recebida na Meta (messages[].id). Deduplica reentregas
  -- do mesmo webhook.
  wamid text not null unique,
  -- Número do profissional que recebeu (metadata.phone_number_id).
  phone_number_id text not null,
  -- Dono, quando o phone_number_id pertence a uma conexão conhecida.
  fisioterapeuta_id uuid references auth.users (id) on delete cascade,
  message_type text not null,
  -- messages[].context.id: a mensagem nossa que a paciente citou/respondeu.
  context_wamid text,
  -- messages[].timestamp da Meta.
  received_at timestamptz not null,
  outcome text not null,
  -- Solicitação de confirmação correlacionada (quando houve uma).
  whatsapp_message_id uuid references public.whatsapp_messages (id)
    on delete set null,
  processed_at timestamptz not null default now(),
  constraint whatsapp_inbound_messages_type_valid
    check (message_type in ('text', 'button', 'interactive')),
  constraint whatsapp_inbound_messages_outcome_valid
    check (outcome in (
      'confirmed',
      'already_confirmed',
      'no_pending_request',
      'ambiguous',
      'request_expired',
      'request_stale',
      'consent_revoked',
      'appointment_status_incompatible'
    ))
);

create index if not exists whatsapp_inbound_messages_fisioterapeuta_id_idx
  on public.whatsapp_inbound_messages (fisioterapeuta_id);
create index if not exists whatsapp_inbound_messages_whatsapp_message_id_idx
  on public.whatsapp_inbound_messages (whatsapp_message_id);

-- Só backend: nenhum acesso para anon/authenticated (nem leitura).
alter table public.whatsapp_inbound_messages enable row level security;
revoke all on public.whatsapp_inbound_messages from anon, authenticated;

comment on table public.whatsapp_inbound_messages is
  'Respostas recebidas pelo WhatsApp processadas como possivel confirmacao '
  'de consulta. Sem corpo da mensagem e sem telefone. wamid UNIQUE = '
  'idempotencia contra reentrega do webhook. Escrita so via '
  'process_whatsapp_confirmation_reply (service_role).';

-- ---------------------------------------------------------------------
-- 2. whatsapp_messages: solicitação de confirmação respondida
-- ---------------------------------------------------------------------
alter table public.whatsapp_messages
  add column if not exists confirmation_reply_id uuid
    references public.whatsapp_inbound_messages (id) on delete set null,
  add column if not exists confirmation_consumed_at timestamptz;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_confirmation_only_on_request'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_confirmation_only_on_request
      check (
        confirmation_consumed_at is null
        or reminder_type = 'appointment_12h'
      );
  end if;
end $$;

-- Lookup do webhook: resposta que cita a nossa mensagem (context.id).
-- (wamid já é UNIQUE desde a 0018, então já tem índice.)
-- Lookup sem citação: solicitações enviadas para um destino.
create index if not exists whatsapp_messages_confirmation_lookup_idx
  on public.whatsapp_messages (destination_phone_e164, fisioterapeuta_id)
  where reminder_type = 'appointment_12h'
    and status in ('sent', 'delivered', 'read');

comment on column public.whatsapp_messages.confirmation_consumed_at is
  'Quando esta solicitacao de confirmacao (appointment_12h) foi respondida '
  'com confirmacao valida. Preenchido so por '
  'process_whatsapp_confirmation_reply; nunca volta a nulo.';

-- ---------------------------------------------------------------------
-- 3. process_whatsapp_confirmation_reply
-- ---------------------------------------------------------------------
-- Chamada pelo whatsapp-webhook SOMENTE para respostas já classificadas
-- como confirmação inequívoca. Tudo numa transação:
--   a) registra a mensagem recebida (wamid UNIQUE); se já existia, devolve
--      'duplicate' com o resultado anterior e não faz mais nada;
--   b) correlaciona com UMA solicitação de confirmação (ver cabeçalho);
--   c) trava consulta e solicitação (FOR UPDATE) e revalida;
--   d) scheduled -> confirmed; confirmed -> já confirmado; outro -> nada;
--   e) marca a solicitação como respondida e grava o resultado.
--
-- p_from_e164_candidates: o remetente em E.164. Pode ter 2 formas para
-- celular brasileiro (com e sem o 9 depois do DDD), porque o WhatsApp ainda
-- identifica contas antigas sem o 9. Ambas representam o MESMO número.
create or replace function public.process_whatsapp_confirmation_reply(
  p_wamid text,
  p_phone_number_id text,
  p_from_e164_candidates text[],
  p_received_at timestamptz,
  p_message_type text,
  p_context_wamid text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_inbound_id uuid;
  v_previous_outcome text;
  v_fisioterapeuta_id uuid;
  v_request_id uuid;
  v_candidates uuid[];
  v_outcome text;
  v_msg public.whatsapp_messages%rowtype;
  v_appt public.appointments%rowtype;
  v_tz text;
  v_start timestamptz;
  v_consent_revoked_at timestamptz;
  v_patient_deleted_at timestamptz;
begin
  if p_wamid is null or btrim(p_wamid) = ''
     or p_phone_number_id is null or btrim(p_phone_number_id) = ''
     or p_received_at is null
     or p_message_type is null
     or p_message_type not in ('text', 'button', 'interactive')
     or p_from_e164_candidates is null
     or cardinality(p_from_e164_candidates) not between 1 and 2
     or exists (
       select 1 from unnest(p_from_e164_candidates) as c(v)
       where v is null or v !~ '^\+[1-9][0-9]{7,14}$'
     )
  then
    raise exception using
      errcode = 'WA002',
      message = 'process_whatsapp_confirmation_reply: parametros invalidos';
  end if;

  select c.fisioterapeuta_id into v_fisioterapeuta_id
  from public.whatsapp_connections c
  where c.phone_number_id = p_phone_number_id;

  -- a) Idempotência: a mesma mensagem da Meta só é processada uma vez.
  insert into public.whatsapp_inbound_messages (
    wamid, phone_number_id, fisioterapeuta_id, message_type,
    context_wamid, received_at, outcome
  ) values (
    p_wamid, p_phone_number_id, v_fisioterapeuta_id, p_message_type,
    nullif(btrim(p_context_wamid), ''), p_received_at, 'no_pending_request'
  )
  on conflict (wamid) do nothing
  returning id into v_inbound_id;

  if v_inbound_id is null then
    select outcome into v_previous_outcome
    from public.whatsapp_inbound_messages where wamid = p_wamid;
    return jsonb_build_object(
      'outcome', 'duplicate',
      'previous_outcome', v_previous_outcome
    );
  end if;

  if v_fisioterapeuta_id is null then
    -- Número que não pertence a nenhum profissional: nada a correlacionar.
    return jsonb_build_object('outcome', 'no_pending_request');
  end if;

  -- b) Correlação.
  if nullif(btrim(p_context_wamid), '') is not null then
    -- A paciente citou uma mensagem: só ela conta (sem cair para busca
    -- por telefone se não for uma solicitação válida).
    select m.id into v_request_id
    from public.whatsapp_messages m
    where m.wamid = btrim(p_context_wamid)
      and m.fisioterapeuta_id = v_fisioterapeuta_id
      and m.reminder_type = 'appointment_12h'
      and m.status in ('sent', 'delivered', 'read')
      and m.destination_phone_e164 = any (p_from_e164_candidates);
  else
    -- Sem citação: todas as solicitações VÁLIDAS para este remetente neste
    -- número. Uma só = é ela; nenhuma ou mais de uma = não confirma.
    select array_agg(m.id order by m.id) into v_candidates
    from public.whatsapp_messages m
    join public.appointments a
      on a.id = m.appointment_id
     and a.fisioterapeuta_id = m.fisioterapeuta_id
    join public.profiles pr on pr.id = m.fisioterapeuta_id
    join public.patient_consents pc on pc.id = m.consent_id
    join public.patients p
      on p.id = m.patient_id
     and p.fisioterapeuta_id = m.fisioterapeuta_id
    where m.fisioterapeuta_id = v_fisioterapeuta_id
      and m.reminder_type = 'appointment_12h'
      and m.status in ('sent', 'delivered', 'read')
      and m.destination_phone_e164 = any (p_from_e164_candidates)
      and m.sent_at is not null
      and p_received_at >= m.sent_at - interval '1 minute'
      and pc.revoked_at is null
      and p.deleted_at is null
      and a.patient_id is not distinct from m.patient_id
      and a.schedule_revision = m.schedule_revision
      and p_received_at < ((a.date + a.time) at time zone pr.timezone)
      and now() < ((a.date + a.time) at time zone pr.timezone);

    if cardinality(v_candidates) = 1 then
      v_request_id := v_candidates[1];
    elsif cardinality(v_candidates) > 1 then
      update public.whatsapp_inbound_messages
      set outcome = 'ambiguous' where id = v_inbound_id;
      return jsonb_build_object('outcome', 'ambiguous');
    end if;
  end if;

  if v_request_id is null then
    return jsonb_build_object('outcome', 'no_pending_request');
  end if;

  -- c) Trava a consulta e depois a solicitação (sempre nesta ordem) e
  --    revalida tudo com os valores travados.
  select m.* into v_msg from public.whatsapp_messages m where m.id = v_request_id;

  select a.* into v_appt
  from public.appointments a
  where a.id = v_msg.appointment_id
    and a.fisioterapeuta_id = v_msg.fisioterapeuta_id
  for update;

  select m.* into v_msg
  from public.whatsapp_messages m where m.id = v_request_id
  for update;

  select pr.timezone into v_tz from public.profiles pr where pr.id = v_msg.fisioterapeuta_id;
  select pc.revoked_at into v_consent_revoked_at
  from public.patient_consents pc where pc.id = v_msg.consent_id;
  select p.deleted_at into v_patient_deleted_at
  from public.patients p
  where p.id = v_msg.patient_id and p.fisioterapeuta_id = v_msg.fisioterapeuta_id;

  v_start := (v_appt.date + v_appt.time) at time zone coalesce(v_tz, 'America/Sao_Paulo');

  if v_appt.id is null or v_tz is null then
    v_outcome := 'no_pending_request';
  elsif v_consent_revoked_at is not null or v_patient_deleted_at is not null then
    v_outcome := 'consent_revoked';
  elsif v_appt.schedule_revision <> v_msg.schedule_revision
     or v_appt.patient_id is distinct from v_msg.patient_id then
    v_outcome := 'request_stale';
  elsif v_msg.sent_at is null
     or p_received_at < v_msg.sent_at - interval '1 minute'
     or p_received_at >= v_start
     or now() >= v_start then
    v_outcome := 'request_expired';
  elsif v_appt.status = 'confirmed' then
    v_outcome := 'already_confirmed';
  elsif v_appt.status = 'scheduled' then
    -- d) Única escrita em appointments: só status, só scheduled -> confirmed.
    update public.appointments
    set status = 'confirmed'
    where id = v_appt.id
      and fisioterapeuta_id = v_appt.fisioterapeuta_id
      and status = 'scheduled';
    v_outcome := 'confirmed';
  else
    v_outcome := 'appointment_status_incompatible';
  end if;

  -- e) Solicitação respondida (só na primeira resposta que confirma).
  if v_outcome in ('confirmed', 'already_confirmed')
     and v_msg.confirmation_consumed_at is null then
    update public.whatsapp_messages
    set confirmation_consumed_at = now(),
        confirmation_reply_id = v_inbound_id
    where id = v_msg.id;
  end if;

  update public.whatsapp_inbound_messages
  set outcome = v_outcome,
      whatsapp_message_id = v_msg.id
  where id = v_inbound_id;

  return jsonb_build_object(
    'outcome', v_outcome,
    'appointment_id', case when v_outcome in ('confirmed', 'already_confirmed')
                           then v_appt.id end
  );
end;
$$;

revoke all on function public.process_whatsapp_confirmation_reply(
  text, text, text[], timestamptz, text, text
) from public, anon, authenticated;
grant execute on function public.process_whatsapp_confirmation_reply(
  text, text, text[], timestamptz, text, text
) to service_role;

comment on function public.process_whatsapp_confirmation_reply(
  text, text, text[], timestamptz, text, text
) is
  'Confirma (scheduled -> confirmed) a consulta ligada a UMA solicitacao '
  'appointment_12h enviada, a partir de uma resposta de confirmacao ja '
  'classificada pelo webhook. Idempotente por wamid. Ver migration 0025.';

-- ---------------------------------------------------------------------
-- Check (read-only):
--   01_check  1 linha: whatsapp_inbound_messages com RLS ligada
--   02_check  2 linhas: colunas novas em whatsapp_messages
--   03_check  1 linha: função security definer, sem EXECUTE para anon/authenticated
-- ---------------------------------------------------------------------
select '01_check' as secao, c.relname as tabela, c.relrowsecurity as rls
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname = 'whatsapp_inbound_messages';

select '02_check' as secao, column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'whatsapp_messages'
  and column_name in ('confirmation_reply_id', 'confirmation_consumed_at')
order by column_name;

select '03_check' as secao, p.proname, p.prosecdef as security_definer,
  has_function_privilege('anon', p.oid, 'execute') as anon_exec,
  has_function_privilege('authenticated', p.oid, 'execute') as authenticated_exec
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'process_whatsapp_confirmation_reply';
