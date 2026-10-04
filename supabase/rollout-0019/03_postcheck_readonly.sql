-- PÓS-CHECK da 0019. SOMENTE LEITURA. Esperado: todas as linhas PASS.
--
--   npx.cmd supabase db query -f supabase/rollout-0019/03_postcheck_readonly.sql --linked --project-ref lchaboncmgcimafpupad

with checks(item, esperado, atual) as (
  values
    ('contact_value existe (text, NOT NULL)', 'text/NO',
      coalesce((select data_type||'/'||is_nullable from information_schema.columns
        where table_schema='public' and table_name='patient_consents' and column_name='contact_value'), 'ausente')),
    ('constraint E.164 criada', '1',
      (select count(*) from pg_constraint where conname='patient_consents_contact_value_e164'
        and conrelid='public.patient_consents'::regclass)::text),
    ('trigger ativo', 'true',
      exists (select 1 from pg_trigger where tgname='patient_consents_only_revoke' and not tgisinternal)::text),
    ('trigger protege contact_value', 'true',
      (select position('contact_value' in prosrc) > 0 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
        where n.nspname='public' and p.proname='patient_consents_only_revoke')::text),
    ('app so atualiza revoked_at', 'revoked_at',
      coalesce((select string_agg(column_name, ',') from information_schema.column_privileges
        where table_schema='public' and table_name='patient_consents' and grantee='authenticated' and privilege_type='UPDATE'), 'nenhum')),
    ('RLS ligada', 'true',
      (select relrowsecurity from pg_class where oid='public.patient_consents'::regclass)::text),
    ('patient_consents continua vazia', '0', (select count(*) from public.patient_consents)::text),
    ('whatsapp_connections/messages intactas (linhas)', '0',
      ((select count(*) from public.whatsapp_connections) + (select count(*) from public.whatsapp_messages))::text)
)
select case when esperado = atual then 'PASS' else 'FAIL' end as resultado, item, esperado, atual from checks
union all
select case when bool_and(esperado = atual) then 'PASS' else 'FAIL' end, '99_geral', 'PASS',
  case when bool_and(esperado = atual) then 'PASS' else 'FAIL' end from checks
order by 2;
