-- POS-CHECK da 0039. SOMENTE LEITURA. Esperado: todas PASS.
--   npx.cmd supabase db query -f supabase/rollout-0039/04_postcheck_readonly.sql --linked --project-ref lchaboncmgcimafpupad
with checks(item, esperado, atual) as (
  values
    ('01 confirm_clinical_data_custody existe', 'true', (to_regprocedure('public.confirm_clinical_data_custody(text)') is not null)::text),
    ('02 check_account_deletion_allowed existe', 'true', (to_regprocedure('public.check_account_deletion_allowed()') is not null)::text),
    ('03 delete_own_account chama a trava', 'true',
      coalesce((select position('check_account_deletion_allowed' in pg_get_functiondef(p.oid)) > 0
                from pg_proc p where p.oid = to_regprocedure('public.delete_own_account()')), false)::text),
    ('04 anon sem EXECUTE em delete_own_account', 'false', has_function_privilege('anon', 'public.delete_own_account()', 'execute')::text),
    ('05 anon sem EXECUTE em confirm_clinical_data_custody', 'false', has_function_privilege('anon', 'public.confirm_clinical_data_custody(text)', 'execute')::text),
    ('06 anon sem EXECUTE em check_account_deletion_allowed', 'false', has_function_privilege('anon', 'public.check_account_deletion_allowed()', 'execute')::text),
    ('07 authenticated com EXECUTE nas tres', 'true',
      (has_function_privilege('authenticated', 'public.delete_own_account()', 'execute')
       and has_function_privilege('authenticated', 'public.confirm_clinical_data_custody(text)', 'execute')
       and has_function_privilege('authenticated', 'public.check_account_deletion_allowed()', 'execute'))::text),
    ('08 colunas de custodia criadas', '2',
      (select count(*) from information_schema.columns where table_schema='public' and table_name='profiles'
         and column_name in ('custody_confirmed_at','custody_confirmed_method'))::text),
    ('10 account_deletion_log existe com RLS e sem acesso do app', 'true',
      (to_regclass('public.account_deletion_log') is not null
       and coalesce((select relrowsecurity from pg_class where oid = to_regclass('public.account_deletion_log')), false)
       and not has_table_privilege('authenticated', 'public.account_deletion_log', 'select')
       and not has_table_privilege('anon', 'public.account_deletion_log', 'select'))::text),
    ('11 delete_own_account grava o log', 'true',
      coalesce((select position('account_deletion_log' in pg_get_functiondef(p.oid)) > 0
                from pg_proc p where p.oid = to_regprocedure('public.delete_own_account()')), false)::text),
    ('09 nenhuma custodia pre-preenchida (a migration nao altera dados)', '0',
      (select count(*) from public.profiles where custody_confirmed_at is not null)::text)
)
select item, esperado, atual, case when esperado = atual then 'PASS' else 'FAIL' end as resultado
from checks order by item;
