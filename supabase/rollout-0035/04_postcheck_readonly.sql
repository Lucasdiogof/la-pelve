-- PÓS-CHECK da 0035. SOMENTE LEITURA. Esperado: todas PASS.
with checks(item, esperado, atual) as (
  values
    ('01 funcao existe', 'true', (to_regprocedure('public.flag_whatsapp_connection_token_invalid(uuid,text)') is not null)::text),
    ('02 security definer com search_path vazio', 'true',
      coalesce((select p.prosecdef and 'search_path=""' = any (p.proconfig)
                from pg_proc p where p.oid = to_regprocedure('public.flag_whatsapp_connection_token_invalid(uuid,text)')), false)::text),
    ('03 anon sem EXECUTE', 'false', has_function_privilege('anon', 'public.flag_whatsapp_connection_token_invalid(uuid,text)', 'execute')::text),
    ('04 authenticated sem EXECUTE', 'false', has_function_privilege('authenticated', 'public.flag_whatsapp_connection_token_invalid(uuid,text)', 'execute')::text),
    ('05 service_role com EXECUTE', 'true', has_function_privilege('service_role', 'public.flag_whatsapp_connection_token_invalid(uuid,text)', 'execute')::text),
    ('06 nenhuma conexao foi alterada para token_invalid', '0',
      (select count(*) from public.whatsapp_connections where last_error->>'code' = 'token_invalid')::text)
)
select item, esperado, atual, case when esperado = atual then 'PASS' else 'FAIL' end as resultado
from checks order by item;
