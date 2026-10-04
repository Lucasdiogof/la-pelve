-- ROLLBACK da 0018, NÍVEL 1: remove SÓ os objetos novos da integração WhatsApp.
-- NÃO toca em profiles, patients, appointments, attachments, evolution_entries
-- nem financial_entries (nenhum DELETE/UPDATE/TRUNCATE nelas, nenhuma coluna
-- antiga removida). As duas colunas novas (profiles.timezone e
-- patients.phone_e164) ficam, pois são inofensivas; para removê-las use o
-- nível 2 (05_rollback_columns_optional.sql).
--
-- Trava de segurança: se as tabelas novas já têm dados (consentimentos e
-- mensagens são registros novos, que o rollback destruiria), ele ABORTA.
-- Exporte-os antes e só então repita.
--
-- Idempotente: pode rodar de novo sem erro.

do $$
declare
  n_consents bigint := 0;
  n_messages bigint := 0;
  n_connections bigint := 0;
begin
  if to_regclass('public.patient_consents') is not null then
    execute 'select count(*) from public.patient_consents' into n_consents;
  end if;
  if to_regclass('public.whatsapp_messages') is not null then
    execute 'select count(*) from public.whatsapp_messages' into n_messages;
  end if;
  if to_regclass('public.whatsapp_connections') is not null then
    execute 'select count(*) from public.whatsapp_connections' into n_connections;
  end if;
  if n_consents > 0 or n_messages > 0 or n_connections > 0 then
    raise exception 'ROLLBACK ABORTADO: tabelas novas ja tem dados (patient_consents=%, whatsapp_messages=%, whatsapp_connections=%). Exporte antes de repetir.',
      n_consents, n_messages, n_connections;
  end if;
end $$;

-- Tabelas novas (levam junto triggers, policies, índices e constraints delas).
drop table if exists public.whatsapp_messages;
drop table if exists public.whatsapp_connections;
drop table if exists public.patient_consents;

-- Funções criadas pela 0018 (o pre-flight provou que não existiam antes).
drop function if exists public.patient_consents_only_revoke();
drop function if exists public.touch_updated_at();

-- Índices únicos auxiliares (só podem cair depois das FKs compostas acima).
drop index if exists public.patients_id_owner_key;
drop index if exists public.appointments_id_owner_key;

-- Checks adicionados às tabelas antigas (não alteram nenhum dado).
alter table public.profiles drop constraint if exists profiles_timezone_valid;
alter table public.patients drop constraint if exists patients_phone_e164_format;
