-- SNAPSHOT dos dados existentes ANTES da 0018. SOMENTE LEITURA.
-- Gera, para as 6 tabelas anteriores: contagem e uma impressão digital (md5)
-- calculada só sobre as colunas que JÁ existem hoje (as colunas novas da 0018,
-- profiles.timezone e patients.phone_e164, ficam de fora de propósito).
-- Também lista 5 pacientes e 5 agendamentos (id + md5 da linha), sem expor
-- nenhum dado clínico no resultado.
--
-- Os mesmos SELECTs rodam no pós-check (03_postcheck.sql, gerado por
-- make_postcheck.mjs a partir deste snapshot).

select 'count' as kind, 'profiles' as k, count(*)::text as v from public.profiles
union all select 'count', 'patients', count(*)::text from public.patients
union all select 'count', 'appointments', count(*)::text from public.appointments
union all select 'count', 'attachments', count(*)::text from public.attachments
union all select 'count', 'evolution_entries', count(*)::text from public.evolution_entries
union all select 'count', 'financial_entries', count(*)::text from public.financial_entries

union all select 'hash', 'profiles', coalesce(md5(string_agg(h, '' order by id)), 'vazio') from (
  select id::text id, md5(row(id, name, crefito, phone, email, created_at, photo_path)::text) h from public.profiles) x
union all select 'hash', 'patients', coalesce(md5(string_agg(h, '' order by id)), 'vazio') from (
  select id, md5(row(id, fisioterapeuta_id, created_at, name, age, phone, occupation, medical_history,
    gynecological_history, obstetric_history, surgical_history, urinary_function, sexual_function,
    bowel_function, consultation_fee, gender, deleted_at, treatment_plan, discharge, social_name)::text) h
  from public.patients) x
union all select 'hash', 'appointments', coalesce(md5(string_agg(h, '' order by id)), 'vazio') from (
  select id, md5(row(id, fisioterapeuta_id, date, time, patient_name, created_at, status, patient_id)::text) h
  from public.appointments) x
union all select 'hash', 'attachments', coalesce(md5(string_agg(h, '' order by id)), 'vazio') from (
  select id, md5(a::text) h from public.attachments a) x
union all select 'hash', 'evolution_entries', coalesce(md5(string_agg(h, '' order by id)), 'vazio') from (
  select id, md5(e::text) h from public.evolution_entries e) x
union all select 'hash', 'financial_entries', coalesce(md5(string_agg(h, '' order by id)), 'vazio') from (
  select id, md5(f::text) h from public.financial_entries f) x

union all select 'sample_patients', id, md5(row(id, fisioterapeuta_id, created_at, name, age, phone, occupation,
    medical_history, gynecological_history, obstetric_history, surgical_history, urinary_function,
    sexual_function, bowel_function, consultation_fee, gender, deleted_at, treatment_plan, discharge,
    social_name)::text)
  from (select * from public.patients order by id limit 5) p
union all select 'sample_appointments', id, md5(row(id, fisioterapeuta_id, date, time, patient_name,
    created_at, status, patient_id)::text)
  from (select * from public.appointments order by id limit 5) a
order by 1, 2;
