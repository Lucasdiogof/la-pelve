-- READ-ONLY. Validacao antes da primeira chamada ao dispatcher. Sem valores sensiveis.
with p as (select * from public.patients where id='e2e-wa-patient-20261009'),
     c as (select * from public.patient_consents where patient_id='e2e-wa-patient-20261009' and revoked_at is null),
     a as (select *, ((date + time) at time zone 'America/Sao_Paulo') as start_utc from public.appointments where id='e2e-wa-appt-20261009')
select 'patient' k, jsonb_build_object('id',p.id,'owner_ok',p.fisioterapeuta_id='4f8bfc70-9e28-4a0a-b5df-ec1ae1560d56','name',p.name,'phone',p.phone,'phone_e164',p.phone_e164,'e164_ok',p.phone_e164='+5562982795032','deleted_at',p.deleted_at) v from p
union all select 'consent', jsonb_build_object('id',c.id,'channel',c.channel,'purpose',c.purpose,'contact_value',c.contact_value,'revoked_at',c.revoked_at,'granted_at',c.granted_at,
   'matches_phone_e164',(select p.phone_e164=c.contact_value from p)) from c
union all select 'appointment', jsonb_build_object('id',a.id,'patient_id',a.patient_id,'patient_ok',a.patient_id='e2e-wa-patient-20261009','status',a.status,'schedule_revision',a.schedule_revision,
   'date',a.date,'time',a.time,'created_at',a.created_at,'schedule_revision_at',a.schedule_revision_at,'start_utc',a.start_utc) from a
union all select 'eligibility_12h', jsonb_build_object(
   'notice_hours', round(extract(epoch from (a.start_utc - a.schedule_revision_at))/3600, 2),
   'notice_gt_12h', (a.start_utc - a.schedule_revision_at) > interval '12 hours',
   'scheduled_for_utc', (a.start_utc - interval '12 hours'),
   'scheduled_for_sp', ((a.start_utc - interval '12 hours') at time zone 'America/Sao_Paulo'),
   'in_silence', (extract(hour from ((a.start_utc - interval '12 hours') at time zone 'America/Sao_Paulo')) >= 22 or extract(hour from ((a.start_utc - interval '12 hours') at time zone 'America/Sao_Paulo')) < 7),
   'gap_after_creation_hours', round(extract(epoch from ((a.start_utc - interval '12 hours') - a.schedule_revision_at))/3600, 2),
   'gap_ge_2h', ((a.start_utc - interval '12 hours') - a.schedule_revision_at) >= interval '2 hours',
   'materialize_from_utc', (a.start_utc - interval '13 hours')) from a
union all select 'connection', (select jsonb_build_object('id',id,'status',status,'phone_number_id',phone_number_id) from public.whatsapp_connections where fisioterapeuta_id='4f8bfc70-9e28-4a0a-b5df-ec1ae1560d56')
union all select 'credential', (select jsonb_build_object('connection_id',cr.connection_id,'vault_secret_id',cr.vault_secret_id,'secret_exists',exists(select 1 from vault.secrets s where s.id=cr.vault_secret_id)) from public.whatsapp_connection_credentials cr)
union all select 'counts', jsonb_build_object('connections',(select count(*) from public.whatsapp_connections),'credentials',(select count(*) from public.whatsapp_connection_credentials),
   'vault_secrets',(select count(*) from vault.secrets),'messages',(select count(*) from public.whatsapp_messages),
   'patients',(select count(*) from public.patients where fisioterapeuta_id='4f8bfc70-9e28-4a0a-b5df-ec1ae1560d56'),
   'consents',(select count(*) from public.patient_consents),'appointments',(select count(*) from public.appointments))
union all select 'now_sp', jsonb_build_object('now_sp', now() at time zone 'America/Sao_Paulo');
