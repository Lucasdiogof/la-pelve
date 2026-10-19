-- POS-CHECK da 0039 + 0040. SOMENTE LEITURA. Esperado: todas PASS (a linha 10 e informativa).
--   npx.cmd supabase db query -f supabase/rollout-0039/04_postcheck_readonly.sql --linked --project-ref lchaboncmgcimafpupad
with checks(item, esperado, atual) as (
  values
    ('01 account_data_counts existe e nao e chamavel pelo app', 'true',
      (to_regprocedure('public.account_data_counts(uuid)') is not null
       and not has_function_privilege('authenticated', 'public.account_data_counts(uuid)', 'execute')
       and not has_function_privilege('anon', 'public.account_data_counts(uuid)', 'execute'))::text),
    ('02 assert_account_empty existe e nao e chamavel pelo app', 'true',
      (to_regprocedure('public.assert_account_empty(uuid)') is not null
       and not has_function_privilege('authenticated', 'public.assert_account_empty(uuid)', 'execute'))::text),
    ('03 check_account_deletion_allowed e record_data_export para authenticated, nao anon', 'true',
      (has_function_privilege('authenticated', 'public.check_account_deletion_allowed()', 'execute')
       and has_function_privilege('authenticated', 'public.record_data_export(text, jsonb)', 'execute')
       and not has_function_privilege('anon', 'public.check_account_deletion_allowed()', 'execute')
       and not has_function_privilege('anon', 'public.record_data_export(text, jsonb)', 'execute'))::text),
    ('04 delete_own_account usa a trava e grava o log', 'true',
      coalesce((select position('assert_account_empty' in pg_get_functiondef(p.oid)) > 0
                  and position('account_deletion_log' in pg_get_functiondef(p.oid)) > 0
                  and position('for update' in lower(pg_get_functiondef(p.oid))) > 0
                from pg_proc p where p.oid = to_regprocedure('public.delete_own_account()')), false)::text),
    ('05 delete_own_account: anon sem EXECUTE, authenticated com EXECUTE', 'true',
      (not has_function_privilege('anon', 'public.delete_own_account()', 'execute')
       and has_function_privilege('authenticated', 'public.delete_own_account()', 'execute'))::text),
    ('06 log e recibos com RLS e sem acesso do app', 'true',
      (to_regclass('public.account_deletion_log') is not null and to_regclass('public.data_export_receipts') is not null
       and coalesce((select bool_and(relrowsecurity) from pg_class
                      where oid in (to_regclass('public.account_deletion_log'), to_regclass('public.data_export_receipts'))), false)
       and not has_table_privilege('authenticated', 'public.account_deletion_log', 'select')
       and not has_table_privilege('anon', 'public.account_deletion_log', 'select')
       and not has_table_privilege('authenticated', 'public.data_export_receipts', 'select')
       and not has_table_privilege('anon', 'public.data_export_receipts', 'select'))::text),
    ('07 politica de Storage que protege anexos referenciados existe', 'true',
      exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects'
                and policyname = 'Keep referenced attachment files' and permissive = 'RESTRICTIVE' and cmd = 'DELETE')::text),
    ('08 indice de attachments.storage_path existe', 'true',
      (to_regclass('public.attachments_storage_path_idx') is not null)::text),
    ('09 nenhuma coluna de custodia criada em profiles (desenho antigo nao e usado)', '0',
      (select count(*) from information_schema.columns where table_schema='public' and table_name='profiles'
         and column_name like 'custody%')::text),
    ('10 a migration nao alterou dados: log e recibos vazios antes do uso', 'info', 'info')
)
select item, esperado, atual,
       case when esperado = 'info' then 'INFO' when esperado = atual then 'PASS' else 'FAIL' end as resultado
from checks order by item;
