-- PRE-FLIGHT da migration 0018 (WhatsApp foundation). SOMENTE LEITURA:
-- só SELECT, nada é criado nem alterado. Pode rodar quantas vezes quiser.
--
--   npx.cmd supabase db query -f supabase/rollout-0018/01_preflight_readonly.sql --linked --project-ref lchaboncmgcimafpupad
--
-- Saída: linhas (secao, item, valor). Interpretação no fim do arquivo.

select '01_contagem' as secao, t.name as item, t.n::text as valor from (
  select 'profiles' name, count(*) n from public.profiles
  union all select 'patients', count(*) from public.patients
  union all select 'appointments', count(*) from public.appointments
  union all select 'attachments', count(*) from public.attachments
  union all select 'evolution_entries', count(*) from public.evolution_entries
  union all select 'financial_entries', count(*) from public.financial_entries
) t

union all
-- Objetos que a 0018 cria e que NÃO podem existir ainda (esperado: 0 linhas).
select '02_colisao_relacao', n.nspname||'.'||c.relname||' ('||c.relkind::text||')', 'JA EXISTE'
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where c.relname in (
  'patient_consents','whatsapp_connections','whatsapp_messages',
  'patient_consents_pkey','patient_consents_fisioterapeuta_id_idx','patient_consents_patient_id_idx','patient_consents_one_active_key',
  'whatsapp_connections_pkey','whatsapp_connections_fisioterapeuta_id_key','whatsapp_connections_phone_number_id_key',
  'whatsapp_messages_pkey','whatsapp_messages_wamid_key','whatsapp_messages_one_per_appointment_type',
  'whatsapp_messages_fisioterapeuta_id_idx','whatsapp_messages_patient_id_idx','whatsapp_messages_due_idx',
  'patients_id_owner_key','appointments_id_owner_key')

union all
select '03_colisao_funcao', n.nspname||'.'||p.proname||'('||pg_get_function_identity_arguments(p.oid)||')', 'JA EXISTE'
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where p.proname in ('touch_updated_at','patient_consents_only_revoke')

union all
select '04_colisao_trigger', tgname||' on '||tgrelid::regclass, 'JA EXISTE'
from pg_trigger
where not tgisinternal and tgname in (
  'patient_consents_only_revoke','whatsapp_connections_touch_updated_at','whatsapp_messages_touch_updated_at')

union all
select '05_colisao_coluna', table_name||'.'||column_name, 'JA EXISTE'
from information_schema.columns
where table_schema = 'public'
  and ((table_name = 'profiles' and column_name = 'timezone')
    or (table_name = 'patients' and column_name = 'phone_e164'))

union all
select '06_colisao_constraint', conname||' on '||conrelid::regclass, 'JA EXISTE'
from pg_constraint
where conname in ('profiles_timezone_valid','patients_phone_e164_format','patient_consents_patient_owner_fkey',
  'patient_consents_revoked_after_granted','whatsapp_connections_status_valid','whatsapp_connections_connected_complete',
  'whatsapp_messages_patient_owner_fkey','whatsapp_messages_appointment_owner_fkey',
  'whatsapp_messages_reminder_type_valid','whatsapp_messages_status_valid','whatsapp_messages_one_per_appointment_type')

union all
select '07_colisao_policy', tablename||' / '||policyname, 'JA EXISTE'
from pg_policies
where policyname in ('Fisioterapeuta reads own consents','Fisioterapeuta inserts own consents','Fisioterapeuta revokes own consents',
  'Fisioterapeuta reads own whatsapp connection','Fisioterapeuta reads own whatsapp messages')

union all
-- Os dois índices únicos compostos: a unicidade de (id, fisioterapeuta_id) é
-- garantida pela PK em id; aqui provamos com os dados reais. Esperado: 0 e 0.
select '08_dup_patients_id_owner', 'linhas duplicadas', (count(*) - count(distinct (id, fisioterapeuta_id)))::text
from public.patients
union all
select '08_dup_appointments_id_owner', 'linhas duplicadas', (count(*) - count(distinct (id, fisioterapeuta_id)))::text
from public.appointments
union all
select '08_nulos_chave', 'patients/appointments com fisioterapeuta_id nulo',
  ((select count(*) from public.patients where fisioterapeuta_id is null)
 + (select count(*) from public.appointments where fisioterapeuta_id is null))::text

union all
-- profiles: o DEFAULT novo vale para linhas existentes e o CHECK de fuso
-- precisa aceitá-lo. Esperado: fuso_valido = true e nulos = 0 em NOT NULL.
select '09_default_timezone', 'America/Sao_Paulo existe em pg_timezone_names',
  exists (select 1 from pg_timezone_names where name = 'America/Sao_Paulo')::text
union all
select '09_default_timezone', 'timezone() aceita o default (mesma expressao do CHECK)',
  (timezone('America/Sao_Paulo', timestamp '2000-01-01 00:00:00') is not null)::text
union all
select '09_default_timezone', 'profiles existentes que receberao o default', count(*)::text from public.profiles

union all
-- Dependências da migration no banco real.
select '10_ambiente', 'versao do postgres', current_setting('server_version')
union all
select '10_ambiente', 'gen_random_uuid() disponivel',
  exists (select 1 from pg_proc where proname = 'gen_random_uuid')::text
union all
select '10_ambiente', 'auth.uid() disponivel',
  exists (select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='auth' and p.proname='uid')::text
union all
select '10_ambiente', 'roles anon/authenticated/service_role',
  (select count(*) from pg_roles where rolname in ('anon','authenticated','service_role'))::text||' de 3'
union all
select '10_ambiente', 'RLS ligada nas 6 tabelas existentes',
  (select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relrowsecurity
      and c.relname in ('profiles','patients','appointments','attachments','evolution_entries','financial_entries'))::text||' de 6'

union all
-- Risco de bloqueio: transações/consultas ativas agora (fora esta).
select '11_atividade', coalesce(state,'?')||' / '||coalesce(wait_event_type,'-'), count(*)::text
from pg_stat_activity
where datname = current_database() and pid <> pg_backend_pid() and backend_type = 'client backend'
group by 1, 2

union all
select '12_tamanho', c.relname, pg_size_pretty(pg_total_relation_size(c.oid))
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind='r'
  and c.relname in ('profiles','patients','appointments')
order by 1, 2;

-- INTERPRETAÇÃO
--  02..07: precisam retornar ZERO linhas. Qualquer linha = colisão de nome.
--  08: os dois valores de duplicadas = 0 e nulos = 0.
--  09: as duas primeiras = true.
--  10: gen_random_uuid e auth.uid = true; roles = 3 de 3; RLS = 6 de 6.
--  11: idealmente nada em 'idle in transaction'.
