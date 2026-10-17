-- APLICADA EM PRODUÇÃO em 2026-10-17 (autorizada pelo usuário).
--
-- Objetivo: dar ao app offline-first um carimbo de versão CONFIÁVEL do
-- servidor (updated_at), para que o app trave a gravação de forma otimista
-- ("só atualize se a linha ainda é a que eu li") e feche a janela entre ler
-- e gravar na detecção de conflito. Sem esta migração o app já funciona: a
-- detecção usa comparação de 3 vias (base x servidor x alteração local) com
-- uma leitura antes da gravação; esta migração torna a checagem atômica.
--
-- Impacto (leia antes de aprovar):
--  * Aditiva: só adiciona colunas e triggers; não apaga nem reescreve dado.
--  * `add column ... default now()` em tabela pequena (patients ~4,
--    appointments ~82, financial_entries ~5 linhas hoje) é instantâneo.
--  * Um trigger BEFORE UPDATE passa a carimbar updated_at em TODO update,
--    inclusive os do webhook/dispatcher de WhatsApp em appointments (isso é
--    desejado: é uma alteração real). Ele NÃO toca em schedule_revision,
--    schedule_revision_at nem created_at (controlados por
--    appointments_set_schedule_revision, 0021/0022) e roda em ordem
--    alfabética de nome de trigger — o nome abaixo (zz_) roda por último.
--  * RLS e policies existentes continuam valendo (nenhuma é alterada).
--  * Cliente antigo ignora a coluna nova (select * devolve a mais; os
--    fromJson ignoram chaves desconhecidas).
--  * Reversível: drop trigger + drop column.
--
-- Não incluído de propósito: evolution_entries (a coluna updated_at dela já
-- existe, carimbada pelo cliente; o app trata evolução como "estrita" e
-- compara a linha inteira) e tombstones de exclusão definitiva de
-- appointments/evolution_entries (hoje o app trata linha ausente no servidor
-- como removida; tombstones só valem se houver sincronização incremental).

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := clock_timestamp();
  return new;
end;
$$;

alter table public.patients
  add column if not exists updated_at timestamptz not null default now();
alter table public.appointments
  add column if not exists updated_at timestamptz not null default now();
alter table public.financial_entries
  add column if not exists updated_at timestamptz not null default now();

drop trigger if exists zz_patients_touch_updated_at on public.patients;
create trigger zz_patients_touch_updated_at
  before update on public.patients
  for each row execute function public.touch_updated_at();

drop trigger if exists zz_appointments_touch_updated_at on public.appointments;
create trigger zz_appointments_touch_updated_at
  before update on public.appointments
  for each row execute function public.touch_updated_at();

drop trigger if exists zz_financial_touch_updated_at on public.financial_entries;
create trigger zz_financial_touch_updated_at
  before update on public.financial_entries
  for each row execute function public.touch_updated_at();
