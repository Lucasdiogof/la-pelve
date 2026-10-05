-- PÓS-CHECK da 0023. SOMENTE LEITURA. Esperado: todas as linhas PASS.
-- Só roda DEPOIS da migration real ser aplicada.
--
--   npx.cmd supabase db query -f supabase/rollout-0023/04_postcheck_readonly.sql --linked --project-ref lchaboncmgcimafpupad

with checks(item, esperado, atual) as (
  values
    ('destination_phone_e164 existe (text, NOT NULL)', 'text/NO',
      coalesce((select data_type||'/'||is_nullable
        from information_schema.columns
        where table_schema='public' and table_name='whatsapp_messages' and column_name='destination_phone_e164'), 'ausente')),
    ('consent_id existe (uuid, NOT NULL)', 'uuid/NO',
      coalesce((select data_type||'/'||is_nullable
        from information_schema.columns
        where table_schema='public' and table_name='whatsapp_messages' and column_name='consent_id'), 'ausente')),
    ('CHECK de formato E.164 existe', 'true',
      (exists (select 1 from pg_constraint where conname='whatsapp_messages_destination_phone_e164_format'))::text),
    ('FK composta de consentimento existe', 'true',
      (exists (select 1 from pg_constraint where conname='whatsapp_messages_consent_owner_fkey'))::text),
    ('UNIQUE auxiliar patient_consents_id_owner_key existe', 'true',
      (exists (select 1 from pg_indexes where indexname='patient_consents_id_owner_key'))::text),
    ('trigger unico de validacao+imutabilidade ativo (BEFORE INSERT OR UPDATE)', '1',
      (select count(*) from pg_trigger where tgname='whatsapp_messages_validate_and_protect'
        and tgrelid='public.whatsapp_messages'::regclass and not tgisinternal)::text),
    ('trigger touch_updated_at ainda ativo (não duplicado/removido)', '1',
      (select count(*) from pg_trigger where tgname='whatsapp_messages_touch_updated_at'
        and tgrelid='public.whatsapp_messages'::regclass and not tgisinternal)::text),
    ('UNIQUE de idempotência original intacta', 'true',
      (exists (select 1 from pg_indexes where indexname='whatsapp_messages_one_per_appointment_revision'))::text),
    ('RLS de whatsapp_messages ligada (inalterada)', 'true',
      (select relrowsecurity from pg_class where oid='public.whatsapp_messages'::regclass)::text),
    ('authenticated continua sem INSERT/UPDATE/DELETE', '0',
      (select count(*) from information_schema.table_privileges
        where table_schema='public' and table_name='whatsapp_messages' and grantee='authenticated'
        and privilege_type in ('INSERT','UPDATE','DELETE'))::text),
    ('whatsapp_messages continua vazia (nenhum backfill fictício)', '0',
      (select count(*) from public.whatsapp_messages)::text)
)
select case when esperado = atual then 'PASS' else 'FAIL' end as resultado, item, esperado, atual from checks
union all
select case when bool_and(esperado = atual) then 'PASS' else 'FAIL' end, '99_geral', 'PASS',
  case when bool_and(esperado = atual) then 'PASS' else 'FAIL' end from checks
order by 2;
