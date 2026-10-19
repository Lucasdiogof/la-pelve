-- PRE-FLIGHT das migrations 0039 + 0040. SOMENTE LEITURA.
--   npx.cmd supabase db query -f supabase/rollout-0039/01_preflight_readonly.sql --linked --project-ref lchaboncmgcimafpupad
-- Esperado: todas PASS (as linhas INFO so mostram numeros).
with checks(item, esperado, atual) as (
  values
    ('01 delete_own_account existe (versao antiga)', 'true', (to_regprocedure('public.delete_own_account()') is not null)::text),
    ('02 objetos novos ainda nao existem', '0',
      ((to_regprocedure('public.check_account_deletion_allowed()') is not null)::int
       + (to_regprocedure('public.account_data_counts(uuid)') is not null)::int
       + (to_regprocedure('public.record_data_export(text, jsonb)') is not null)::int
       + (to_regclass('public.account_deletion_log') is not null)::int
       + (to_regclass('public.data_export_receipts') is not null)::int
       + (to_regclass('public.attachments_storage_path_idx') is not null)::int)::text),
    ('03 politica de Storage nova ainda nao existe', '0',
      (select count(*) from pg_policies where schemaname='storage' and tablename='objects'
         and policyname = 'Keep referenced attachment files')::text),
    ('04 colunas usadas pela contagem existem', '9',
      (select count(*) from information_schema.columns where table_schema='public' and (
         (table_name='patients' and column_name='fisioterapeuta_id') or
         (table_name='evolution_entries' and column_name='physiotherapist_id') or
         (table_name='appointments' and column_name='fisioterapeuta_id') or
         (table_name='financial_entries' and column_name='fisioterapeuta_id') or
         (table_name='attachments' and column_name in ('fisioterapeuta_id','storage_path')) or
         (table_name='patient_consents' and column_name='fisioterapeuta_id') or
         (table_name='whatsapp_messages' and column_name='fisioterapeuta_id') or
         (table_name='attachments' and column_name='id')))::text),
    ('05 existem politicas de Storage de anexos (a nova e restritiva e se soma a elas)', 'true',
      exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and cmd in ('ALL','DELETE'))::text),
    ('06 INFO usuarios com perfil', 'info', (select count(*) from public.profiles)::text),
    ('07 INFO arquivos no bucket de anexos sem linha em attachments (orfaos)', 'info',
      (select count(*) from storage.objects o where o.bucket_id = 'patient-attachments'
         and not exists (select 1 from public.attachments a where a.storage_path = o.name))::text),
    ('08 INFO linhas de attachments sem arquivo no bucket', 'info',
      (select count(*) from public.attachments a
         where not exists (select 1 from storage.objects o where o.bucket_id = 'patient-attachments' and o.name = a.storage_path))::text)
)
select item, esperado, atual,
       case when esperado = 'info' then 'INFO' when esperado = atual then 'PASS' else 'FAIL' end as resultado
from checks order by item;
