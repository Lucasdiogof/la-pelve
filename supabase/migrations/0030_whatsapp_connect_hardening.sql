-- Migration 0030 -- endurece o onboarding do WhatsApp (revisão do PR #6).
--
--  * whatsapp_connections.setup_state: progresso do onboarding (modo
--    cloud/coexistência, tentativas de registro do número). Sem segredos; a
--    profissional só lê a própria linha (RLS já existente).
--  * upsert_whatsapp_connection_from_signup: ganha p_setup_state e NUNCA marca
--    'connected' sem credencial gravada no Vault (WA009).
--  * count_other_whatsapp_connections_on_waba: a inscrição do webhook é por
--    WABA; só quem é o último usuário da WABA pode removê-la.
--  * apply_whatsapp_account_event: aplica eventos `account_update` da Meta
--    (revogação, desativação, restrição) de forma idempotente.
-- Idempotente. Rollback: rollout-0030/02_rollback.sql.

alter table public.whatsapp_connections
  add column if not exists setup_state jsonb not null default '{}'::jsonb;

-- A assinatura antiga (6 parâmetros, da 0029) é substituída.
drop function if exists public.upsert_whatsapp_connection_from_signup(uuid, text, text, text, text, jsonb);

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
begin
  if p_status not in ('pending', 'connected', 'error') then
    raise exception using errcode = 'WA005', message = 'status invalido';
  end if;
  select * into v_existing from public.whatsapp_connections
   where fisioterapeuta_id = p_fisioterapeuta_id for update;
  if found and v_existing.status = 'connected'
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
       found and exists (select 1 from public.whatsapp_connection_credentials cr
                         where cr.connection_id = v_existing.id)) then
    raise exception using errcode = 'WA009', message = 'conectar exige credencial gravada';
  end if;
  if found then
    update public.whatsapp_connections
       set waba_id = p_waba_id, phone_number_id = p_phone_number_id,
           display_phone_number = coalesce(p_display_phone_number, v_existing.display_phone_number),
           status = p_status,
           connected_at = case when p_status = 'connected'
                               then coalesce(v_existing.connected_at, now()) else null end,
           disconnected_at = null, last_error = p_last_error,
           setup_state = coalesce(p_setup_state, '{}'::jsonb)
     where id = v_existing.id
    returning id into v_id;
  else
    insert into public.whatsapp_connections
      (fisioterapeuta_id, waba_id, phone_number_id, display_phone_number,
       status, connected_at, last_error, setup_state)
    values (p_fisioterapeuta_id, p_waba_id, p_phone_number_id, p_display_phone_number,
            p_status, null, p_last_error, coalesce(p_setup_state, '{}'::jsonb))
    returning id into v_id;
  end if;
  return v_id;
end;
$$;

-- Quantas OUTRAS profissionais ainda dependem da inscrição de webhook desta
-- WABA (conexão pendente ou conectada).
create or replace function public.count_other_whatsapp_connections_on_waba(
  p_fisioterapeuta_id uuid,
  p_waba_id text
)
returns integer
language sql
security definer
set search_path = ''
stable
as $$
  select count(*)::integer
  from public.whatsapp_connections c
  where c.waba_id = p_waba_id
    and c.fisioterapeuta_id <> p_fisioterapeuta_id
    and c.status in ('pending', 'connected');
$$;

-- Eventos account_update da Meta, por WABA. Devolve quantas conexões mudaram.
--   revogação (PARTNER_REMOVED, PARTNER_APP_UNINSTALLED, ACCOUNT_DELETED,
--   ACCOUNT_OFFBOARDED): apaga a credencial (e o segredo no Vault) e marca
--   'disconnected';
--   DISABLED_UPDATE (DISABLE), ACCOUNT_VIOLATION, ACCOUNT_RESTRICTION: 'error'
--   (o envio para, a credencial fica);
--   DISABLED_UPDATE (REINSTATE), ACCOUNT_RECONNECTED: volta a 'pending' para o
--   servidor reavaliar tudo antes de liberar o envio.
-- Idempotente: repetir o mesmo evento não muda nada além da primeira vez.
create or replace function public.apply_whatsapp_account_event(
  p_waba_id text,
  p_event text,
  p_detail text
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer := 0;
begin
  if p_waba_id is null or p_waba_id !~ '^[0-9]{5,32}$' then
    return 0;
  end if;

  if p_event in ('PARTNER_REMOVED', 'PARTNER_APP_UNINSTALLED', 'ACCOUNT_DELETED', 'ACCOUNT_OFFBOARDED') then
    delete from public.whatsapp_connection_credentials cr
     using public.whatsapp_connections c
     where cr.connection_id = c.id and c.waba_id = p_waba_id;
    update public.whatsapp_connections
       set status = 'disconnected',
           disconnected_at = coalesce(disconnected_at, now()),
           connected_at = null,
           last_error = jsonb_build_object('code', 'revoked_by_meta', 'event', p_event)
     where waba_id = p_waba_id and status <> 'disconnected';
    get diagnostics v_count = row_count;

  elsif (p_event = 'DISABLED_UPDATE' and p_detail = 'DISABLE')
     or p_event in ('ACCOUNT_VIOLATION', 'ACCOUNT_RESTRICTION') then
    update public.whatsapp_connections
       set status = 'error', connected_at = null,
           last_error = jsonb_build_object(
             'code', case when p_event = 'ACCOUNT_RESTRICTION' then 'account_restricted'
                          else 'account_disabled' end,
             'event', p_event)
     where waba_id = p_waba_id and status in ('pending', 'connected');
    get diagnostics v_count = row_count;

  elsif (p_event = 'DISABLED_UPDATE' and p_detail = 'REINSTATE') or p_event = 'ACCOUNT_RECONNECTED' then
    update public.whatsapp_connections
       set status = 'pending', connected_at = null,
           last_error = jsonb_build_object('code', 'account_reinstated_review')
     where waba_id = p_waba_id and status = 'error';
    get diagnostics v_count = row_count;
  end if;

  return v_count;
end;
$$;

revoke all on function public.upsert_whatsapp_connection_from_signup(uuid, text, text, text, text, jsonb, jsonb) from public, anon, authenticated;
revoke all on function public.count_other_whatsapp_connections_on_waba(uuid, text) from public, anon, authenticated;
revoke all on function public.apply_whatsapp_account_event(text, text, text) from public, anon, authenticated;
grant execute on function public.upsert_whatsapp_connection_from_signup(uuid, text, text, text, text, jsonb, jsonb) to service_role;
grant execute on function public.count_other_whatsapp_connections_on_waba(uuid, text) to service_role;
grant execute on function public.apply_whatsapp_account_event(text, text, text) to service_role;
