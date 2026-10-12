-- 0035: marca uma conexão como 'error'/token_invalid de forma atômica e
-- vinculada AO TOKEN que foi recusado.
--
-- Problema (revisão do PR #13): o dispatcher recebe o erro 190 da Meta para
-- um envio feito com o token T1. Se, antes de a resposta chegar, a
-- profissional reconectou (token novo T2 gravado NO MESMO segredo do Vault),
-- marcar a conexão apenas por fisioterapeuta_id + status='connected' derrubaria
-- a conexão nova por causa de uma resposta velha. Ler e depois escrever
-- também deixa uma janela de corrida.
--
-- Esta função faz tudo na mesma transação:
--   1. trava a linha da conexão (FOR UPDATE): espera uma reconexão em curso;
--   2. relê o token atual do Vault (instrução nova = snapshot novo) e compara
--      o SHA-256 dele com o hash recebido; o token nunca é comparado nem
--      devolvido em texto, e só o hash (não reversível) trafega;
--   3. só se o token atual ainda é o mesmo que a Meta recusou, marca
--      status='error', connected_at=null, last_error={"code":"token_invalid"}.
--
-- Retorno: 'flagged' (marcou), 'stale' (o token já foi trocado: nada muda),
-- 'skipped' (sem conexão, desconectada, em erro por outro motivo ou sem
-- credencial). Só 'connected' e 'pending' podem ser marcadas.
-- Só service_role executa. Nenhuma linha existente muda ao aplicar.

create or replace function public.flag_whatsapp_connection_token_invalid(
  p_fisioterapeuta_id uuid,
  p_token_sha256 text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_conn public.whatsapp_connections;
  v_secret text;
begin
  if p_token_sha256 is null or p_token_sha256 !~ '^[0-9a-f]{64}$' then
    raise exception using errcode = 'WA011',
      message = 'flag_whatsapp_connection_token_invalid: hash invalido';
  end if;

  select * into v_conn
    from public.whatsapp_connections
   where fisioterapeuta_id = p_fisioterapeuta_id
     for update;
  if not found or v_conn.status not in ('connected', 'pending') then
    return 'skipped';
  end if;

  select ds.decrypted_secret into v_secret
    from public.whatsapp_connection_credentials cc
    join vault.decrypted_secrets ds on ds.id = cc.vault_secret_id
   where cc.connection_id = v_conn.id;
  if v_secret is null or v_secret = '' then
    return 'skipped';
  end if;

  if pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(v_secret, 'UTF8')), 'hex')
       is distinct from p_token_sha256 then
    return 'stale';
  end if;

  update public.whatsapp_connections
     set status = 'error',
         connected_at = null,
         last_error = pg_catalog.jsonb_build_object('code', 'token_invalid')
   where id = v_conn.id;
  return 'flagged';
end;
$$;

revoke all on function public.flag_whatsapp_connection_token_invalid(uuid, text)
  from public, anon, authenticated;
grant execute on function public.flag_whatsapp_connection_token_invalid(uuid, text) to service_role;
