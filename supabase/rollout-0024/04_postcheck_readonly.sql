-- PÓS-CHECK da 0024. SOMENTE LEITURA. Esperado: todas as linhas PASS.
--
--   npx.cmd supabase db query -f supabase/rollout-0024/04_postcheck_readonly.sql --linked --project-ref lchaboncmgcimafpupad

with checks(item, esperado, atual) as (
  values
    ('funcao contem o SQLSTATE customizado WA001', 'true',
      (position('WA001' in (select pg_get_functiondef(oid) from pg_proc where proname='whatsapp_messages_validate_and_protect')) > 0)::text),
    ('funcao ainda contem FOR SHARE (nao removido por engano)', 'true',
      (position('for share' in (select pg_get_functiondef(oid) from pg_proc where proname='whatsapp_messages_validate_and_protect')) > 0)::text),
    ('trigger unico continua BEFORE INSERT OR UPDATE', '1',
      (select count(*) from pg_trigger where tgname='whatsapp_messages_validate_and_protect'
        and tgrelid='public.whatsapp_messages'::regclass and not tgisinternal)::text),
    ('trigger touch_updated_at ainda ativo (nao duplicado/removido)', '1',
      (select count(*) from pg_trigger where tgname='whatsapp_messages_touch_updated_at'
        and tgrelid='public.whatsapp_messages'::regclass and not tgisinternal)::text),
    ('exatamente 2 triggers em whatsapp_messages', '2',
      (select count(*) from pg_trigger where tgrelid='public.whatsapp_messages'::regclass and not tgisinternal)::text),
    ('whatsapp_messages continua vazia (nenhum dado alterado)', '0',
      (select count(*) from public.whatsapp_messages)::text),
    ('UNIQUE de idempotencia original intacta', 'true',
      (exists (select 1 from pg_indexes where indexname='whatsapp_messages_one_per_appointment_revision'))::text),
    ('FK composta de consentimento intacta', 'true',
      (exists (select 1 from pg_constraint where conname='whatsapp_messages_consent_owner_fkey'))::text)
)
select case when esperado = atual then 'PASS' else 'FAIL' end as resultado, item, esperado, atual from checks
union all
select case when bool_and(esperado = atual) then 'PASS' else 'FAIL' end, '99_geral', 'PASS',
  case when bool_and(esperado = atual) then 'PASS' else 'FAIL' end from checks
order by 2;
