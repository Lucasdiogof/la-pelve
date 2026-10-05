-- PÓS-CHECK (v2) da 0020. SOMENTE LEITURA. Esperado: todas as linhas PASS.
-- Só roda DEPOIS da migration real ser aplicada (algumas linhas referenciam
-- a coluna schedule_revision diretamente — rodar antes dá erro de SQL, não
-- FAIL; isso é esperado e não indica problema na migration).
--
--   npx.cmd supabase db query -f supabase/rollout-0020/03_postcheck_readonly.sql --linked --project-ref lchaboncmgcimafpupad

with checks(item, esperado, atual) as (
  values
    ('reminder_type aceita os 3 tipos', 'CHECK ((reminder_type = ANY (ARRAY[''appointment_confirmation''::text, ''appointment_12h''::text, ''appointment_rescheduled''::text])))',
      coalesce((select pg_get_constraintdef(oid) from pg_constraint
        where conrelid = 'public.whatsapp_messages'::regclass
        and conname = 'whatsapp_messages_reminder_type_valid'), 'ausente')),
    ('whatsapp_messages.schedule_revision existe (integer, NOT NULL, default 0)', 'integer/NO/0',
      coalesce((select data_type||'/'||is_nullable||'/'||regexp_replace(column_default, '::.*', '')
        from information_schema.columns
        where table_schema='public' and table_name='whatsapp_messages' and column_name='schedule_revision'), 'ausente')),
    ('appointments.schedule_revision existe (integer, NOT NULL, default 0)', 'integer/NO/0',
      coalesce((select data_type||'/'||is_nullable||'/'||regexp_replace(column_default, '::.*', '')
        from information_schema.columns
        where table_schema='public' and table_name='appointments' and column_name='schedule_revision'), 'ausente')),
    ('event_key NAO existe (estrategia removida)', 'false',
      (exists (select 1 from information_schema.columns
        where table_schema='public' and table_name='whatsapp_messages' and column_name='event_key'))::text),
    ('check nao-negativo em whatsapp_messages existe', '1',
      (select count(*) from pg_constraint where conname='whatsapp_messages_schedule_revision_non_negative'
        and conrelid='public.whatsapp_messages'::regclass)::text),
    ('check nao-negativo em appointments existe', '1',
      (select count(*) from pg_constraint where conname='appointments_schedule_revision_non_negative'
        and conrelid='public.appointments'::regclass)::text),
    ('check de coerencia tipo<->revisao existe', '1',
      (select count(*) from pg_constraint where conname='whatsapp_messages_schedule_revision_matches_type'
        and conrelid='public.whatsapp_messages'::regclass)::text),
    ('UNIQUE nova (3 colunas) existe', '1',
      (select count(*) from pg_constraint where conname='whatsapp_messages_one_per_appointment_revision'
        and conrelid='public.whatsapp_messages'::regclass)::text),
    ('UNIQUE antiga (2 colunas) nao existe mais', '0',
      (select count(*) from pg_constraint where conname='whatsapp_messages_one_per_appointment_type'
        and conrelid='public.whatsapp_messages'::regclass)::text),
    ('trigger de schedule_revision existe em appointments', '1',
      (select count(*) from pg_trigger where tgname='appointments_set_schedule_revision'
        and tgrelid='public.appointments'::regclass and not tgisinternal)::text),
    ('funcao do trigger existe', '1',
      (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
        where n.nspname='public' and p.proname='set_appointment_schedule_revision')::text),
    ('indices antigos de whatsapp_messages intactos (pkey, wamid, fisio, patient, due)', '5',
      (select count(*) from pg_indexes where schemaname='public' and tablename='whatsapp_messages'
        and indexname in (
          'whatsapp_messages_pkey', 'whatsapp_messages_wamid_key',
          'whatsapp_messages_fisioterapeuta_id_idx', 'whatsapp_messages_patient_id_idx',
          'whatsapp_messages_due_idx'
        ))::text),
    ('whatsapp_messages continua vazia (nenhum DML nesta migration)', '0',
      (select count(*) from public.whatsapp_messages)::text),
    ('appointments mantem 65 linhas (nenhuma perdida/criada)', '65',
      (select count(*) from public.appointments)::text),
    ('todos os 65 appointments existentes estao em revision 0', '65',
      (select count(*) from public.appointments where schedule_revision = 0)::text),
    ('RLS de whatsapp_messages ligada (inalterada)', 'true',
      (select relrowsecurity from pg_class where oid='public.whatsapp_messages'::regclass)::text),
    ('RLS de appointments ligada (inalterada)', 'true',
      (select relrowsecurity from pg_class where oid='public.appointments'::regclass)::text)
)
select case when esperado = atual then 'PASS' else 'FAIL' end as resultado, item, esperado, atual from checks
union all
select case when bool_and(esperado = atual) then 'PASS' else 'FAIL' end, '99_geral', 'PASS',
  case when bool_and(esperado = atual) then 'PASS' else 'FAIL' end from checks
order by 2;
