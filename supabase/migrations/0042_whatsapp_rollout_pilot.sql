-- Migration 0042 -- liberação gradual do onboarding do WhatsApp (piloto).
--
-- whatsapp_rollout (1 linha): mode = 'off' | 'pilot' | 'all'.
--   off   : ninguém inicia conexão (rollback imediato; conexões existentes seguem).
--   pilot : só quem está em pilot_user_ids.
--   all   : todas as profissionais.
-- A chave WHATSAPP_SELF_CONNECT_ENABLED do ambiente continua valendo (liga para todos);
-- esta tabela é a liberação por cima dela, mudável por SQL sem redeploy nem secret.
-- Sem policy: o app nunca lê. Aditiva e idempotente. Padrão: 'off'.

create table if not exists public.whatsapp_rollout (
  singleton boolean primary key default true check (singleton),
  mode text not null default 'off' check (mode in ('off', 'pilot', 'all')),
  pilot_user_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now()
);
insert into public.whatsapp_rollout (singleton) values (true) on conflict do nothing;

alter table public.whatsapp_rollout enable row level security;
revoke all on public.whatsapp_rollout from public, anon, authenticated;

create or replace function public.whatsapp_self_connect_allowed(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select r.mode = 'all' or (r.mode = 'pilot' and p_user_id = any (r.pilot_user_ids))
       from public.whatsapp_rollout r where r.singleton),
    false);
$$;

revoke all on function public.whatsapp_self_connect_allowed(uuid) from public, anon, authenticated;
grant execute on function public.whatsapp_self_connect_allowed(uuid) to service_role;
