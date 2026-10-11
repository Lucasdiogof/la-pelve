drop function if exists public.apply_whatsapp_account_event(text, text, text);
drop function if exists public.count_other_whatsapp_connections_on_waba(uuid, text);
drop function if exists public.upsert_whatsapp_connection_from_signup(uuid, text, text, text, text, jsonb, jsonb);
-- Reaplicar a função da 0029 (6 parâmetros) logo depois, e então:
-- alter table public.whatsapp_connections drop column if exists setup_state;
