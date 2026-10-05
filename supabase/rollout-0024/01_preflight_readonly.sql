-- PRE-FLIGHT da migration 0024 (SQLSTATE customizado para rejeição de
-- consentimento). SOMENTE LEITURA. Não aplica nada.
--
--   npx.cmd supabase db query -f supabase/rollout-0024/01_preflight_readonly.sql --linked --project-ref lchaboncmgcimafpupad
--
-- Esperado: todas as linhas PASS. Se 02 falhar, a função em produção NÃO
-- é a da 0023 (alguém a alterou fora do repo) -- PARE e investigue antes
-- de substituí-la, senão a 0024 apagaria uma mudança desconhecida.

with checks(item, esperado, atual) as (
  values
    ('01 whatsapp_messages continua vazia', '0',
      (select count(*) from public.whatsapp_messages)::text),

    -- Corpo EXATO da função criada pela 0023 (copiado byte a byte do
    -- arquivo da migration; CR removido por segurança caso algum cliente
    -- tenha enviado CRLF).
    ('02 corpo da funcao identico ao da 0023', 'true',
      ((select replace(prosrc, E'\r', '') from pg_proc
        where proname = 'whatsapp_messages_validate_and_protect'
          and pronamespace = 'public'::regnamespace) = $f0023$
begin
  if tg_op = 'INSERT' then
    if not exists (
      select 1 from public.patient_consents
      where id = new.consent_id
        and patient_id = new.patient_id
        and fisioterapeuta_id = new.fisioterapeuta_id
        and channel = 'whatsapp'
        and purpose = 'appointment_reminder'
        and revoked_at is null
        and contact_value = new.destination_phone_e164
      for share
    ) then
      raise exception 'whatsapp_messages: consentimento ativo incompativel com a mensagem';
    end if;
  elsif tg_op = 'UPDATE' then
    if new.fisioterapeuta_id is distinct from old.fisioterapeuta_id
      or new.patient_id is distinct from old.patient_id
      or new.appointment_id is distinct from old.appointment_id
      or new.reminder_type is distinct from old.reminder_type
      or new.schedule_revision is distinct from old.schedule_revision
      or new.scheduled_for is distinct from old.scheduled_for
      or new.destination_phone_e164 is distinct from old.destination_phone_e164
      or new.consent_id is distinct from old.consent_id
    then
      raise exception
        'whatsapp_messages: campos de identidade sao imutaveis apos a '
        'criacao (fisioterapeuta_id, patient_id, appointment_id, '
        'reminder_type, schedule_revision, scheduled_for, '
        'destination_phone_e164, consent_id). Uma remarcacao cria uma '
        'NOVA linha com nova schedule_revision -- nunca atualiza esta.';
    end if;
  end if;
  return new;
end;
$f0023$)::text),

    ('03 funcao ainda nao tem WA001', 'false',
      (position('WA001' in (select prosrc from pg_proc where proname = 'whatsapp_messages_validate_and_protect')) > 0)::text),
    ('04 exatamente 1 funcao com esse nome (sem overload)', '1',
      (select count(*) from pg_proc where proname = 'whatsapp_messages_validate_and_protect')::text),
    ('05 search_path vazio, sem security definer', 'true',
      (select proconfig = array['search_path=""'] and not prosecdef from pg_proc
        where proname = 'whatsapp_messages_validate_and_protect')::text),
    ('06 exatamente 2 triggers em whatsapp_messages', '2',
      (select count(*) from pg_trigger
        where tgrelid = 'public.whatsapp_messages'::regclass and not tgisinternal)::text),
    ('07 os 2 triggers sao os esperados', 'whatsapp_messages_touch_updated_at,whatsapp_messages_validate_and_protect',
      (select string_agg(tgname, ',' order by tgname) from pg_trigger
        where tgrelid = 'public.whatsapp_messages'::regclass and not tgisinternal)),
    ('08 validate_and_protect aponta para a funcao', 'true',
      (select tgfoid = 'public.whatsapp_messages_validate_and_protect()'::regprocedure from pg_trigger
        where tgname = 'whatsapp_messages_validate_and_protect'
          and tgrelid = 'public.whatsapp_messages'::regclass)::text),
    ('09 ramo INSERT ainda usa raise generico (P0001), sem errcode', 'true',
      (position('raise exception ''whatsapp_messages: consentimento ativo incompativel com a mensagem''' in
        (select prosrc from pg_proc where proname = 'whatsapp_messages_validate_and_protect')) > 0
       and position('errcode' in (select prosrc from pg_proc where proname = 'whatsapp_messages_validate_and_protect')) = 0)::text),
    ('10 UNIQUE one_per_appointment_revision valida e ready', 'true',
      (select indisvalid and indisready and indisunique from pg_index
        where indexrelid = 'public.whatsapp_messages_one_per_appointment_revision'::regclass)::text),
    ('11 FK composta e CHECK E.164 da 0023 presentes e validadas', '2',
      (select count(*) from pg_constraint
        where conrelid = 'public.whatsapp_messages'::regclass and convalidated
          and conname in ('whatsapp_messages_consent_owner_fkey', 'whatsapp_messages_destination_phone_e164_format'))::text),
    ('12 indice patient_consents_id_owner_key (alvo da FK) valido', 'true',
      (select indisvalid and indisready from pg_index
        where indexrelid = 'public.patient_consents_id_owner_key'::regclass)::text),
    ('13 RLS ligado em whatsapp_messages e patient_consents', 'true',
      (select bool_and(relrowsecurity) from pg_class
        where oid in ('public.whatsapp_messages'::regclass, 'public.patient_consents'::regclass))::text),
    ('14 nenhuma transacao aberta ha mais de 60s', '0',
      (select count(*) from pg_stat_activity
        where datname = current_database() and pid <> pg_backend_pid()
          and xact_start < now() - interval '60 seconds')::text),
    ('15 nenhum lock de outra sessao em whatsapp_messages/patient_consents', '0',
      (select count(*) from pg_locks l
        where l.pid <> pg_backend_pid()
          and l.relation in ('public.whatsapp_messages'::regclass, 'public.patient_consents'::regclass))::text)
)
select case when esperado = atual then 'PASS' else 'FAIL' end as resultado, item, esperado, atual from checks
union all
select case when bool_and(esperado = atual) then 'PASS' else 'FAIL' end, '99 geral', 'PASS',
  case when bool_and(esperado = atual) then 'PASS' else 'FAIL' end from checks
union all
-- Informativo (não entra no geral): contagem de patient_consents e conexões ativas.
select 'INFO', '97 patient_consents (linhas)', '-', (select count(*) from public.patient_consents)::text
union all
select 'INFO', '98 conexoes client backend: ' || coalesce(state, '?'), '-', count(*)::text
from pg_stat_activity
where datname = current_database() and pid <> pg_backend_pid() and backend_type = 'client backend'
group by state
order by 2;
