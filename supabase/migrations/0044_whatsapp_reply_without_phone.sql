-- Resposta de paciente sem telefone (WhatsApp BSUID / nome de usuário).
--
-- Quando a Meta deixa de enviar o telefone em messages[].from, o webhook passa
-- p_from_e164_candidates = null. A correlação continua EXATA: só vale se a
-- resposta cita (context.id) uma mensagem NOSSA appointment_12h já enviada,
-- do dono do phone_number_id que recebeu, com todas as demais travas da 0025
-- (consentimento, revisão do horário, janela de tempo, status). Sem citação e
-- sem telefone: parâmetros inválidos (WA002), nada é gravado.
-- Compatível: mesma assinatura; chamadas com telefone se comportam como antes.
-- Aditiva e idempotente (create or replace). Rollback: reaplicar a 0025.

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
     -- Telefone opcional (BSUID): sem ele, a citação (context.id) é obrigatória.
     or (p_from_e164_candidates is null
         and nullif(btrim(coalesce(p_context_wamid, '')), '') is null)
     or (p_from_e164_candidates is not null and (
       cardinality(p_from_e164_candidates) not between 1 and 2
       or exists (
         select 1 from unnest(p_from_e164_candidates) as c(v)
         where v is null or v !~ '^\+[1-9][0-9]{7,14}$'
       )))
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
      and (p_from_e164_candidates is null
           or m.destination_phone_e164 = any (p_from_e164_candidates));
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
