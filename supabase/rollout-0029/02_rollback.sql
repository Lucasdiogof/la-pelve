drop function if exists public.get_whatsapp_connection_access_token(uuid);
drop function if exists public.disconnect_whatsapp_connection(uuid);
drop function if exists public.upsert_whatsapp_connection_from_signup(uuid, text, text, text, text, jsonb);
drop function if exists public.consume_whatsapp_connect_attempt(text);
drop function if exists public.peek_whatsapp_connect_attempt(text);
drop function if exists public.create_whatsapp_connect_attempt(uuid, text, integer);
drop table if exists public.whatsapp_connect_attempts;
