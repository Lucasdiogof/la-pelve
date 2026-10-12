-- 0032: guard de registro de número na Cloud API do WhatsApp (por phone_number_id).
--
-- Regras:
-- - Toda chamada a POST /{phone_number_id}/register é RESERVADA aqui antes da
--   chamada HTTP. A reserva (incremento da tentativa) é confirmada quando a
--   RPC retorna, então um crash ou timeout depois dela continua contando.
-- - O controle é por número (phone_number_id), não por sessão/conexão/conta:
--   desconectar e reconectar, ou outra profissional tentar o mesmo número, não
--   zera o limite.
-- - Concorrência: advisory lock transacional por número + FOR UPDATE na linha.
-- - Limite próprio: 8 tentativas em 72 h (a Meta corta em 10, erro 133016),
--   intervalo mínimo de 10 min entre tentativas e bloqueio de 72 h quando a
--   Meta responde 133016.
-- - PIN de verificação em duas etapas: 6 dígitos gerados UMA vez por número com
--   pgcrypto, guardados só no Vault. É o mesmo PIN em todas as tentativas e em
--   reconexões (o número registrado por nós fica com 2FA = esse PIN). O texto
--   do PIN só sai pela RPC de reserva, executável apenas por service_role.
-- - Número com 2FA ligada que NÃO foi registrado por nós: sem PIN guardado,
--   a RPC responde pin_unknown e nada é enviado à Meta.
--
-- Aditiva: não altera conexões, consentimentos, mensagens nem dados clínicos.
-- Requer pgcrypto (schema extensions) e supabase_vault.

do $$
begin
  if not exists (select 1 from pg_extension where extname = 'supabase_vault') then
    raise exception '0032 requer a extensão supabase_vault';
  end if;
  if not exists (select 1 from pg_extension where extname = 'pgcrypto') then
    raise exception '0032 requer a extensão pgcrypto';
  end if;
end;
$$;

create table if not exists public.whatsapp_phone_registration_guard (
  phone_number_id text primary key check (phone_number_id ~ '^[0-9]{5,32}$'),
  pin_secret_id uuid not null,
  register_attempts timestamptz[] not null default array[]::timestamptz[],
  last_attempt_at timestamptz,
  blocked_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.whatsapp_phone_registration_guard is
  'Tentativas de registro na Cloud API por número e id do PIN de 2FA no Vault. Só backend.';

alter table public.whatsapp_phone_registration_guard enable row level security;
revoke all on public.whatsapp_phone_registration_guard from public, anon, authenticated;
-- Sem policy para authenticated: só as RPCs abaixo (service_role) usam a tabela.

create or replace function public.reserve_whatsapp_phone_registration(
  p_fisioterapeuta_id uuid,
  p_phone_number_id text,
  p_existing_pin_only boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_guard public.whatsapp_phone_registration_guard%rowtype;
  v_now timestamptz := pg_catalog.clock_timestamp();
  v_attempts timestamptz[];
  v_pin text;
  v_secret uuid;
  v_bytes bytea;
  v_number bigint;
begin
  if p_fisioterapeuta_id is null or p_phone_number_id is null
     or p_phone_number_id !~ '^[0-9]{5,32}$' then
    return pg_catalog.jsonb_build_object('status', 'error');
  end if;

  -- Serializa workers, retries e contas diferentes para o mesmo número.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('whatsapp_register:' || p_phone_number_id, 0)
  );

  -- Só a conexão desta profissional, ainda não pronta, que já reservou o
  -- número (linha pending/error criada pelo complete) pode registrar.
  perform 1 from public.whatsapp_connections c
    where c.fisioterapeuta_id = p_fisioterapeuta_id
      and c.phone_number_id = p_phone_number_id
      and c.status in ('pending', 'error')
    for update;
  if not found then
    return pg_catalog.jsonb_build_object('status', 'error');
  end if;

  select * into v_guard
    from public.whatsapp_phone_registration_guard g
   where g.phone_number_id = p_phone_number_id
   for update;

  if not found then
    if p_existing_pin_only then
      -- 2FA ligada por terceiros: não conhecemos o PIN; nada a tentar.
      return pg_catalog.jsonb_build_object('status', 'pin_unknown');
    end if;
    v_bytes := extensions.gen_random_bytes(4);
    v_number := (
      (pg_catalog.get_byte(v_bytes, 0)::bigint << 24) +
      (pg_catalog.get_byte(v_bytes, 1)::bigint << 16) +
      (pg_catalog.get_byte(v_bytes, 2)::bigint << 8) +
       pg_catalog.get_byte(v_bytes, 3)::bigint
    ) % 1000000;
    v_pin := pg_catalog.lpad(v_number::text, 6, '0');
    v_secret := vault.create_secret(
      v_pin,
      'la_pelve_wa_pin_' || p_phone_number_id,
      'La Pelve: PIN de verificação em duas etapas do número da Cloud API'
    );
    insert into public.whatsapp_phone_registration_guard (phone_number_id, pin_secret_id)
    values (p_phone_number_id, v_secret)
    returning * into v_guard;
  end if;

  if v_guard.blocked_until is not null and v_guard.blocked_until > v_now then
    return pg_catalog.jsonb_build_object('status', 'limited', 'retry_at', v_guard.blocked_until);
  end if;

  select coalesce(array_agg(t.ts order by t.ts), array[]::timestamptz[])
    into v_attempts
    from pg_catalog.unnest(v_guard.register_attempts) as t(ts)
   where t.ts > v_now - interval '72 hours';

  if pg_catalog.cardinality(v_attempts) >= 8 then
    update public.whatsapp_phone_registration_guard
       set register_attempts = v_attempts,
           blocked_until = v_attempts[1] + interval '72 hours',
           updated_at = v_now
     where phone_number_id = p_phone_number_id;
    return pg_catalog.jsonb_build_object('status', 'limited', 'retry_at', v_attempts[1] + interval '72 hours');
  end if;

  -- Intervalo mínimo: protege o limite após timeout/resultado desconhecido e
  -- contra cliques repetidos em "Atualizar status".
  if v_guard.last_attempt_at is not null
     and v_guard.last_attempt_at > v_now - interval '10 minutes' then
    return pg_catalog.jsonb_build_object(
      'status', 'cooldown', 'retry_at', v_guard.last_attempt_at + interval '10 minutes'
    );
  end if;

  select ds.decrypted_secret into v_pin
    from vault.decrypted_secrets ds
   where ds.id = v_guard.pin_secret_id;
  if v_pin is null or v_pin !~ '^[0-9]{6}$' then
    return pg_catalog.jsonb_build_object('status', 'error');
  end if;

  update public.whatsapp_phone_registration_guard
     set register_attempts = v_attempts || array[v_now],
         last_attempt_at = v_now,
         blocked_until = null,
         updated_at = v_now
   where phone_number_id = p_phone_number_id;

  return pg_catalog.jsonb_build_object('status', 'reserved', 'pin', v_pin);
end;
$$;

-- A Meta respondeu 133016: bloqueia 72 h a partir de agora (nunca encurta).
create or replace function public.mark_whatsapp_phone_registration_limited(
  p_fisioterapeuta_id uuid,
  p_phone_number_id text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := pg_catalog.clock_timestamp();
begin
  if not exists (
    select 1 from public.whatsapp_connections c
     where c.fisioterapeuta_id = p_fisioterapeuta_id
       and c.phone_number_id = p_phone_number_id
       and c.status in ('pending', 'error')
  ) then
    return false;
  end if;

  update public.whatsapp_phone_registration_guard g
     set blocked_until = greatest(coalesce(g.blocked_until, v_now), v_now + interval '72 hours'),
         updated_at = v_now
   where g.phone_number_id = p_phone_number_id;
  return found;
end;
$$;

revoke all on function public.reserve_whatsapp_phone_registration(uuid, text, boolean)
  from public, anon, authenticated;
revoke all on function public.mark_whatsapp_phone_registration_limited(uuid, text)
  from public, anon, authenticated;
grant execute on function public.reserve_whatsapp_phone_registration(uuid, text, boolean)
  to service_role;
grant execute on function public.mark_whatsapp_phone_registration_limited(uuid, text)
  to service_role;
