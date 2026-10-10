-- ESCRITA (paciente + consentimento + consulta de TESTE do E2E appointment_12h).
-- Atomico (um bloco DO): se qualquer guarda falhar, NADA e gravado. Idempotente por id.
-- Nao toca em whatsapp_messages, conexao, Vault, scheduler nem cron.
do $$
declare
  fisio constant uuid := '4f8bfc70-9e28-4a0a-b5df-ec1ae1560d56';
  pid   constant text := 'e2e-wa-patient-20261009';
  aid   constant text := 'e2e-wa-appt-20261009';
  e164  constant text := '+5562982795032';
  sp_now timestamp := now() at time zone 'America/Sao_Paulo';
begin
  -- Guarda de horario: consulta 10/10 09:00 BRT. Precisa ser criada hoje (09/10) ate 18:50 BRT
  -- para a antecedencia ser > 12h e o envio das 21:00 ficar >= 2h depois da criacao.
  if sp_now::date <> date '2026-10-09' or sp_now::time > time '18:50' then
    raise exception 'fora da janela do cenario B (agora em SP: %). Recalcular horario da consulta.', sp_now;
  end if;
  if not exists (select 1 from public.whatsapp_connections where fisioterapeuta_id = fisio and status = 'connected') then
    raise exception 'conexao nao esta connected';
  end if;
  if exists (select 1 from public.patients where id = pid and fisioterapeuta_id <> fisio) then
    raise exception 'id de paciente de teste ja existe para outro fisioterapeuta';
  end if;

  insert into public.patients (id, fisioterapeuta_id, name, phone, phone_e164)
  values (pid, fisio, 'Teste WhatsApp E2E', '(62) 98279-5032', e164)
  on conflict (id) do nothing;

  insert into public.patient_consents (fisioterapeuta_id, patient_id, channel, purpose, contact_value, source)
  select fisio, pid, 'whatsapp', 'appointment_reminder', e164, 'e2e_test'
  where not exists (select 1 from public.patient_consents
                    where patient_id = pid and channel = 'whatsapp' and purpose = 'appointment_reminder' and revoked_at is null);

  insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status, patient_id)
  values (aid, fisio, date '2026-10-10', time '09:00', 'Teste WhatsApp E2E', 'scheduled', pid)
  on conflict (id) do nothing;
end $$;
select 'written' as result;
