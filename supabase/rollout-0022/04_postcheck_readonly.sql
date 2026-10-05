-- PÓS-CHECK da 0022. SOMENTE LEITURA. Esperado: todas as linhas PASS.
--
--   npx.cmd supabase db query -f supabase/rollout-0022/04_postcheck_readonly.sql --linked --project-ref lchaboncmgcimafpupad

with checks(item, esperado, atual) as (
  values
    ('funcao protege created_at no INSERT (creation_time) e no UPDATE (old.created_at)', 'true',
      (select
        position('creation_time' in def) > 0
        and position('new.created_at' in def) > 0
        and position('old.created_at' in def) > 0
      from (select pg_get_functiondef(p.oid) as def
        from pg_proc p join pg_namespace n on n.oid=p.pronamespace
        where n.nspname='public' and p.proname='set_appointment_schedule_revision') f)::text),
    ('todos em schedule_revision 0 continuam com schedule_revision_at == created_at', '0',
      (select count(*) from public.appointments where schedule_revision = 0 and schedule_revision_at is distinct from created_at)::text),
    ('nenhum created_at nulo', '0',
      (select count(*) from public.appointments where created_at is null)::text),
    ('trigger appointments_set_schedule_revision continua unico e ativo', '1',
      (select count(*) from pg_trigger where tgrelid='public.appointments'::regclass and not tgisinternal)::text),
    ('whatsapp_messages continua vazia', '0',
      (select count(*) from public.whatsapp_messages)::text),
    ('RLS de appointments ligada (inalterada)', 'true',
      (select relrowsecurity from pg_class where oid='public.appointments'::regclass)::text)
)
select case when esperado = atual then 'PASS' else 'FAIL' end as resultado, item, esperado, atual from checks
union all
select case when bool_and(esperado = atual) then 'PASS' else 'FAIL' end, '99_geral', 'PASS',
  case when bool_and(esperado = atual) then 'PASS' else 'FAIL' end from checks
union all
select 'info', '00_total_appointments_atual', '(informativo, nao compara com baseline)', (select count(*)::text from public.appointments)
order by 2;
