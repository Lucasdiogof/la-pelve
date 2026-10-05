-- Run this in the Supabase dashboard: SQL Editor > New query
-- (or: npx supabase db query -f <this file> --linked).
--
-- Amplia whatsapp_messages (da 0018) para suportar os 3 tipos de evento de
-- agendamento definidos pelo produto: appointment_confirmation,
-- appointment_12h (já existia) e appointment_rescheduled. NÃO implementa
-- nenhum envio, scheduler, cron, Edge Function ou integração com a Meta —
-- é só o schema e as regras documentadas para a etapa seguinte.
--
-- v2 desta migration: a primeira versão usava um event_key de texto livre
-- para dedupicar appointment_rescheduled. Foi descartada (nunca chegou a
-- produção) depois de uma auditoria mostrar dois problemas: (1)
-- appointment_12h também pode repetir — se uma consulta é remarcada DEPOIS
-- de um lembrete já ter sido enviado, o novo horário precisa de outro
-- lembrete, e o antigo não pode ser sobrescrito; (2) uma chave baseada só
-- no horário antigo/novo colide quando o horário "volta" a um valor já
-- usado antes (ex.: A->B->A->B). A solução final usa um contador de
-- versão (schedule_revision) controlado inteiramente pelo banco, nunca
-- pelo cliente — ver seção 1.
--
-- Idempotente: pode rodar de novo sem efeito colateral. Puramente aditivo
-- nos dados: nenhuma linha é alterada ou perdida (confirmado por
-- pre-flight que whatsapp_messages está vazia e os 65 appointments reais
-- em produção têm date/time preenchidos). Os 65 appointments existentes
-- passam a ter schedule_revision = 0 (correto: nenhum deles tem remarcação
-- rastreada até hoje — 0 linhas com status 'rescheduled').

-- ---------------------------------------------------------------------
-- 1. appointments.schedule_revision — controlado SÓ pelo banco
-- ---------------------------------------------------------------------
-- Representa exclusivamente a versão de DATE/TIME do agendamento: 0 =
-- horário original; 1 = depois da 1ª mudança real de date ou time; 2 =
-- depois da 2ª; etc. Mudar patient_name, patient_id, status ou qualquer
-- outro campo NUNCA incrementa isto. O cliente não pode escolher o valor
-- — o trigger abaixo sobrescreve o que quer que ele envie.
alter table public.appointments
  add column if not exists schedule_revision integer not null default 0;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'appointments_schedule_revision_non_negative'
      and conrelid = 'public.appointments'::regclass
  ) then
    alter table public.appointments
      add constraint appointments_schedule_revision_non_negative
      check (schedule_revision >= 0);
  end if;
end $$;

-- Uma função + um trigger BEFORE INSERT OR UPDATE (em vez de dois
-- triggers separados): é a mesma lógica simples em ambos os casos — "o
-- valor final de schedule_revision nunca vem do cliente, só do que o
-- banco já sabia (OLD) e do que realmente mudou (NEW.date/NEW.time)" —
-- não há motivo para duplicar isso em dois objetos. BEFORE (não AFTER)
-- porque só um trigger BEFORE pode alterar NEW antes da linha ser escrita.
create or replace function public.set_appointment_schedule_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    -- Agendamento novo: sempre começa do zero, não importa o que o
    -- cliente tenha mandado.
    new.schedule_revision = 0;
  elsif tg_op = 'UPDATE' then
    if new.date is distinct from old.date or new.time is distinct from old.time then
      -- Mudança real de horário: avança exatamente 1, a partir do que o
      -- banco já tinha (OLD), nunca do valor que o cliente mandou.
      new.schedule_revision = old.schedule_revision + 1;
    else
      -- Qualquer outra mudança (nome, status, paciente...): preserva o
      -- valor que já existia, ignorando o que o cliente mandou.
      new.schedule_revision = old.schedule_revision;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists appointments_set_schedule_revision on public.appointments;
create trigger appointments_set_schedule_revision
  before insert or update on public.appointments
  for each row execute function public.set_appointment_schedule_revision();

comment on column public.appointments.schedule_revision is
  'Versao de DATE/TIME do agendamento, controlada so pelo trigger '
  'appointments_set_schedule_revision — o cliente nao pode definir este '
  'valor. 0 = horario original; incrementa exatamente 1 a cada mudanca '
  'real de date ou time (nunca por mudar nome/status/paciente/etc). Usada '
  'por whatsapp_messages.schedule_revision para identificar a que versao '
  'do horario cada mensagem pertence.';

-- ---------------------------------------------------------------------
-- 2. reminder_type: amplia o CHECK para os 3 tipos (sem renomear a
--    coluna — "reminder_type" continua funcionando tecnicamente mesmo
--    não sendo mais só "lembrete")
-- ---------------------------------------------------------------------
do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_reminder_type_valid'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      drop constraint whatsapp_messages_reminder_type_valid;
  end if;

  alter table public.whatsapp_messages
    add constraint whatsapp_messages_reminder_type_valid
    check (reminder_type in (
      'appointment_confirmation',
      'appointment_12h',
      'appointment_rescheduled'
    ));
end $$;

-- ---------------------------------------------------------------------
-- 3. whatsapp_messages.schedule_revision + idempotência unificada
-- ---------------------------------------------------------------------
-- Problema com a UNIQUE (appointment_id, reminder_type) herdada da 0018:
-- ela pressupõe "no máximo 1 linha por (consulta, tipo), para sempre".
-- Isso é ERRADO tanto para appointment_rescheduled (uma consulta pode ser
-- remarcada mais de uma vez; cada remarcação real fica no histórico)
-- quanto para appointment_12h (se a consulta for remarcada DEPOIS de um
-- lembrete já ter sido enviado, o novo horário precisa de outro
-- lembrete — o antigo, já enviado, não pode ser sobrescrito nem usado
-- para bloquear o novo).
--
-- Solução: cada linha carrega a que schedule_revision da consulta ela se
-- refere, e a unicidade passa a ser por (appointment_id, reminder_type,
-- schedule_revision) — "no máximo 1 linha por consulta+tipo+versão do
-- horário", nunca "por consulta+tipo para sempre". Como schedule_revision
-- é um contador monotônico controlado pelo banco (seção 1), ele nunca
-- colide mesmo quando o horário "volta" a um valor usado antes (ex.:
-- A->B->A->B tem revisions 0,1,2,3, mesmo repetindo os valores de
-- data/hora) — o que uma chave baseada só nos valores de data/hora não
-- conseguiria garantir.
alter table public.whatsapp_messages
  add column if not exists schedule_revision integer not null default 0;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_schedule_revision_non_negative'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_schedule_revision_non_negative
      check (schedule_revision >= 0);
  end if;
end $$;

-- Coerência tipo <-> revisão permitida:
--   appointment_confirmation: só existe na criação original (revision 0).
--   appointment_rescheduled:  só existe a partir da 1ª remarcação real
--                             (revision >= 1 — não existe "remarcação"
--                             do agendamento original).
--   appointment_12h:          qualquer revisão (0, 1, 2...), uma por vez.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_schedule_revision_matches_type'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_schedule_revision_matches_type
      check (
        (reminder_type = 'appointment_confirmation' and schedule_revision = 0)
        or (reminder_type = 'appointment_rescheduled' and schedule_revision >= 1)
        or (reminder_type = 'appointment_12h' and schedule_revision >= 0)
      );
  end if;
end $$;

alter table public.whatsapp_messages
  drop constraint if exists whatsapp_messages_one_per_appointment_type;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'whatsapp_messages_one_per_appointment_revision'
      and conrelid = 'public.whatsapp_messages'::regclass
  ) then
    alter table public.whatsapp_messages
      add constraint whatsapp_messages_one_per_appointment_revision
      unique (appointment_id, reminder_type, schedule_revision);
  end if;
end $$;

comment on column public.whatsapp_messages.schedule_revision is
  'A que appointments.schedule_revision esta mensagem se refere — capturado '
  'no momento em que a mensagem eh criada pelo scheduler futuro, nunca '
  'recalculado depois. Junto com (appointment_id, reminder_type) forma a '
  'chave de idempotencia (ver whatsapp_messages_one_per_appointment_revision). '
  'Uma mensagem NUNCA eh movida de uma revisao para outra via UPDATE — se '
  'o horario mudar de novo, nasce uma linha nova na revisao nova; a antiga '
  'fica no historico exatamente como estava.';

-- ---------------------------------------------------------------------
-- 4. status: auditoria (nenhuma mudança nesta migration)
-- ---------------------------------------------------------------------
-- Os 7 status existentes (scheduled, processing, sent, delivered, read,
-- failed, cancelled) já cobrem os 3 tipos de evento desta fase — ver
-- comentário completo na tabela, item (8). Não é adicionado status novo.

-- ---------------------------------------------------------------------
-- 5. Documentação das regras do scheduler futuro (NADA disto é
--    implementado aqui — nenhuma trigger de envio, função de agendamento
--    ou job é criado; só o trigger de schedule_revision da seção 1, que é
--    puramente estrutural)
-- ---------------------------------------------------------------------
comment on table public.whatsapp_messages is
  'Metadados de envio de mensagens de agendamento pelo WhatsApp (sem '
  'corpo da mensagem). Carrega so follow-up de entrega; quem decide o que '
  'criar/cancelar e QUANDO enviar e um scheduler futuro, ainda nao '
  'implementado. Regras que esse scheduler devera seguir: '
  '(1) EVENTOS: appointment_confirmation ao criar o agendamento (nao ao '
  'cadastrar o paciente), sempre na revision 0; appointment_12h = horario '
  'da consulta - 12h, pode existir em qualquer revision; '
  'appointment_rescheduled quando date/time mudar de verdade (revision '
  '>= 1). Nao existe mensagem de cancelamento nesta fase. '
  '(2) ANTECEDENCIA: agendamento criado/remarcado com MAIS de 12h de '
  'antecedencia pode ter confirmation + appointment_12h daquela revisao; '
  'com 12h OU MENOS (inclusive exatamente 12h), so a confirmation/'
  'rescheduled, nunca um appointment_12h (ele cairia no passado ou no '
  'mesmo instante). '
  '(3) SILENCIO: nenhum envio entre 22:00 e 06:59 no fuso de '
  'profiles.timezone (default America/Sao_Paulo); confirmation ou '
  'appointment_12h calculados dentro desse intervalo tem o horario '
  'EFETIVO de envio adiado para 07:00 do fuso do profissional. Se 07:00 '
  'chegar e a consulta ja tiver ocorrido, NAO enviar a mensagem atrasada. '
  '(4) INTERVALO MINIMO: confirmation e appointment_12h DA MESMA REVISAO '
  'precisam ficar a pelo menos 2h de distancia um do outro, comparando os '
  'horarios EFETIVOS (apos o ajuste do silencio, item 3). Se o intervalo '
  'ficar menor que 2h (ou cair no mesmo instante), appointment_12h e '
  'suprimido/cancelado e so a confirmation existe — confirmation tem '
  'prioridade, nunca o contrario. '
  '(5) REMARCACAO: mudar date/time de verdade incrementa '
  'appointments.schedule_revision (so o banco faz isso, nunca o '
  'cliente). O scheduler deve reavaliar mensagens ainda nao enviadas '
  '(status scheduled/processing) da REVISAO ANTERIOR: cancela-las (nunca '
  'faz UPDATE para "mudar de revisao" uma linha existente — uma mensagem '
  'fica ligada para sempre a revisao em que nasceu) e criar as novas da '
  'revisao atual (appointment_12h recalculado reaplicando os itens 2-4; '
  'appointment_rescheduled avisando o novo dia/horario, sem dado '
  'clinico). Uma consulta pode ser remarcada mais de uma vez; cada '
  'remarcacao real vira uma revision nova, sem limite. '
  '(6) MENSAGEM DESATUALIZADA (stale): antes de enviar qualquer mensagem '
  'ainda pendente (scheduled/processing), o scheduler DEVE reler '
  'appointments.schedule_revision atual. Se message.schedule_revision <> '
  'appointments.schedule_revision, a mensagem pertence a uma versao '
  'antiga do horario: NAO enviar, e futuramente marcar como cancelled. '
  'Isso cobre inclusive o caso de uma confirmation que ainda esperava o '
  'fim do silencio e, nesse intervalo, a consulta foi remarcada — a '
  'confirmation antiga fica stale/cancelled, e quem passa a representar '
  'o novo horario e a mensagem appointment_rescheduled da revisao atual. '
  'Mensagens ja sent/delivered/read/failed (apos tentativa real) NUNCA '
  'sao alteradas por isso — ficam no historico exatamente como foram '
  'enviadas, mesmo que pertencam a uma revisao que deixou de ser a atual. '
  '(7) CANCELAMENTO: se appointments.status indicar consulta cancelada, '
  'qualquer mensagem pendente (scheduled/processing) de qualquer revisao '
  'deve ser cancelada antes do envio; mensagens ja enviadas permanecem no '
  'historico, intocadas. '
  '(8) STATUS: os 7 existentes (scheduled, processing, sent, delivered, '
  'read, failed, cancelled) sao suficientes para esta fase — cancelled '
  'cobre tanto consulta cancelada quanto mensagem suprimida pela regra de '
  'prioridade do item 4 ou pela regra de stale do item 6; nenhum status '
  'novo foi adicionado. '
  '(9) ELEGIBILIDADE (reavaliada a cada tentativa de envio, nao so na '
  'criacao): appointments.patient_id precisa existir; patients.phone_e164 '
  'precisa ser valido; precisa existir patient_consents ativo '
  '(channel=whatsapp, purpose=appointment_reminder) cujo contact_value '
  'seja EXATAMENTE igual ao patients.phone_e164 atual; o profissional '
  'precisa ter whatsapp_connections com status=connected (ainda nao '
  'implementado). Nenhuma mensagem pode conter diagnostico, anamnese, '
  'tratamento ou qualquer informacao clinica — so dia/horario da consulta.';

-- ---------------------------------------------------------------------
-- Check (read-only):
--   01_check     3 linhas: os 3 CHECKs novos/ampliados em whatsapp_messages
--   02_check     1 linha: a UNIQUE nova (appointment_id, reminder_type, schedule_revision)
--   03_check     1 linha: a UNIQUE antiga (so 2 colunas) não existe mais
--   04_check     1 linha: schedule_revision existe em whatsapp_messages
--   05_check     1 linha: schedule_revision existe em appointments, NOT NULL default 0
--   06_check     1 linha: CHECK de não-negativo em appointments
--   07_check     1 linha: o trigger em appointments existe
-- ---------------------------------------------------------------------
select '01_check' as secao, conname, pg_get_constraintdef(oid) as def
from pg_constraint
where conrelid = 'public.whatsapp_messages'::regclass
  and conname in (
    'whatsapp_messages_reminder_type_valid',
    'whatsapp_messages_schedule_revision_non_negative',
    'whatsapp_messages_schedule_revision_matches_type'
  )
order by conname;

select '02_check' as secao, conname, pg_get_constraintdef(oid) as def
from pg_constraint
where conrelid = 'public.whatsapp_messages'::regclass
  and conname = 'whatsapp_messages_one_per_appointment_revision';

select '03_check' as secao, count(*) as linhas_com_esse_nome
from pg_constraint
where conrelid = 'public.whatsapp_messages'::regclass
  and conname = 'whatsapp_messages_one_per_appointment_type';

select '04_check' as secao, column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'whatsapp_messages'
  and column_name = 'schedule_revision';

select '05_check' as secao, column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'appointments'
  and column_name = 'schedule_revision';

select '06_check' as secao, conname, pg_get_constraintdef(oid) as def
from pg_constraint
where conrelid = 'public.appointments'::regclass
  and conname = 'appointments_schedule_revision_non_negative';

select '07_check' as secao, tgname, pg_get_triggerdef(oid) as def
from pg_trigger
where tgrelid = 'public.appointments'::regclass and not tgisinternal;
