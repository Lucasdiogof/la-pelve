-- 0033: webhooks de status de entrega e de status de templates do WhatsApp.
--
-- 1. apply_whatsapp_message_status: aplica sent/delivered/read/failed vindos
--    do webhook (statuses[]) à mensagem com aquele wamid, numa transação com
--    a linha travada.
--    - Identidade: o wamid só vale se a conexão da profissional dona da
--      mensagem usa o phone_number_id do webhook (metadata).
--    - Monotônico: sent < delivered < read. Evento atrasado/duplicado nunca
--      rebaixa (ex.: 'sent' depois de 'read' é ignorado).
--    - failed: só a partir de sent/delivered; nunca depois de read. Não volta
--      para a fila: o despacho só reserva 'scheduled', então failed NUNCA
--      autoriza reenvio. delivered/read posteriores provam a entrega e vencem
--      um failed de entrega.
--    - Mensagem que ainda não saiu (scheduled/processing/cancelled) ou outro
--      failed (ex.: send_outcome_unknown) não é tocada.
--    - Erro gravado só com códigos numéricos (sem texto da Meta).
-- 2. apply_whatsapp_template_status: registra o evento de status de template
--    (message_template_status_update) nas conexões da WABA e, se o template
--    deixou de estar utilizável, tira a conexão de 'connected' (volta para
--    'pending' com o motivo). NUNCA promove: aprovação só vira 'connected'
--    pela reavaliação completa (whatsapp-connect status), que consulta a Meta.
--
-- Aditiva: nenhuma linha existente muda ao aplicar. Só service_role executa.

create or replace function public.apply_whatsapp_message_status(
  p_phone_number_id text,
  p_wamid text,
  p_status text,
  p_occurred_at timestamptz,
  p_error_code integer default null
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_msg public.whatsapp_messages%rowtype;
  v_rank integer;
  v_current integer;
  v_at timestamptz := coalesce(p_occurred_at, pg_catalog.now());
begin
  if p_phone_number_id is null or p_phone_number_id !~ '^[0-9]{5,32}$'
     or p_wamid is null or pg_catalog.btrim(p_wamid) = '' or pg_catalog.length(p_wamid) > 256
     or p_status is null or p_status not in ('sent', 'delivered', 'read', 'failed') then
    return 'invalid';
  end if;

  select m.* into v_msg
    from public.whatsapp_messages m
    join public.whatsapp_connections c on c.fisioterapeuta_id = m.fisioterapeuta_id
   where m.wamid = pg_catalog.btrim(p_wamid)
     and c.phone_number_id = p_phone_number_id
   for update of m;
  if not found then
    return 'not_found';
  end if;

  v_current := case v_msg.status
    when 'sent' then 1 when 'delivered' then 2 when 'read' then 3 else null end;

  if p_status = 'failed' then
    if v_msg.status not in ('sent', 'delivered') then
      return 'unchanged';
    end if;
    update public.whatsapp_messages
       set status = 'failed',
           failed_at = v_at,
           error = pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
             'code', 'delivery_failed',
             'provider_code', p_error_code))
     where id = v_msg.id;
    return 'updated';
  end if;

  v_rank := case p_status when 'sent' then 1 when 'delivered' then 2 else 3 end;

  -- Entrega comprovada vence um failed de entrega (eventos fora de ordem).
  if v_msg.status = 'failed' and v_msg.error->>'code' = 'delivery_failed' and v_rank >= 2 then
    v_current := 0;
  end if;

  if v_current is null or v_rank <= v_current then
    return 'unchanged';
  end if;

  update public.whatsapp_messages
     set status = p_status,
         delivered_at = case when v_rank >= 2 then coalesce(delivered_at, v_at) else delivered_at end,
         read_at = case when v_rank = 3 then coalesce(read_at, v_at) else read_at end,
         failed_at = case when v_msg.status = 'failed' then null else failed_at end,
         error = case when v_msg.status = 'failed' then null else error end
   where id = v_msg.id;
  return 'updated';
end;
$$;

create or replace function public.apply_whatsapp_template_status(
  p_waba_id text,
  p_template_name text,
  p_language text,
  p_event text,
  p_occurred_at timestamptz
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_key text;
  v_at timestamptz := coalesce(p_occurred_at, pg_catalog.now());
  v_code text;
  v_count integer := 0;
begin
  if p_waba_id is null or p_waba_id !~ '^[0-9]{5,32}$'
     or p_template_name is null or p_template_name !~ '^[a-z0-9_]+$' or pg_catalog.length(p_template_name) > 512
     or p_language is null or p_language !~ '^[a-z]{2,3}(_[A-Z]{2})?$'
     or p_event is null or p_event !~ '^[A-Z_]{3,32}$' then
    return 0;
  end if;

  v_key := p_template_name || ':' || p_language;
  -- Template deixou de ser utilizável: a conexão não pode ficar 'connected'.
  v_code := case
    when p_event in ('REJECTED', 'DISABLED', 'DELETED', 'PENDING_DELETION', 'ARCHIVED', 'LOCKED')
      then 'templates_rejected'
    when p_event in ('PAUSED', 'PENDING', 'IN_APPEAL', 'LIMIT_EXCEEDED')
      then 'templates_pending'
    else null -- APPROVED, REINSTATED, UNARCHIVED, FLAGGED: só registra
  end;

  -- Registro (sem segredos) em setup_state.templates; evento mais antigo que
  -- o já registrado é ignorado (reentrega fora de ordem).
  update public.whatsapp_connections c
     set setup_state = pg_catalog.jsonb_set(
           case when pg_catalog.jsonb_typeof(c.setup_state->'templates') = 'object'
                then c.setup_state else c.setup_state || '{"templates": {}}'::jsonb end,
           array['templates', v_key],
           pg_catalog.jsonb_build_object('event', p_event, 'at', v_at),
           true),
         status = case when v_code is not null and c.status = 'connected' then 'pending' else c.status end,
         connected_at = case when v_code is not null and c.status = 'connected' then null else c.connected_at end,
         last_error = case when v_code is not null and c.status = 'connected'
                           then pg_catalog.jsonb_build_object('code', v_code, 'event', p_event)
                           else c.last_error end
   where c.waba_id = p_waba_id
     and c.status in ('pending', 'connected', 'error')
     and (c.setup_state->'templates'->v_key->>'at' is null
          or (c.setup_state->'templates'->v_key->>'at')::timestamptz <= v_at);
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.apply_whatsapp_message_status(text, text, text, timestamptz, integer)
  from public, anon, authenticated;
revoke all on function public.apply_whatsapp_template_status(text, text, text, text, timestamptz)
  from public, anon, authenticated;
grant execute on function public.apply_whatsapp_message_status(text, text, text, timestamptz, integer)
  to service_role;
grant execute on function public.apply_whatsapp_template_status(text, text, text, text, timestamptz)
  to service_role;
