-- Run this in the Supabase dashboard: SQL Editor > New query
-- (or: npx supabase db query -f <this file> --linked).
--
-- Fecha a lacuna de destino/autorização encontrada na auditoria de
-- whatsapp_messages: hoje a tabela não guarda QUAL número foi autorizado
-- no momento em que a mensagem foi materializada, nem QUAL consentimento
-- autorizou aquele destino. Sem isso, reler patients.phone_e164 no momento
-- do envio poderia mandar uma mensagem para um número diferente do que
-- foi de fato aprovado (telefone pode mudar entre a fila ser criada e o
-- envio real).
--
-- whatsapp_messages está vazia hoje (confirmado no preflight abaixo) --
-- por isso as duas colunas novas podem ser NOT NULL sem nenhum backfill
-- fictício. Se deixar de estar vazia antes desta migration ser aplicada
-- de verdade, a migration ABORTA (ver passo 1) em vez de inventar um
-- valor para linhas existentes.
--
-- NÃO implementa persistência, dispatch, cron, Meta nem altera Flutter.
-- NÃO altera status/CHECKs de status (essa semântica fica para quando o
-- dispatch for desenhado -- ver nota sobre attempted_at em conversas
-- anteriores).

-- ---------------------------------------------------------------------
-- 0. Trava de segurança: só continua se whatsapp_messages estiver vazia.
-- ---------------------------------------------------------------------
do $$
begin
  if exists (select 1 from public.whatsapp_messages limit 1) then
    raise exception
      'MIGRATION 0023 ABORTADA: whatsapp_messages nao esta vazia. Esta '
      'migration exige destination_phone_e164/consent_id NOT NULL sem '
      'nenhum backfill ficticio -- se ja existem linhas reais, alguma '
      'outra etapa comecou a persistir mensagens antes desta migration '
      'ser aplicada. Investigue antes de continuar; NAO prossiga '
      'inventando um backfill.';
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 1. Colunas novas (nullable primeiro, por clareza/idempotência -- a
--    tabela já está vazia, então SET NOT NULL abaixo é seguro e
--    instantâneo).
-- ---------------------------------------------------------------------
alter table public.whatsapp_messages
  add column if not exists destination_phone_e164 text,
  add column if not exists consent_id uuid;

alter table public.whatsapp_messages
  alter column destination_phone_e164 set not null,
  alter column consent_id set not null;

-- ---------------------------------------------------------------------
-- 2. CHECK de formato E.164 -- MESMA regex já usada em
--    patients.phone_e164 (patients_phone_e164_format) e
--    patient_consents.contact_value (patient_consents_contact_value_e164).
--    Não inventa uma regra nova: reutiliza a existente, sem o ramo
--    "channel <> whatsapp OR" porque esta tabela é inteiramente de
--    mensagens WhatsApp (reminder_type já garante isso).
-- ---------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_destination_phone_e164_format'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_destination_phone_e164_format
      check (destination_phone_e164 ~ '^\+[1-9][0-9]{7,14}$');
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 3. Índice único composto em patient_consents, SÓ para sustentar a FK
--    composta do passo 4 -- mesmo padrão já usado em patients_id_owner_key
--    e appointments_id_owner_key (migration 0018): `id` já é PK, então
--    este índice nunca falha por conflito de dados, só torna a tripla
--    (id, patient_id, fisioterapeuta_id) referenciável por FK.
-- ---------------------------------------------------------------------
create unique index if not exists patient_consents_id_owner_key
  on public.patient_consents (id, patient_id, fisioterapeuta_id);

-- ---------------------------------------------------------------------
-- 4. FK composta ESTRUTURAL: garante que o consent_id referenciado
--    pertence EXATAMENTE ao patient_id e fisioterapeuta_id desta mesma
--    linha de whatsapp_messages. Um bug de backend que tentasse associar
--    a mensagem do paciente A a um consentimento do paciente B (ou de
--    outro profissional) falharia aqui.
--
--    DE PROPÓSITO esta FK não inclui revoked_at/channel/purpose/
--    contact_value: um consentimento pode ser revogado legitimamente
--    DEPOIS da materialização, e a linha histórica em whatsapp_messages
--    precisa continuar existindo e válida como registro -- uma FK que
--    dependesse de revoked_at IS NULL quebraria no instante da
--    revogação. A validação SEMÂNTICA completa (canal, finalidade,
--    revogação, telefone) é feita só no momento do INSERT, pelo trigger
--    do passo 5 -- nunca reavaliada depois.
-- ---------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_consent_owner_fkey'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_consent_owner_fkey
      foreign key (consent_id, patient_id, fisioterapeuta_id)
      references public.patient_consents (id, patient_id, fisioterapeuta_id);
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 5. UM ÚNICO trigger novo, com DUAS responsabilidades (evita multiplicar
--    triggers BEFORE sem necessidade -- o único trigger pré-existente,
--    whatsapp_messages_touch_updated_at, continua separado e intacto,
--    porque tem responsabilidade genuinamente diferente: só updated_at,
--    só em UPDATE):
--
--    BEFORE INSERT: valida que existe, de fato, um patient_consents
--    ativo e compatível -- channel='whatsapp', purpose=
--    'appointment_reminder', revoked_at IS NULL, E contact_value IGUAL a
--    destination_phone_e164. A FK do passo 4 já garante a tripla
--    id+patient_id+fisioterapeuta_id; esta validação garante o resto, que
--    nenhuma FK simples conseguiria expressar (são condições sobre
--    colunas que não fazem parte de nenhuma chave).
--
--    CONCORRÊNCIA: a consulta usa FOR SHARE na linha de patient_consents.
--    Sob READ COMMITTED (padrão do Postgres), um SELECT comum não
--    bloqueia nem é bloqueado por outra transação -- então, sem FOR
--    SHARE, uma revogação CONCORRENTE ainda não commitada no instante
--    exato desta validação poderia, em tese, não ser vista (o SELECT
--    veria a versão anterior, ainda ativa). FOR SHARE força o oposto:
--    se outra transação está exatamente no meio de um
--    UPDATE patient_consents SET revoked_at=... nesta mesma linha, nosso
--    SELECT...FOR SHARE ESPERA aquela transação terminar antes de
--    decidir -- nunca valida contra um estado "no meio do caminho". Isso
--    fecha a janela de corrida sem exigir nenhuma arquitetura adicional
--    (sem advisory lock, sem SERIALIZABLE). Uma revogação que termine de
--    commitar ANTES desta validação começar sempre é vista (MVCC comum,
--    sem lock nenhum necessário para isso). Uma revogação que comece
--    DEPOIS desta validação terminar (ou depois do INSERT commitar) é
--    permitida normalmente -- é exatamente o comportamento desejado
--    ("revogação posterior continua permitida").
--
--    BEFORE UPDATE: bloqueia qualquer tentativa de mudar os 8 campos de
--    identidade (os mesmos de antes, agora incluindo o fato de que
--    consent_id/destination_phone_e164 nunca são revalidados num UPDATE
--    -- eles são fixados para sempre no INSERT). status/wamid/
--    template_name/sent_at/delivered_at/read_at/failed_at/error/
--    updated_at continuam livres, de propósito.
--
--    Mensagem de erro do INSERT é GENÉRICA, sem telefone/patient_id --
--    nunca vaza PII numa exception que pode acabar em log.
-- ---------------------------------------------------------------------
create or replace function public.whatsapp_messages_validate_and_protect()
returns trigger
language plpgsql
set search_path = ''
as $$
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
$$;

create or replace trigger whatsapp_messages_validate_and_protect
  before insert or update on public.whatsapp_messages
  for each row execute function public.whatsapp_messages_validate_and_protect();
-- Ordem entre os dois BEFORE UPDATE (Postgres executa triggers do mesmo
-- evento em ordem alfabética do NOME do trigger, não da ordem de
-- criação): "whatsapp_messages_touch_updated_at" vem antes de
-- "whatsapp_messages_validate_and_protect" ('t' < 'v'). Isso não importa
-- aqui: touch_updated_at só toca updated_at (nunca olha os 8 campos de
-- identidade) e validate_and_protect só olha os 8 campos de identidade
-- (nunca toca updated_at) -- são ortogonais, qualquer ordem produz o
-- mesmo resultado. Confirmado por teste (ver 00_dry_run).

-- ---------------------------------------------------------------------
-- 6. Comentários de documentação.
-- ---------------------------------------------------------------------
comment on column public.whatsapp_messages.destination_phone_e164 is
  'Snapshot IMUTAVEL do telefone E.164 autorizado no momento em que esta '
  'mensagem foi materializada (copiado de patients.phone_e164, validado '
  'pelo trigger whatsapp_messages_validate_and_protect no INSERT contra '
  'um patient_consents ativo e compativel). O futuro dispatch usa ESTE '
  'valor, nunca relendo patients.phone_e164.';

comment on column public.whatsapp_messages.consent_id is
  'patient_consents.id que autorizou destination_phone_e164 no momento '
  'da materializacao (validado no INSERT: channel=whatsapp, '
  'purpose=appointment_reminder, revoked_at IS NULL, contact_value = '
  'destination_phone_e164). IMUTAVEL apos a criacao -- NUNCA revalidado '
  'num UPDATE. Revogacao POSTERIOR do consentimento referenciado e '
  'permitida e nao quebra esta linha (a FK nao depende de revoked_at); '
  'o futuro dispatch deve reconferir revoked_at antes de enviar uma '
  'mensagem ainda scheduled. Reconsentimento futuro (uma NOVA linha de '
  'patient_consents apos a revogacao) NAO ressuscita automaticamente uma '
  'mensagem cancelada da mesma tripla appointment_id+reminder_type+ '
  'schedule_revision -- essa tripla permanece ocupada pela UNIQUE '
  'existente (nao-parcial); uma nova autorizacao so vale para novos '
  'appointments/revisions.';

-- ---------------------------------------------------------------------
-- Check (read-only):
--   01_check   as 2 colunas novas: NOT NULL, tipos corretos
--   02_check   FK composta + CHECK existem
--   03_check   trigger unico (INSERT valida, UPDATE protege) ativo
-- ---------------------------------------------------------------------
select '01_check' as secao, column_name, data_type, is_nullable
from information_schema.columns
where table_schema='public' and table_name='whatsapp_messages'
  and column_name in ('destination_phone_e164', 'consent_id');

select '02_check' as secao, conname
from pg_constraint
where conrelid='public.whatsapp_messages'::regclass
  and conname in ('whatsapp_messages_consent_owner_fkey', 'whatsapp_messages_destination_phone_e164_format');

select '03_check' as secao, tgname, pg_get_triggerdef(oid)
from pg_trigger
where tgrelid='public.whatsapp_messages'::regclass and not tgisinternal
order by tgname;
