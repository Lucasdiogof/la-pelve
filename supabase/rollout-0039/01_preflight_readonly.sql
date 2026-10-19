-- PRE-FLIGHT da migration 0039 (trava de custodia na exclusao de conta). SOMENTE LEITURA.
--   npx.cmd supabase db query -f supabase/rollout-0039/01_preflight_readonly.sql --linked --project-ref lchaboncmgcimafpupad
-- Esperado: todas PASS.
with checks(item, esperado, atual) as (
  values
    ('01 delete_own_account existe (versao antiga)', 'true',
      (to_regprocedure('public.delete_own_account()') is not null)::text),
    ('02 funcoes novas ainda nao existem', 'false',
      (to_regprocedure('public.confirm_clinical_data_custody(text)') is not null
        or to_regprocedure('public.check_account_deletion_allowed()') is not null)::text),
    ('03 colunas novas ainda nao existem em profiles', '0',
      (select count(*) from information_schema.columns where table_schema='public' and table_name='profiles'
         and column_name in ('custody_confirmed_at','custody_confirmed_method'))::text),
    ('04 evolution_entries usa physiotherapist_id', 'true',
      exists (select 1 from information_schema.columns where table_schema='public'
              and table_name='evolution_entries' and column_name='physiotherapist_id')::text),
    ('05 patients e attachments usam fisioterapeuta_id', '2',
      (select count(*) from information_schema.columns where table_schema='public'
         and table_name in ('patients','attachments') and column_name='fisioterapeuta_id')::text),
    ('05b account_deletion_log ainda nao existe', 'false', (to_regclass('public.account_deletion_log') is not null)::text),
    ('05c appointments e financial_entries usam fisioterapeuta_id', '2',
      (select count(*) from information_schema.columns where table_schema='public'
         and table_name in ('appointments','financial_entries') and column_name='fisioterapeuta_id')::text),
    ('06 profiles tem a linha de cada usuario (contagem so informativa, nao e PASS/FAIL)', 'info',
      'info')
)
select item, esperado, atual,
       case when esperado = 'info' then 'INFO' when esperado = atual then 'PASS' else 'FAIL' end as resultado
from checks order by item;
