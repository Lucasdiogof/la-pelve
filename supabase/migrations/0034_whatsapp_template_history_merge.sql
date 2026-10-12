-- 0034: histórico de templates preservado e sem promoção com avaliação velha.
--
-- Bug (auditoria do PR #10): a 0033 guarda eventos de template em
-- whatsapp_connections.setup_state.templates, mas o whatsapp-connect regrava
-- setup_state inteiro em upsert_whatsapp_connection_from_signup (0030) com o
-- que o cliente mandou, apagando o histórico; um webhook atrasado podia então
-- rebaixar de novo a conexão.
--
-- Agora o setup_state tem chaves do SERVIDOR que o cliente nunca sobrescreve:
--   templates               { "<nome>:<idioma>": { event, at } } (0033)
--   templates_verified_at   instante em que uma avaliação COMPLETA, consultando
--                           a Meta, viu os templates aprovados e conectou.
-- e uma chave de entrada que não é gravada:
--   evaluated_at            início da avaliação que o cliente está persistindo.
--
-- upsert_whatsapp_connection_from_signup (mesma assinatura da 0030):
--   - merge no SQL, com a linha travada (FOR UPDATE): templates e
--     templates_verified_at vêm SEMPRE da linha atual, nunca do cliente;
--   - 'connected' é recusado (WA010) se existe evento negativo de template
--     mais novo que o início da avaliação (ou que a última verificação): a
--     avaliação pode ter lido a Meta antes da mudança;
--   - ao conectar, templates_verified_at = evaluated_at.
-- apply_whatsapp_template_status (0033) passa a ignorar eventos com instante
-- <= templates_verified_at: a consulta à Meta naquele instante já reflete
-- tudo o que aconteceu antes, então um REJECTED atrasado não rebaixa.
--
-- Nenhuma linha existente muda ao aplicar. Só service_role executa.

create or replace function public.whatsapp_template_event_blocks(p_event text)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select p_event in ('REJECTED', 'DISABLED', 'DELETED', 'PENDING_DELETION', 'ARCHIVED', 'LOCKED',
                     'PAUSED', 'PENDING', 'IN_APPEAL', 'LIMIT_EXCEEDED');
$$;

create or replace function public.upsert_whatsapp_connection_from_signup(
  p_fisioterapeuta_id uuid,
  p_waba_id text,
  p_phone_number_id text,
  p_display_phone_number text,
  p_status text,
  p_last_error jsonb,
  p_setup_state jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_existing public.whatsapp_connections%rowtype;
  v_id uuid;
  v_client jsonb := coalesce(p_setup_state, '{}'::jsonb);
  v_evaluated_at timestamptz;
  v_templates jsonb;
  v_verified_at timestamptz;
  v_setup jsonb;
  v_found boolean;
begin
  if p_status not in ('pending', 'connected', 'error') then
    raise exception using errcode = 'WA005', message = 'status invalido';
  end if;
  if pg_catalog.jsonb_typeof(v_client) <> 'object' then
    v_client := '{}'::jsonb;
  end if;
  begin
    v_evaluated_at := (v_client->>'evaluated_at')::timestamptz;
  exception when others then
    v_evaluated_at := null;
  end;

  select * into v_existing from public.whatsapp_connections
   where fisioterapeuta_id = p_fisioterapeuta_id for update;
  v_found := found;
  if v_found and v_existing.status = 'connected'
     and v_existing.phone_number_id is distinct from p_phone_number_id then
    raise exception using errcode = 'WA007', message = 'conexao ativa: desconecte antes';
  end if;
  if exists (select 1 from public.whatsapp_connections c
             where c.phone_number_id = p_phone_number_id
               and c.fisioterapeuta_id <> p_fisioterapeuta_id) then
    raise exception using errcode = 'WA008', message = 'numero ja conectado';
  end if;
  -- Conectada = pronta para enviar: exige token já persistido no Vault.
  if p_status = 'connected' and not (
       v_found and exists (select 1 from public.whatsapp_connection_credentials cr
                         where cr.connection_id = v_existing.id)) then
    raise exception using errcode = 'WA009', message = 'conectar exige credencial gravada';
  end if;

  -- Estado do servidor (linha travada): nunca vem do cliente. Histórico de
  -- templates só vale para a MESMA WABA.
  if v_found and v_existing.waba_id is not distinct from p_waba_id then
    v_templates := case when pg_catalog.jsonb_typeof(v_existing.setup_state->'templates') = 'object'
                        then v_existing.setup_state->'templates' end;
    begin
      v_verified_at := (v_existing.setup_state->>'templates_verified_at')::timestamptz;
    exception when others then
      v_verified_at := null;
    end;
  end if;

  if p_status = 'connected' then
    -- Evento negativo mais novo que o que a avaliação pode ter visto.
    if exists (
      select 1
        from pg_catalog.jsonb_each(coalesce(v_templates, '{}'::jsonb)) t(key, value)
       where public.whatsapp_template_event_blocks(t.value->>'event')
         and (t.value->>'at')::timestamptz
             > coalesce(greatest(v_evaluated_at, v_verified_at), '-infinity'::timestamptz)
    ) then
      raise exception using errcode = 'WA010', message = 'template mudou durante a avaliacao';
    end if;
    if v_evaluated_at is not null then
      v_verified_at := greatest(coalesce(v_verified_at, v_evaluated_at), v_evaluated_at);
    end if;
  end if;

  v_setup := (v_client - 'templates' - 'templates_verified_at' - 'evaluated_at')
             || pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
                  'templates', v_templates,
                  'templates_verified_at', v_verified_at));

  if v_found then
    update public.whatsapp_connections
       set waba_id = p_waba_id, phone_number_id = p_phone_number_id,
           display_phone_number = coalesce(p_display_phone_number, v_existing.display_phone_number),
           status = p_status,
           connected_at = case when p_status = 'connected'
                               then coalesce(v_existing.connected_at, now()) else null end,
           disconnected_at = null, last_error = p_last_error,
           setup_state = v_setup
     where id = v_existing.id
    returning id into v_id;
  else
    insert into public.whatsapp_connections
      (fisioterapeuta_id, waba_id, phone_number_id, display_phone_number,
       status, connected_at, last_error, setup_state)
    values (p_fisioterapeuta_id, p_waba_id, p_phone_number_id, p_display_phone_number,
            p_status, null, p_last_error, v_setup)
    returning id into v_id;
  end if;
  return v_id;
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
  v_code := case
    when p_event in ('REJECTED', 'DISABLED', 'DELETED', 'PENDING_DELETION', 'ARCHIVED', 'LOCKED')
      then 'templates_rejected'
    when p_event in ('PAUSED', 'PENDING', 'IN_APPEAL', 'LIMIT_EXCEEDED')
      then 'templates_pending'
    else null -- APPROVED, REINSTATED, UNARCHIVED, FLAGGED: só registra
  end;

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
     -- Evento atrasado em relação ao já registrado para este template.
     and (c.setup_state->'templates'->v_key->>'at' is null
          or (c.setup_state->'templates'->v_key->>'at')::timestamptz <= v_at)
     -- Evento anterior à última consulta completa à Meta: já refletido nela.
     and (c.setup_state->>'templates_verified_at' is null
          or (c.setup_state->>'templates_verified_at')::timestamptz < v_at);
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- Conexões da WABA que estão pendentes SÓ por causa de template: candidatas a
-- reavaliação completa depois de um evento de aprovação. Só leitura.
create or replace function public.list_whatsapp_template_reevaluation_candidates(p_waba_id text)
returns table (
  fisioterapeuta_id uuid,
  phone_number_id text,
  display_phone_number text,
  setup_state jsonb
)
language sql
stable
security definer
set search_path = ''
as $$
  select c.fisioterapeuta_id, c.phone_number_id, c.display_phone_number, c.setup_state
    from public.whatsapp_connections c
   where c.waba_id = p_waba_id
     and c.status = 'pending'
     and c.phone_number_id is not null
     and c.last_error->>'code' in ('templates_pending', 'templates_rejected');
$$;

revoke all on function public.whatsapp_template_event_blocks(text) from public, anon, authenticated;
revoke all on function public.upsert_whatsapp_connection_from_signup(uuid, text, text, text, text, jsonb, jsonb)
  from public, anon, authenticated;
revoke all on function public.apply_whatsapp_template_status(text, text, text, text, timestamptz)
  from public, anon, authenticated;
revoke all on function public.list_whatsapp_template_reevaluation_candidates(text)
  from public, anon, authenticated;
grant execute on function public.whatsapp_template_event_blocks(text) to service_role;
grant execute on function public.upsert_whatsapp_connection_from_signup(uuid, text, text, text, text, jsonb, jsonb)
  to service_role;
grant execute on function public.apply_whatsapp_template_status(text, text, text, text, timestamptz)
  to service_role;
grant execute on function public.list_whatsapp_template_reevaluation_candidates(text) to service_role;
