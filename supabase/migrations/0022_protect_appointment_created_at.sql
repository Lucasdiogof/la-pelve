-- Run this in the Supabase dashboard: SQL Editor > New query
-- (or: npx supabase db query -f <this file> --linked).
--
-- Fecha a pendência de segurança deixada pela 0021: appointments.created_at
-- hoje é timestamptz NOT NULL DEFAULT now(), mas nada impede um cliente
-- authenticated de definir/alterar esse valor via PostgREST manual (fora do
-- Flutter) — a RLS só valida auth.uid() = fisioterapeuta_id, não restringe
-- colunas, e a role authenticated tem grant de INSERT/UPDATE na coluna.
--
-- Isso importa porque schedule_revision_at da revision 0 é definido como
-- igual a created_at (migration 0021), e o scheduler futuro vai confiar
-- nesses dois timestamps para decidir quando enviar lembretes.
--
-- Estratégia: NÃO criar um segundo trigger. A MESMA função/trigger que já
-- controla schedule_revision/schedule_revision_at (appointments_set_
-- schedule_revision, BEFORE INSERT OR UPDATE, desde a 0020/0021) passa a
-- controlar created_at também, numa única função — evita qualquer
-- dependência de ordem entre dois BEFORE triggers na mesma linha.
--
-- Migration mínima: nenhum ALTER de dados, nenhuma coluna nova, nenhum
-- índice novo, nenhum trigger novo — só CREATE OR REPLACE da função
-- existente. Nenhum UPDATE em appointments existentes: os valores atuais
-- de created_at/schedule_revision/schedule_revision_at/date/time/
-- patient_id/patient_name/status permanecem byte-a-byte iguais (o CREATE
-- OR REPLACE FUNCTION não toca em nenhuma linha).
--
-- DEFAULT now() de created_at NÃO é removido: fica como fallback/descrição
-- de schema (sem efeito prático, já que o trigger sempre sobrescreve NEW
-- antes de qualquer INSERT/UPDATE ser gravado) — remover o DEFAULT não traz
-- nenhum ganho de segurança adicional (o trigger já neutraliza qualquer
-- valor, com ou sem DEFAULT) e mudaria o schema sem necessidade.

create or replace function public.set_appointment_schedule_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  creation_time timestamptz;
begin
  if tg_op = 'INSERT' then
    -- Agendamento novo: created_at, schedule_revision e
    -- schedule_revision_at são TODOS definidos pelo banco, não importa o
    -- que o cliente tenha mandado para nenhum dos três. Um único
    -- clock_timestamp() (creation_time) alimenta created_at E
    -- schedule_revision_at, garantindo igualdade EXATA entre eles — nunca
    -- duas chamadas separadas que poderiam divergir por uma fração de
    -- segundo.
    creation_time := clock_timestamp();
    new.created_at = creation_time;
    new.schedule_revision = 0;
    new.schedule_revision_at = creation_time;
  elsif tg_op = 'UPDATE' then
    -- created_at nunca muda depois do INSERT, não importa o que o
    -- cliente tenha mandado.
    new.created_at = old.created_at;

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
-- é suficiente, não precisa recriar o trigger. Continua sendo o único
-- trigger de revision em appointments.

comment on column public.appointments.created_at is
  'Instante (timestamptz, absoluto) em que o appointment foi criado. '
  'Controlado exclusivamente pelo trigger appointments_set_schedule_revision '
  'via set_appointment_schedule_revision() desde a 0022 — o cliente nunca '
  'escolhe nem altera este valor, nem no INSERT nem em nenhum UPDATE '
  'posterior. Para schedule_revision=0, e por construcao sempre igual a '
  'schedule_revision_at (mesma chamada de clock_timestamp()).';

-- ---------------------------------------------------------------------
-- Check (read-only):
--   01_check   definição atual da função (deve conter created_at nos 2 ramos)
--   02_check   os 65 appointments existentes continuam com os mesmos valores
--              de created_at/schedule_revision/schedule_revision_at (nenhum
--              UPDATE foi feito por esta migration)
-- ---------------------------------------------------------------------
select '01_check' as secao, pg_get_functiondef(p.oid) as def
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'set_appointment_schedule_revision';

select '02_check' as secao, count(*) as total_appointments,
  count(*) filter (where schedule_revision = 0 and schedule_revision_at = created_at) as revision0_consistente
from public.appointments;
