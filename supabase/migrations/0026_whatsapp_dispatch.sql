-- Run this in the Supabase dashboard: SQL Editor > New query
-- (or: npx supabase db query -f <this file> --linked).
--
-- Envio real (dispatch) das mensagens de whatsapp_messages pela WhatsApp
-- Cloud API, por profissional.
--
-- O que esta migration cria:
--   1. Credencial da Meta por conexão, guardada no Supabase Vault:
--      whatsapp_connection_credentials (connection_id -> vault_secret_id).
--      O token NUNCA fica em coluna comum, nunca chega ao app e só é lido
--      dentro de prepare_whatsapp_message_send, para a mensagem que o worker
--      tem reservada.
--   2. Colunas de controle de envio em whatsapp_messages (lease, tentativas,
--      próxima tentativa, início do envio).
--   3. RPCs do dispatcher (só service_role):
--        set_whatsapp_connection_access_token  grava/rotaciona o token (só escrita)
--        claim_whatsapp_messages_for_dispatch  reserva mensagens devidas (SKIP LOCKED + lease)
--        prepare_whatsapp_message_send         revalida tudo e devolve o necessário para 1 envio
--        complete_whatsapp_message_send        grava o resultado (sent / retry / failed)
--
-- Máquina de estados (status já existentes desde a 0018; nenhum novo):
--   scheduled --claim--> processing --prepare ok--> (HTTP) --complete--> sent
--                                                            \--> scheduled (retry, next_attempt_at)
--                                                            \--> failed
--   processing --prepare: inválida para sempre--> cancelled
--   processing --prepare: bloqueio temporário--> scheduled (next_attempt_at)
--   processing com lease vencida:
--     send_started_at nulo  -> scheduled (nunca chegou a chamar a Meta: seguro reenviar)
--     send_started_at feito -> failed 'send_outcome_unknown' (pode ter sido enviada:
--                              NÃO reenvia, para nunca mandar duas vezes)
--
-- Nenhuma transação fica aberta durante a chamada HTTP: claim, prepare e
-- complete são transações curtas e separadas.
--
-- Pré-requisito: extensão supabase_vault instalada (padrão nos projetos
-- Supabase). Sem ela a migration ABORTA. Idempotente. Aditiva: nenhuma linha
-- existente é alterada (colunas novas com default/nulas).
-- Rollback: supabase/rollout-0026/02_rollback.sql.

do $$
begin
  if not exists (select 1 from pg_extension where extname = 'supabase_vault') then
    raise exception
      'MIGRATION 0026 ABORTADA: extensao supabase_vault nao instalada. As '
      'credenciais da Meta dependem do Vault; nao aplicar sem ele.';
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 1. Credencial por conexão (Vault)
-- ---------------------------------------------------------------------
create table if not exists public.whatsapp_connection_credentials (
  connection_id uuid primary key
    references public.whatsapp_connections (id) on delete cascade,
  -- vault.secrets.id do access token da Meta desta conexão.
  vault_secret_id uuid not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists whatsapp_connection_credentials_touch_updated_at
  on public.whatsapp_connection_credentials;
create trigger whatsapp_connection_credentials_touch_updated_at
  before update on public.whatsapp_connection_credentials
  for each row execute function public.touch_updated_at();

-- Apagar a credencial (inclusive em cascata, ao apagar a conexão ou a conta)
-- apaga o segredo do Vault: nenhum token órfão.
create or replace function public.whatsapp_connection_credentials_delete_secret()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from vault.secrets where id = old.vault_secret_id;
  return old;
end;
$$;

revoke all on function public.whatsapp_connection_credentials_delete_secret()
  from public, anon, authenticated;

drop trigger if exists whatsapp_connection_credentials_delete_secret
  on public.whatsapp_connection_credentials;
create trigger whatsapp_connection_credentials_delete_secret
  after delete on public.whatsapp_connection_credentials
  for each row execute function public.whatsapp_connection_credentials_delete_secret();

alter table public.whatsapp_connection_credentials enable row level security;
revoke all on public.whatsapp_connection_credentials from anon, authenticated;

comment on table public.whatsapp_connection_credentials is
  'Referencia ao access token da Meta de cada whatsapp_connection, guardado '
  'no Supabase Vault. Sem token aqui. Sem acesso do app; escrita so via '
  'set_whatsapp_connection_access_token e leitura so dentro de '
  'prepare_whatsapp_message_send (service_role).';

-- Grava ou rotaciona o token. Só escrita: nunca devolve o token.
create or replace function public.set_whatsapp_connection_access_token(
  p_connection_id uuid,
  p_access_token text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_secret_id uuid;
begin
  if p_access_token is null
     or length(p_access_token) not between 16 and 4096
     or p_access_token ~ '\s' then
    raise exception using errcode = 'WA003',
      message = 'set_whatsapp_connection_access_token: token invalido';
  end if;
  if not exists (select 1 from public.whatsapp_connections where id = p_connection_id) then
    raise exception using errcode = 'WA003',
      message = 'set_whatsapp_connection_access_token: conexao inexistente';
  end if;

  select vault_secret_id into v_secret_id
  from public.whatsapp_connection_credentials
  where connection_id = p_connection_id
  for update;

  if v_secret_id is null then
    v_secret_id := vault.create_secret(
      p_access_token,
      'whatsapp_connection_' || p_connection_id::text,
      'Meta access token da whatsapp_connection ' || p_connection_id::text
    );
    insert into public.whatsapp_connection_credentials (connection_id, vault_secret_id)
    values (p_connection_id, v_secret_id);
  else
    perform vault.update_secret(v_secret_id, p_access_token);
    update public.whatsapp_connection_credentials
    set updated_at = now()
    where connection_id = p_connection_id;
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- 2. whatsapp_messages: controle de envio
-- ---------------------------------------------------------------------
alter table public.whatsapp_messages
  -- Envios efetivamente tentados (incrementa só quando a Meta vai ser chamada).
  add column if not exists attempt_count integer not null default 0,
  -- Retry/bloqueio temporário: não reservar antes disto (scheduled_for é imutável).
  add column if not exists next_attempt_at timestamptz,
  -- Reserva do worker (claim). Só quem tem o token completa a mensagem.
  add column if not exists lease_token uuid,
  add column if not exists lease_expires_at timestamptz,
  -- Marcado imediatamente antes da chamada HTTP à Meta.
  add column if not exists send_started_at timestamptz;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_attempt_count_non_negative'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_attempt_count_non_negative
      check (attempt_count >= 0);
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_processing_has_lease'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_processing_has_lease
      check (status <> 'processing' or (lease_token is not null and lease_expires_at is not null));
  end if;
end $$;

-- Recuperação de leases vencidas.
create index if not exists whatsapp_messages_processing_lease_idx
  on public.whatsapp_messages (lease_expires_at)
  where status = 'processing';

-- Erro persistido: só estas chaves, nunca texto livre (o texto da Meta pode
-- ecoar dados; token nunca entra por construção).
create or replace function public.whatsapp_sanitize_dispatch_error(p_error jsonb)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select case when p_error is null or jsonb_typeof(p_error) <> 'object' then null
  else jsonb_strip_nulls(jsonb_build_object(
    'code', case when p_error->>'code' ~ '^[a-z0-9_]{1,64}$' then p_error->>'code' end,
    'http_status', case when jsonb_typeof(p_error->'http_status') = 'number' then p_error->'http_status' end,
    'provider_code', case when jsonb_typeof(p_error->'provider_code') = 'number' then p_error->'provider_code' end,
    'provider_subcode', case when jsonb_typeof(p_error->'provider_subcode') = 'number' then p_error->'provider_subcode' end
  )) end
$$;

-- ---------------------------------------------------------------------
-- 3. claim_whatsapp_messages_for_dispatch
-- ---------------------------------------------------------------------
-- Reserva até p_limit mensagens devidas dos tipos com template configurado,
-- só de profissionais com conexão 'connected'. FOR UPDATE SKIP LOCKED: dois
-- workers simultâneos nunca pegam a mesma linha. Antes, recupera leases
-- vencidas (ver cabeçalho).
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

-- ---------------------------------------------------------------------
-- 4. prepare_whatsapp_message_send
-- ---------------------------------------------------------------------
-- Revalida TUDO imediatamente antes do envio e, se puder enviar, marca
-- send_started_at e devolve só o necessário para montar o template:
-- destino, primeiro nome, data/hora da consulta, fuso, phone_number_id e o
-- token da conexão. Nada clínico.
--
-- Inválida para sempre (condição que não volta atrás) -> cancelled:
--   consent_revoked, stale_schedule_revision, appointment_already_occurred.
-- Bloqueio que pode passar -> volta para scheduled com next_attempt_at:
--   appointment_status_not_sendable, patient_changed, patient_deleted,
--   destination_changed, connection_inactive, credential_missing.
create or replace function public.prepare_whatsapp_message_send(
  p_message_id uuid,
  p_lease_token uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_msg public.whatsapp_messages%rowtype;
  v_appt public.appointments%rowtype;
  v_tz text;
  v_start timestamptz;
  v_consent_revoked_at timestamptz;
  v_patient_phone text;
  v_patient_deleted_at timestamptz;
  v_patient_name text;
  v_patient_social_name text;
  v_connection_id uuid;
  v_connection_status text;
  v_phone_number_id text;
  v_token text;
  v_code text;
  v_cancel boolean := false;
  v_defer_seconds integer;
  v_display_name text;
begin
  select m.* into v_msg
  from public.whatsapp_messages m
  where m.id = p_message_id
  for update;

  if v_msg.id is null
     or v_msg.status <> 'processing'
     or v_msg.lease_token is distinct from p_lease_token
     or v_msg.lease_expires_at <= now() then
    return jsonb_build_object('result', 'lease_lost');
  end if;

  select a.* into v_appt
  from public.appointments a
  where a.id = v_msg.appointment_id
    and a.fisioterapeuta_id = v_msg.fisioterapeuta_id;

  select pr.timezone into v_tz from public.profiles pr where pr.id = v_msg.fisioterapeuta_id;
  v_start := (v_appt.date + v_appt.time) at time zone coalesce(v_tz, 'America/Sao_Paulo');

  select pc.revoked_at into v_consent_revoked_at
  from public.patient_consents pc where pc.id = v_msg.consent_id;

  select p.phone_e164, p.deleted_at, p.name, p.social_name
  into v_patient_phone, v_patient_deleted_at, v_patient_name, v_patient_social_name
  from public.patients p
  where p.id = v_msg.patient_id and p.fisioterapeuta_id = v_msg.fisioterapeuta_id;

  select c.id, c.status, c.phone_number_id
  into v_connection_id, v_connection_status, v_phone_number_id
  from public.whatsapp_connections c
  where c.fisioterapeuta_id = v_msg.fisioterapeuta_id;

  if v_consent_revoked_at is not null then
    v_code := 'consent_revoked'; v_cancel := true;
  elsif v_appt.schedule_revision is distinct from v_msg.schedule_revision then
    v_code := 'stale_schedule_revision'; v_cancel := true;
  elsif now() >= v_start then
    v_code := 'appointment_already_occurred'; v_cancel := true;
  elsif not (
    (v_msg.reminder_type = 'appointment_12h' and v_appt.status = 'scheduled')
    or (v_msg.reminder_type in ('appointment_confirmation', 'appointment_rescheduled')
        and v_appt.status in ('scheduled', 'confirmed'))
  ) then
    -- A solicitação de confirmação só faz sentido para consulta ainda não
    -- confirmada (mesma regra do inbound, que só confirma 'scheduled').
    v_code := 'appointment_status_not_sendable'; v_defer_seconds := 900;
  elsif v_appt.patient_id is distinct from v_msg.patient_id then
    v_code := 'patient_changed'; v_defer_seconds := 900;
  elsif v_patient_deleted_at is not null then
    v_code := 'patient_deleted'; v_defer_seconds := 900;
  elsif v_patient_phone is distinct from v_msg.destination_phone_e164 then
    v_code := 'destination_changed'; v_defer_seconds := 900;
  elsif v_connection_status is distinct from 'connected' or v_phone_number_id is null then
    v_code := 'connection_inactive'; v_defer_seconds := 1800;
  else
    select ds.decrypted_secret into v_token
    from public.whatsapp_connection_credentials cc
    join vault.decrypted_secrets ds on ds.id = cc.vault_secret_id
    where cc.connection_id = v_connection_id;
    if v_token is null or v_token = '' then
      v_code := 'credential_missing'; v_defer_seconds := 1800;
    end if;
  end if;

  if v_cancel then
    update public.whatsapp_messages
    set status = 'cancelled',
        lease_token = null,
        lease_expires_at = null,
        error = jsonb_build_object('code', v_code)
    where id = v_msg.id;
    return jsonb_build_object('result', 'cancelled', 'code', v_code);
  end if;

  if v_code is not null then
    update public.whatsapp_messages
    set status = 'scheduled',
        lease_token = null,
        lease_expires_at = null,
        next_attempt_at = now() + make_interval(secs => v_defer_seconds),
        error = jsonb_build_object('code', v_code)
    where id = v_msg.id;
    return jsonb_build_object('result', 'deferred', 'code', v_code);
  end if;

  update public.whatsapp_messages
  set send_started_at = now(),
      attempt_count = attempt_count + 1
  where id = v_msg.id;

  v_display_name := split_part(btrim(coalesce(
    nullif(btrim(v_patient_social_name), ''), v_patient_name, '')), ' ', 1);

  return jsonb_build_object(
    'result', 'ready',
    'reminder_type', v_msg.reminder_type,
    'attempt_count', v_msg.attempt_count + 1,
    'destination_phone_e164', v_msg.destination_phone_e164,
    'patient_first_name', v_display_name,
    'appointment_date', to_char(v_appt.date, 'YYYY-MM-DD'),
    'appointment_time', to_char(v_appt.time, 'HH24:MI'),
    'time_zone', v_tz,
    'phone_number_id', v_phone_number_id,
    'access_token', v_token
  );
end;
$$;

-- ---------------------------------------------------------------------
-- 5. complete_whatsapp_message_send
-- ---------------------------------------------------------------------
-- p_result:
--   'sent'   wamid obrigatório. Aceito também se a lease venceu e a linha
--            já foi para failed/send_outcome_unknown (a Meta aceitou: o
--            wamid precisa ficar gravado para o inbound correlacionar).
--   'retry'  volta para scheduled com next_attempt_at = now() + p_retry_delay_seconds.
--   'failed' definitivo.
-- Só quem tem o lease_token completa. Erro gravado só com chaves conhecidas.
create or replace function public.complete_whatsapp_message_send(
  p_message_id uuid,
  p_lease_token uuid,
  p_result text,
  p_wamid text default null,
  p_template_name text default null,
  p_error jsonb default null,
  p_retry_delay_seconds integer default null
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_msg public.whatsapp_messages%rowtype;
begin
  if p_result not in ('sent', 'retry', 'failed')
     or (p_result = 'sent' and (p_wamid is null or btrim(p_wamid) = '' or length(p_wamid) > 256))
     or (p_result = 'retry' and (p_retry_delay_seconds is null
                                 or p_retry_delay_seconds not between 1 and 86400)) then
    raise exception using errcode = 'WA004',
      message = 'complete_whatsapp_message_send: parametros invalidos';
  end if;

  select m.* into v_msg
  from public.whatsapp_messages m
  where m.id = p_message_id
  for update;

  if v_msg.id is null or v_msg.lease_token is distinct from p_lease_token then
    return 'lease_lost';
  end if;

  if p_result = 'sent' then
    if not (v_msg.status = 'processing'
            or (v_msg.status = 'failed' and v_msg.error->>'code' = 'send_outcome_unknown')) then
      return 'lease_lost';
    end if;
    update public.whatsapp_messages
    set status = 'sent',
        wamid = btrim(p_wamid),
        sent_at = now(),
        failed_at = null,
        template_name = p_template_name,
        error = null,
        lease_token = null,
        lease_expires_at = null
    where id = v_msg.id;
    return 'ok';
  end if;

  if v_msg.status <> 'processing' then
    return 'lease_lost';
  end if;

  if p_result = 'retry' then
    update public.whatsapp_messages
    set status = 'scheduled',
        next_attempt_at = now() + make_interval(secs => p_retry_delay_seconds),
        error = public.whatsapp_sanitize_dispatch_error(p_error),
        lease_token = null,
        lease_expires_at = null,
        send_started_at = null
    where id = v_msg.id;
  else
    update public.whatsapp_messages
    set status = 'failed',
        failed_at = now(),
        template_name = p_template_name,
        error = public.whatsapp_sanitize_dispatch_error(p_error),
        lease_token = null,
        lease_expires_at = null
    where id = v_msg.id;
  end if;
  return 'ok';
end;
$$;

-- ---------------------------------------------------------------------
-- 6. Permissões: só service_role
-- ---------------------------------------------------------------------
revoke all on function public.set_whatsapp_connection_access_token(uuid, text)
  from public, anon, authenticated;
revoke all on function public.claim_whatsapp_messages_for_dispatch(integer, integer, text[])
  from public, anon, authenticated;
revoke all on function public.prepare_whatsapp_message_send(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.complete_whatsapp_message_send(uuid, uuid, text, text, text, jsonb, integer)
  from public, anon, authenticated;
revoke all on function public.whatsapp_sanitize_dispatch_error(jsonb)
  from public, anon, authenticated;

grant execute on function public.set_whatsapp_connection_access_token(uuid, text) to service_role;
grant execute on function public.claim_whatsapp_messages_for_dispatch(integer, integer, text[]) to service_role;
grant execute on function public.prepare_whatsapp_message_send(uuid, uuid) to service_role;
grant execute on function public.complete_whatsapp_message_send(uuid, uuid, text, text, text, jsonb, integer) to service_role;

-- ---------------------------------------------------------------------
-- Check (read-only):
--   01_check  1 linha: whatsapp_connection_credentials com RLS ligada
--   02_check  5 linhas: colunas novas em whatsapp_messages
--   03_check  4 linhas: RPCs security definer, sem EXECUTE para anon/authenticated
-- ---------------------------------------------------------------------
select '01_check' as secao, c.relname as tabela, c.relrowsecurity as rls
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname = 'whatsapp_connection_credentials';

select '02_check' as secao, column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'whatsapp_messages'
  and column_name in ('attempt_count', 'next_attempt_at', 'lease_token',
                      'lease_expires_at', 'send_started_at')
order by column_name;

select '03_check' as secao, p.proname, p.prosecdef as security_definer,
  has_function_privilege('anon', p.oid, 'execute') as anon_exec,
  has_function_privilege('authenticated', p.oid, 'execute') as authenticated_exec
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('set_whatsapp_connection_access_token',
                    'claim_whatsapp_messages_for_dispatch',
                    'prepare_whatsapp_message_send',
                    'complete_whatsapp_message_send')
order by p.proname;
