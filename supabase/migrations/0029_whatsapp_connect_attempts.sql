-- Migration 0029 -- onboarding do WhatsApp de cada profissional (Embedded
-- Signup). Só o banco do fluxo; nenhuma credencial da Meta em tabela comum.
--
--  * whatsapp_connect_attempts: "state" de uso único, vinculado à profissional
--    autenticada no momento em que ela inicia a conexão. Guarda só o HASH
--    (sha256) do state; o valor em claro existe apenas no navegador dela.
--    Protege contra CSRF/replay: expira em minutos e só pode ser consumido
--    uma vez, de forma atômica.
--  * RPCs (só service_role) usadas pela Edge Function whatsapp-connect.
-- O token da Meta continua no Vault via set_whatsapp_connection_access_token
-- (migration 0026). Idempotente e aditiva. Rollback: rollout-0029/02_rollback.sql.

create table if not exists public.whatsapp_connect_attempts (
  state_hash text primary key check (state_hash ~ '^[0-9a-f]{64}$'),
  fisioterapeuta_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  used_at timestamptz,
  constraint whatsapp_connect_attempts_ttl
    check (expires_at > created_at and expires_at <= created_at + interval '1 hour')
);
create index if not exists whatsapp_connect_attempts_owner_idx
  on public.whatsapp_connect_attempts (fisioterapeuta_id, created_at desc);

alter table public.whatsapp_connect_attempts enable row level security;
revoke all on public.whatsapp_connect_attempts from public, anon, authenticated;
-- Sem policy: nem leitura pelo app. Só service_role (bypass de RLS).

-- Cria uma tentativa. Invalida (marca como usadas) as anteriores ainda
-- abertas da mesma profissional e limita a 10 por hora (anti-abuso).
create or replace function public.create_whatsapp_connect_attempt(
  p_fisioterapeuta_id uuid,
  p_state_hash text,
  p_ttl_seconds integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_ttl_seconds is null or p_ttl_seconds not between 60 and 1800 then
    raise exception using errcode = 'WA005', message = 'ttl invalido';
  end if;
  if (select count(*) from public.whatsapp_connect_attempts a
      where a.fisioterapeuta_id = p_fisioterapeuta_id
        and a.created_at > now() - interval '1 hour') >= 10 then
    raise exception using errcode = 'WA006', message = 'muitas tentativas';
  end if;
  update public.whatsapp_connect_attempts
     set used_at = now()
   where fisioterapeuta_id = p_fisioterapeuta_id and used_at is null;
  insert into public.whatsapp_connect_attempts
    (state_hash, fisioterapeuta_id, expires_at)
  values (p_state_hash, p_fisioterapeuta_id, now() + make_interval(secs => p_ttl_seconds));
end;
$$;

-- Consulta sem consumir (a página de onboarding valida o state antes de
-- abrir o popup da Meta). Devolve a profissional ou nulo.
create or replace function public.peek_whatsapp_connect_attempt(p_state_hash text)
returns uuid
language sql
security definer
set search_path = ''
stable
as $$
  select a.fisioterapeuta_id
  from public.whatsapp_connect_attempts a
  where a.state_hash = p_state_hash and a.used_at is null and a.expires_at > now();
$$;

-- Consome atomicamente: a primeira chamada válida devolve a profissional,
-- qualquer repetição/expirada devolve nulo.
create or replace function public.consume_whatsapp_connect_attempt(p_state_hash text)
returns uuid
language sql
security definer
set search_path = ''
as $$
  update public.whatsapp_connect_attempts a
     set used_at = now()
   where a.state_hash = p_state_hash and a.used_at is null and a.expires_at > now()
  returning a.fisioterapeuta_id;
$$;

-- Cria/atualiza a conexão da profissional e devolve o id. Recusa trocar uma
-- conexão ATIVA (é preciso desconectar antes) e número já usado por outra
-- profissional (phone_number_id é único).
create or replace function public.upsert_whatsapp_connection_from_signup(
  p_fisioterapeuta_id uuid,
  p_waba_id text,
  p_phone_number_id text,
  p_display_phone_number text,
  p_status text,
  p_last_error jsonb
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
  if p_status not in ('pending', 'connected') then
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
  if found then
    update public.whatsapp_connections
       set waba_id = p_waba_id, phone_number_id = p_phone_number_id,
           display_phone_number = p_display_phone_number, status = p_status,
           connected_at = case when p_status = 'connected'
                               then coalesce(v_existing.connected_at, now()) else null end,
           disconnected_at = null, last_error = p_last_error
     where id = v_existing.id
    returning id into v_id;
  else
    insert into public.whatsapp_connections
      (fisioterapeuta_id, waba_id, phone_number_id, display_phone_number,
       status, connected_at, last_error)
    values (p_fisioterapeuta_id, p_waba_id, p_phone_number_id, p_display_phone_number,
            p_status, case when p_status = 'connected' then now() end, p_last_error)
    returning id into v_id;
  end if;
  return v_id;
end;
$$;

-- Desconecta: apaga a credencial (o trigger remove o segredo do Vault) e
-- marca a conexão como desconectada. Devolve waba_id para a function tirar
-- a inscrição do webhook.
create or replace function public.disconnect_whatsapp_connection(p_fisioterapeuta_id uuid)
returns table (waba_id text, phone_number_id text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v public.whatsapp_connections%rowtype;
begin
  select * into v from public.whatsapp_connections
   where fisioterapeuta_id = p_fisioterapeuta_id for update;
  if not found then return; end if;
  delete from public.whatsapp_connection_credentials where connection_id = v.id;
  update public.whatsapp_connections
     set status = 'disconnected', disconnected_at = now(), last_error = null
   where id = v.id;
  return query select v.waba_id, v.phone_number_id;
end;
$$;

-- Leitura do token da profissional, só para a Edge Function whatsapp-connect
-- (status de templates e desconexão). service_role apenas; nunca chega ao app.
create or replace function public.get_whatsapp_connection_access_token(p_fisioterapeuta_id uuid)
returns text
language sql
security definer
set search_path = ''
stable
as $$
  select ds.decrypted_secret
  from public.whatsapp_connections c
  join public.whatsapp_connection_credentials cr on cr.connection_id = c.id
  join vault.decrypted_secrets ds on ds.id = cr.vault_secret_id
  where c.fisioterapeuta_id = p_fisioterapeuta_id;
$$;

revoke all on function public.create_whatsapp_connect_attempt(uuid, text, integer) from public, anon, authenticated;
revoke all on function public.peek_whatsapp_connect_attempt(text) from public, anon, authenticated;
revoke all on function public.consume_whatsapp_connect_attempt(text) from public, anon, authenticated;
revoke all on function public.upsert_whatsapp_connection_from_signup(uuid, text, text, text, text, jsonb) from public, anon, authenticated;
revoke all on function public.disconnect_whatsapp_connection(uuid) from public, anon, authenticated;
revoke all on function public.get_whatsapp_connection_access_token(uuid) from public, anon, authenticated;
grant execute on function public.get_whatsapp_connection_access_token(uuid) to service_role;
grant execute on function public.create_whatsapp_connect_attempt(uuid, text, integer) to service_role;
grant execute on function public.peek_whatsapp_connect_attempt(text) to service_role;
grant execute on function public.consume_whatsapp_connect_attempt(text) to service_role;
grant execute on function public.upsert_whatsapp_connection_from_signup(uuid, text, text, text, text, jsonb) to service_role;
grant execute on function public.disconnect_whatsapp_connection(uuid) to service_role;
