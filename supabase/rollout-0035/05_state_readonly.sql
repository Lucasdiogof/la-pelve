-- READ-ONLY: confirma que nada ficou do dry-run.
select to_regprocedure('public.flag_whatsapp_connection_token_invalid(uuid,text)') is null as funcao_ausente,
       (select count(*) from auth.users where email like '%@teste.local') as usuarios_teste,
       (select count(*) from public.whatsapp_connections) as conexoes,
       (select count(*) from vault.secrets) as segredos;
