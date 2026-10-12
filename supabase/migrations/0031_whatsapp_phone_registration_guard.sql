-- 0031: crash-safe, per-phone registration guard for WhatsApp Cloud API.
--
-- Each /register request MUST be reserved in PostgreSQL before the HTTP call.
-- Attempts are tracked by phone_number_id, not by login/session/connection.
-- A stable six-digit PIN is created once using pgcrypto and encrypted in Vault.
-- Its plaintext is returned only by a service_role-only RPC to the Edge Function.
-- No PINs/tokens appear in the user-readable whatsapp_connections.setup_state.
--
-- This migration is additive; existing connections and consent are unchanged.

create table if not exists public.whatsapp_phone_registration_guard (
  phone_number_id text primary key check (phone_number_id ~ '^[0-9]{5,32}$'),
  pin_secret_id uuid not null references vault.secrets(id),
  register_attempts timestamptz[] not null default array[]::timestamptz[],
  last_attempt_at timestamptz,
  blocked_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.whatsapp_phone_registration_guard enable row level security;
revoke all on public.whatsapp_phone_registration_guard from public, anon, authenticated;
-- Deliberately NO authenticated policy. Edge Functions use service-role RPCs.

create or replace function public.reserve_whatsapp_phone_registration(
  p_fisioterapeuta_id uuid,
  p_phone_number_id text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_guard public.whatsapp_phone_registration_guard%rowtype;
  v_now timestamptz := clock_timestamp();
  v_attempts timestamptz[];
  v_pin text;
  v_secret uuid;
  v_bytes bytea;
  v_number bigint;
  v_unblock timestamptz;
begin
  if p_fisioterapeuta_id is null or p_phone_number_id is null
     or p_phone_number_id !~ '^[0-9]{5,32}$' then
    return jsonb_build_object('status', 'error');
  end if;

  -- Serialize across workers, retries, and *different* accounts. An owner
  -- cannot reset the rate limit by disconnecting or reconnecting.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_phone_number_id, 114991)
  );

  -- Only a pending connection that already reserved this phone may register.
  perform 1 from public.whatsapp_connections c
    where c.fisioterapeuta_id = p_fisioterapeuta_id
      and c.phone_number_id = p_phone_number_id
      and c.status = 'pending'
    for update;
  if not found then
    return jsonb_build_object('status', 'error');
  end if;

  select * into v_guard
  from public.whatsapp_phone_registration_guard g
  where g.phone_number_id = p_phone_number_id
  for update;

  if not found then
    -- Secure random, stable for a phone across crashes and re-onboarding.
    v_bytes := extensions.gen_random_bytes(4);
    v_number := (
      (pg_catalog.get_byte(v_bytes, 0)::bigint << 24) +
      (pg_catalog.get_byte(v_bytes, 1)::bigint << 16) +
      (pg_catalog.get_byte(v_bytes, 2)::bigint << 8) +
       pg_catalog.get_byte(v_bytes, 3)::bigint
    ) % 1000000;
    v_pin := pg_catalog.lpad(v_number::text, 6, '0');
    v_secret := vault.create_secret(
      v_pin, null, 'La Pelve WhatsApp registration PIN', null
    );
    insert into public.whatsapp_phone_registration_guard
      (phone_number_id, pin_secret_id)
    values (p_phone_number_id, v_secret);
    select * into v_guard
      from public.whatsapp_phone_registration_guard g
      where g.phone_number_id = p_phone_number_id
      for update;
  end if;

  if v_guard.blocked_until is not null and v_guard.blocked_until > v_now then
    return jsonb_build_object('status', 'limited');
  end if;

  select coalesce(array_agg(t.ts order by t.ts), array[]::timestamptz[])
    into v_attempts
  from pg_catalog.unnest(v_guard.register_attempts) as t(ts)
  where t.ts > v_now - interval '72 hours';

  if pg_catalog.cardinality(v_attempts) >= 8 then
    v_unblock := v_attempts[1] + interval '72 hours';
    update public.whatsapp_phone_registration_guard
       set register_attempts = v_attempts,
           blocked_until = v_unblock,
           updated_at = v_now
     where phone_number_id = p_phone_number_id;
    return jsonb_build_object('status', 'limited');
  end if;

  -- A retry window limits load after a timeout/unknown Meta outcome.
  if v_guard.last_attempt_at is not null
     and v_guard.last_attempt_at > v_now - interval '15 minutes' then
    return jsonb_build_object('status', 'cooldown');
  end if;

  select ds.decrypted_secret into v_pin
    from vault.decrypted_secrets ds
   where ds.id = v_guard.pin_secret_id;
  if v_pin is null or v_pin !~ '^[0-9]{6}$' then
    return jsonb_build_object('status', 'error');
  end if;

  -- The increment is COMMITTED before the Edge Function can call /register.
  update public.whatsapp_phone_registration_guard
     set register_attempts = v_attempts || array[v_now],
         last_attempt_at = v_now,
         blocked_until = null,
         updated_at = v_now
   where phone_number_id = p_phone_number_id;

  return jsonb_build_object('status', 'reserved', 'pin', v_pin);
end;
$$;

create or replace function public.mark_whatsapp_phone_registration_limited(
  p_fisioterapeuta_id uuid,
  p_phone_number_id text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.whatsapp_connections c
    where c.fisioterapeuta_id = p_fisioterapeuta_id
      and c.phone_number_id = p_phone_number_id
      and c.status = 'pending'
  ) then
    return false;
  end if;

  update public.whatsapp_phone_registration_guard g
     set blocked_until = pg_catalog.greatest(
           coalesce(g.blocked_until, now()), now() + interval '72 hours'
         ),
         updated_at = now()
   where g.phone_number_id = p_phone_number_id;
  return found;
end;
$$;

revoke all on function public.reserve_whatsapp_phone_registration(uuid,text)
  from public,anon,authenticated;
revoke all on function public.mark_whatsapp_phone_registration_limited(uuid,text)
  from public,anon,authenticated;
grant execute on function public.reserve_whatsapp_phone_registration(uuid,text)
  to service_role;
grant execute on function public.mark_whatsapp_phone_registration_limited(uuid,text)
  to service_role;
