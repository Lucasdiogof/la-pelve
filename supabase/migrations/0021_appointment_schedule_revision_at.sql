-- Run this in the Supabase dashboard: SQL Editor > New query
-- (or: npx supabase db query -f <this file> --linked).
--
-- Adiciona public.appointments.schedule_revision_at: o instante em que a
-- VERSÃO ATUAL de date/time do agendamento nasceu. Para schedule_revision=0
-- é o momento de criação do agendamento; para cada revisão seguinte, é o
-- momento daquela remarcação específica. Sem isto, o scheduler (lógica pura
-- já escrita em supabase/functions/_shared/scheduler/) não tem como saber
-- quando uma remarcação aconteceu — só appointments.created_at existe hoje,
-- e ele só serve para a revisão 0.
--
-- NÃO implementa scheduler, cron, envio ou integração Meta. NÃO altera
-- Flutter. Idempotente: pode rodar de novo sem efeito colateral.
--
-- Backfill intencional e cuidadoso: os 65 appointments reais de produção
-- estão todos em schedule_revision=0 (confirmado por pre-flight) — para
-- eles, schedule_revision_at = created_at é a verdade histórica, não um
-- valor inventado. NÃO se usa um DEFAULT now() direto na criação da coluna,
-- porque isso daria a TODOS os 65 registros o horário da migration, o que
-- falsificaria quando cada um foi de fato criado.

-- ---------------------------------------------------------------------
-- 1. Coluna nullable primeiro (sem default ainda) — o backfill explícito
--    do passo 2 é quem decide o valor de cada linha existente.
-- ---------------------------------------------------------------------
alter table public.appointments
  add column if not exists schedule_revision_at timestamptz;

-- ---------------------------------------------------------------------
-- 2. Backfill SÓ onde ainda está null — idempotente: reaplicar a
--    migration depois que todas as linhas já tiverem valor não afeta
--    nada (WHERE … IS NULL não encontra candidatos).
--
--    IMPORTANTE: isto roda ANTES de trocar a função do trigger (passo 6),
--    de propósito. O trigger ainda ativo aqui é a versão da 0020, que só
--    conhece schedule_revision — ele não toca em schedule_revision_at,
--    então este UPDATE passa limpo. Se a função já tivesse sido trocada
--    antes deste passo, o próprio trigger novo devolveria
--    NEW.schedule_revision_at = OLD.schedule_revision_at (nulo, já que
--    nenhuma mudança de date/time está acontecendo aqui) e cancelaria o
--    backfill silenciosamente — foi exatamente isso que a validação em
--    BEGIN…ROLLBACK (00_dry_run_full_validation.sql) pegou antes desta
--    migration ser escrita assim.
-- ---------------------------------------------------------------------
update public.appointments
set schedule_revision_at = created_at
where schedule_revision_at is null;

-- ---------------------------------------------------------------------
-- 3. Confirma que não sobrou nenhum null antes de travar a coluna.
-- ---------------------------------------------------------------------
do $$
begin
  if exists (select 1 from public.appointments where schedule_revision_at is null) then
    raise exception
      'MIGRATION ABORTADA: ainda há appointments com schedule_revision_at '
      'nulo depois do backfill. Isso não deveria acontecer (created_at é '
      'NOT NULL); investigue antes de continuar.';
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 4. DEFAULT now() só como rede de segurança estilística (mesma escolha
--    de created_at) — na prática NUNCA é usado, porque o trigger do
--    passo 5 sempre define o valor antes de qualquer INSERT/UPDATE ser
--    gravado. A fonte definitiva é o trigger, não este DEFAULT.
-- ---------------------------------------------------------------------
alter table public.appointments
  alter column schedule_revision_at set default now();

-- ---------------------------------------------------------------------
-- 5. NOT NULL — seguro agora que o passo 3 confirmou zero nulos.
-- ---------------------------------------------------------------------
alter table public.appointments
  alter column schedule_revision_at set not null;

-- ---------------------------------------------------------------------
-- 6. SÓ AGORA atualiza a MESMA função/trigger da 0020 (não cria um
--    segundo mecanismo) — depois que a coluna já está pronta
--    (NOT NULL + backfill completo), para o trigger novo nunca ver um
--    OLD.schedule_revision_at nulo. A partir de agora ela também controla
--    schedule_revision_at, com a mesma garantia de schedule_revision: o
--    cliente nunca escolhe o valor, só o banco.
--
--    DOIS instantes diferentes, de propósito:
--
--    a) INSERT (revision 0): NEW.schedule_revision_at = NEW.created_at,
--       NÃO clock_timestamp(). Motivo: appointments.created_at já usa
--       DEFAULT now() (fixo no início da transação). Se a revision 0
--       usasse clock_timestamp() no trigger, os dois timestamps
--       poderiam divergir por uma fração de segundo — now() é resolvido
--       antes do trigger rodar, clock_timestamp() seria resolvido
--       DENTRO do trigger, um instante depois. Isso violaria a
--       semântica aprovada ("revision 0 nasceu no momento de criação do
--       agendamento" = created_at) e quebraria a invariante que o
--       rollback depende de: schedule_revision_at == created_at para
--       toda linha em revision 0. No Postgres, o DEFAULT de uma coluna
--       já é aplicado a NEW antes do corpo de um trigger BEFORE INSERT
--       rodar — então NEW.created_at já está disponível e com o valor
--       final (seja o DEFAULT now(), seja um valor que o cliente tenha
--       mandado explicitamente) no momento em que este trigger lê
--       NEW.created_at. Isso é exercitado e confirmado nos testes 2 e 3
--       do dry-run.
--
--    b) UPDATE com mudança real de date/time (revision >= 1):
--       NEW.schedule_revision_at = clock_timestamp(), como antes. Aqui
--       não existe nenhuma coluna "created_at da remarcação" para
--       copiar — clock_timestamp() é a própria definição do instante em
--       que a nova revisão nasceu. now()/transaction_timestamp() ficam
--       fixos no início da transação (errado se este UPDATE for um
--       entre vários numa transação mais longa já aberta);
--       statement_timestamp() tem uma pegadinha documentada: não muda
--       entre comandos enviados juntos na mesma mensagem multi-statement
--       nem dentro do mesmo bloco função/DO, o que a primeira versão
--       deste dry-run expôs. clock_timestamp() reavalia o relógio de
--       parede a cada chamada, sem essa pegadinha.
-- ---------------------------------------------------------------------
create or replace function public.set_appointment_schedule_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    -- Agendamento novo: sempre começa do zero, não importa o que o
    -- cliente tenha mandado para schedule_revision. schedule_revision_at
    -- copia NEW.created_at (já resolvido pelo DEFAULT/valor do cliente
    -- antes deste trigger rodar) em vez de clock_timestamp(), para
    -- garantir igualdade exata com created_at — nunca uma fração de
    -- segundo depois.
    new.schedule_revision = 0;
    new.schedule_revision_at = new.created_at;
  elsif tg_op = 'UPDATE' then
    if new.date is distinct from old.date or new.time is distinct from old.time then
      -- Mudança real de horário: avança exatamente 1 e registra o
      -- instante de AGORA como o nascimento desta revisão — nunca o que
      -- o cliente mandou em nenhum dos dois campos.
      new.schedule_revision = old.schedule_revision + 1;
      new.schedule_revision_at = clock_timestamp();
    else
      -- Qualquer outra mudança (nome, status, paciente...): preserva os
      -- dois valores que já existiam, ignorando o que o cliente mandou.
      new.schedule_revision = old.schedule_revision;
      new.schedule_revision_at = old.schedule_revision_at;
    end if;
  end if;
  return new;
end;
$$;
-- O trigger appointments_set_schedule_revision (BEFORE INSERT OR UPDATE,
-- já criado na 0020) referencia esta função por nome: substituí-la aqui já
-- é suficiente, não precisa recriar o trigger.

comment on column public.appointments.schedule_revision_at is
  'Instante (timestamptz, absoluto) em que a versao ATUAL de date/time '
  'deste agendamento nasceu. Controlado exclusivamente pelo trigger '
  'appointments_set_schedule_revision via '
  'set_appointment_schedule_revision() — o cliente nunca escolhe este '
  'valor. revision 0: igual a created_at. revision N>=1: momento exato '
  'da N-esima mudanca real de date/time. E a fonte canonica que o '
  'scheduler (supabase/functions/_shared/scheduler/) usa para calcular a '
  'antecedencia de 12h e os horarios de appointment_12h/'
  'appointment_rescheduled de qualquer revisao, nao so a 0.';

-- ---------------------------------------------------------------------
-- Check (read-only):
--   01_check   schedule_revision_at: timestamptz, NOT NULL, default now()
--   02_check   os 65 appointments existentes têm schedule_revision_at = created_at
--   03_check   definição atual da função (deve conter schedule_revision_at nos 2 ramos)
-- ---------------------------------------------------------------------
select '01_check' as secao, column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'appointments'
  and column_name = 'schedule_revision_at';

select '02_check' as secao, count(*) as linhas_com_schedule_revision_at_diferente_de_created_at
from public.appointments
where schedule_revision_at <> created_at;

select '03_check' as secao, pg_get_functiondef(p.oid) as def
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'set_appointment_schedule_revision';
