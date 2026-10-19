-- Exclusão definitiva de todos os dados com PRAZO DE ARREPENDIMENTO de 30 dias (ADITIVA e idempotente).
--
-- Fluxo: a profissional pede "excluir todos os meus dados" (com confirmação explícita no app, depois de ser
-- oferecida a exportação). A conta fica "em exclusão": lembretes de WhatsApp param, o app mostra só a tela de
-- restaurar. Durante 30 dias ela pode cancelar. Depois, uma rotina de servidor (Edge Function account-purge, com
-- service_role) apaga os arquivos do Storage pela API, confere que não sobrou nenhum e só então chama
-- finalize_account_deletion(), que apaga a conta e deixa o registro mínimo em account_deletion_log.
--
-- NÃO é retenção para consulta: o prazo existe só para desfazer engano. Retenção por outro motivo (defesa de
-- direitos etc.) é decisão jurídica pendente (docs/privacy/LEGAL_DECISIONS.md).
-- Contas vazias continuam usando delete_own_account() (imediato). Contas com dados continuam bloqueadas ali.

create table if not exists public.account_deletion_requests (
  user_id uuid primary key references auth.users (id) on delete cascade,
  requested_at timestamptz not null default now(),
  purge_after timestamptz not null,
  -- Status da conexão WhatsApp antes de pausá-la, para restaurar igual.
  whatsapp_prev_status text,
  constraint account_deletion_requests_purge_after_check check (purge_after > requested_at)
);
alter table public.account_deletion_requests enable row level security;
revoke all on table public.account_deletion_requests from public, anon, authenticated;

-- Pede a exclusão definitiva. Idempotente: repetir devolve o pedido já existente (não renova o prazo).
create or replace function public.request_account_data_deletion(p_confirmation text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  req public.account_deletion_requests;
  prev text;
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;
  if p_confirmation is distinct from 'EXCLUIR_TODOS_OS_DADOS' then
    raise exception 'confirmation_required';
  end if;
  perform 1 from auth.users where id = uid for update;
  if not found then
    raise exception 'not authenticated';
  end if;

  select * into req from public.account_deletion_requests where user_id = uid;
  if not found then
    -- Para os lembretes: cancela o que está na fila e desconecta o envio.
    update public.whatsapp_messages
       set status = 'cancelled'
     where fisioterapeuta_id = uid and status = 'scheduled';
    select status into prev from public.whatsapp_connections where fisioterapeuta_id = uid;
    if prev = 'connected' then
      update public.whatsapp_connections
         set status = 'disconnected', disconnected_at = now()
       where fisioterapeuta_id = uid;
    else
      prev := null;
    end if;
    insert into public.account_deletion_requests (user_id, purge_after, whatsapp_prev_status)
    values (uid, now() + interval '30 days', prev)
    returning * into req;
  end if;
  return jsonb_build_object('requested_at', req.requested_at, 'purge_after', req.purge_after);
end;
$$;

-- Cancela o pedido dentro do prazo. Restaura a conexão WhatsApp como estava; mensagens canceladas NÃO voltam
-- (o agendador cria as próximas normalmente).
create or replace function public.cancel_account_data_deletion()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  req public.account_deletion_requests;
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;
  perform 1 from auth.users where id = uid for update;
  select * into req from public.account_deletion_requests where user_id = uid;
  if not found then
    return; -- nada a cancelar (idempotente)
  end if;
  if req.purge_after <= now() then
    raise exception 'deletion_deadline_passed' using errcode = 'P0001';
  end if;
  if req.whatsapp_prev_status = 'connected' then
    update public.whatsapp_connections
       set status = 'connected', disconnected_at = null
     where fisioterapeuta_id = uid and status = 'disconnected';
  end if;
  delete from public.account_deletion_requests where user_id = uid;
end;
$$;

-- Estado do pedido para o app (null quando não há).
create or replace function public.get_account_deletion_status()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object('requested_at', r.requested_at, 'purge_after', r.purge_after)
    from public.account_deletion_requests r
   where r.user_id = auth.uid()
$$;

-- Só service_role (Edge Function account-purge): contas com prazo vencido.
create or replace function public.list_due_account_deletions(p_limit integer default 20)
returns table (user_id uuid)
language sql
stable
security definer
set search_path = public
as $$
  select r.user_id from public.account_deletion_requests r
   where r.purge_after <= now()
   order by r.purge_after
   limit least(greatest(coalesce(p_limit, 20), 1), 100)
$$;

-- Só service_role. Apaga a conta DEPOIS de os arquivos terem sido removidos pela API do Storage.
-- Recusa se o pedido não existe, se o prazo não venceu ou se ainda há objeto do usuário no Storage.
create or replace function public.finalize_account_deletion(p_user uuid)
returns void
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  req public.account_deletion_requests;
  remaining bigint;
begin
  perform 1 from auth.users where id = p_user for update;
  if not found then
    return; -- já excluída (reexecução da rotina)
  end if;
  select * into req from public.account_deletion_requests where user_id = p_user;
  if not found then
    raise exception 'no_deletion_request' using errcode = 'P0001';
  end if;
  if req.purge_after > now() then
    raise exception 'grace_period_not_over' using errcode = 'P0001';
  end if;
  select count(*) into remaining from storage.objects
   where bucket_id in ('patient-attachments', 'avatars')
     and (storage.foldername(name))[1] = p_user::text;
  if remaining > 0 then
    raise exception 'storage_not_empty' using errcode = 'P0001';
  end if;
  insert into public.account_deletion_log (user_hash, counts)
  values (encode(sha256(convert_to(p_user::text, 'utf8')), 'hex'),
          public.account_data_counts(p_user) || jsonb_build_object('via', 'grace_period'));
  delete from auth.users where id = p_user;
end;
$$;

revoke all on function public.request_account_data_deletion(text) from public, anon;
revoke all on function public.cancel_account_data_deletion() from public, anon;
revoke all on function public.get_account_deletion_status() from public, anon;
revoke all on function public.list_due_account_deletions(integer) from public, anon, authenticated;
revoke all on function public.finalize_account_deletion(uuid) from public, anon, authenticated;
grant execute on function public.request_account_data_deletion(text) to authenticated;
grant execute on function public.cancel_account_data_deletion() to authenticated;
grant execute on function public.get_account_deletion_status() to authenticated;
grant execute on function public.list_due_account_deletions(integer) to service_role;
grant execute on function public.finalize_account_deletion(uuid) to service_role;
