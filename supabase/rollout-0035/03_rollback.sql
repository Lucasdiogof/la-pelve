-- Desfaz a 0035: só remove a função nova (nada mais mudou). Idempotente.
drop function if exists public.flag_whatsapp_connection_token_invalid(uuid, text);
select to_regprocedure('public.flag_whatsapp_connection_token_invalid(uuid,text)') is null as removida;
