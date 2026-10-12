drop function if exists public.whatsapp_health_summary(integer);
select to_regprocedure('public.whatsapp_health_summary(integer)') is null as removida;
