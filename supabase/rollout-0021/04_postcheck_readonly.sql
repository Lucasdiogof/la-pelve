-- PÓS-CHECK da 0021. SOMENTE LEITURA. Esperado: todas as linhas PASS.
-- Só roda DEPOIS da migration real ser aplicada (uma das linhas referencia
-- a coluna schedule_revision_at diretamente — rodar antes dá erro de SQL,
-- não FAIL; isso é esperado).
--
--   npx.cmd supabase db query -f supabase/rollout-0021/04_postcheck_readonly.sql --linked --project-ref lchaboncmgcimafpupad

with checks(item, esperado, atual) as (
  values
    ('schedule_revision_at existe (timestamptz, NOT NULL, default now())', 'timestamp with time zone/NO/now()',
      coalesce((select data_type||'/'||is_nullable||'/'||regexp_replace(column_default, '\(\)$', '()')
        from information_schema.columns
        where table_schema='public' and table_name='appointments' and column_name='schedule_revision_at'), 'ausente')),
    ('appointments mantem 65 linhas', '65',
      (select count(*) from public.appointments)::text),
    ('todos os 65 continuam em schedule_revision 0', '65',
      (select count(*) from public.appointments where schedule_revision = 0)::text),
    ('todos os schedule_revision_at == created_at (revision 0)', '0',
      (select count(*) from public.appointments where schedule_revision_at <> created_at)::text),
    ('nenhum schedule_revision_at nulo', '0',
      (select count(*) from public.appointments where schedule_revision_at is null)::text),
    ('funcao do trigger existe e menciona schedule_revision_at', 'true',
      (select position('schedule_revision_at' in pg_get_functiondef(p.oid)) > 0
        from pg_proc p join pg_namespace n on n.oid=p.pronamespace
        where n.nspname='public' and p.proname='set_appointment_schedule_revision')::text),
    ('trigger appointments_set_schedule_revision continua ativo', '1',
      (select count(*) from pg_trigger where tgname='appointments_set_schedule_revision'
        and tgrelid='public.appointments'::regclass and not tgisinternal)::text),
    ('whatsapp_messages continua vazia', '0',
      (select count(*) from public.whatsapp_messages)::text),
    ('RLS de appointments ligada (inalterada)', 'true',
      (select relrowsecurity from pg_class where oid='public.appointments'::regclass)::text)
)
select case when esperado = atual then 'PASS' else 'FAIL' end as resultado, item, esperado, atual from checks
union all
select case when bool_and(esperado = atual) then 'PASS' else 'FAIL' end, '99_geral', 'PASS',
  case when bool_and(esperado = atual) then 'PASS' else 'FAIL' end from checks
order by 2;
