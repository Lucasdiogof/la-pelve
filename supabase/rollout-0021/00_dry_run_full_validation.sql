-- VALIDAÇÃO LOCAL COMPLETA da 0021 (v2, corrigida) contra o schema real de
-- produção, SEM aplicar nada de verdade: tudo roda dentro de uma transação
-- que termina em ROLLBACK, nunca em COMMIT.
--
--   npx.cmd supabase db query -f supabase/rollout-0021/00_dry_run_full_validation.sql --linked --project-ref lchaboncmgcimafpupad
--
-- v2: corrige o INSERT para usar NEW.schedule_revision_at = NEW.created_at
-- (em vez de clock_timestamp()), garantindo igualdade EXATA entre os dois
-- para revision 0. Cobre os 12 testes pedidos na correção.
--
-- NOTA: alguns testes usam pg_sleep(0.01) SOMENTE para garantir, de forma
-- determinística, que duas chamadas de clock_timestamp() em updates
-- consecutivos difiram — isso é só uma robustez de teste, nunca entra em
-- código de produção (o trigger real nunca usa sleep).

begin;

create temporary table _wa_checkpoints (
  step text primary key,
  appointment_id text,
  schedule_revision int,
  schedule_revision_at timestamptz,
  created_at timestamptz
);

create temporary table _before_hash as
select md5(string_agg(
  id || '|' || fisioterapeuta_id::text || '|' || date::text || '|' || time::text || '|' ||
  patient_name || '|' || status || '|' || coalesce(patient_id, '<NULL>') || '|' || created_at::text,
  ',' order by id
)) as h, count(*) as linhas
from public.appointments;

-- ======================================================================
-- PARTE 1 — aplica a migration 0021 corrigida (idêntico ao arquivo real)
-- ======================================================================

alter table public.appointments
  add column if not exists schedule_revision_at timestamptz;

update public.appointments
set schedule_revision_at = created_at
where schedule_revision_at is null;

do $$
begin
  if exists (select 1 from public.appointments where schedule_revision_at is null) then
    raise exception 'MIGRATION ABORTADA: sobrou schedule_revision_at nulo apos o backfill';
  end if;
end $$;

alter table public.appointments alter column schedule_revision_at set default now();
alter table public.appointments alter column schedule_revision_at set not null;

create or replace function public.set_appointment_schedule_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.schedule_revision = 0;
    new.schedule_revision_at = new.created_at;
  elsif tg_op = 'UPDATE' then
    if new.date is distinct from old.date or new.time is distinct from old.time then
      new.schedule_revision = old.schedule_revision + 1;
      new.schedule_revision_at = clock_timestamp();
    else
      new.schedule_revision = old.schedule_revision;
      new.schedule_revision_at = old.schedule_revision_at;
    end if;
  end if;
  return new;
end;
$$;

select 'migration aplicada (1a vez)' as fase;

-- ======================================================================
-- TESTE 1 — appointment ANTIGO (backfill dos 65 reais): revision_at ==
-- created_at. Nenhuma coluna antiga mudou (hash idêntico).
-- ======================================================================

do $$
declare
  v_after_hash text;
  v_after_linhas int;
  v_before_hash text;
  v_before_linhas int;
  v_diff_count int;
begin
  select h, linhas into v_before_hash, v_before_linhas from _before_hash;

  select md5(string_agg(
    id || '|' || fisioterapeuta_id::text || '|' || date::text || '|' || time::text || '|' ||
    patient_name || '|' || status || '|' || coalesce(patient_id, '<NULL>') || '|' || created_at::text,
    ',' order by id
  )), count(*)
  into v_after_hash, v_after_linhas
  from public.appointments;

  if v_before_hash <> v_after_hash or v_before_linhas <> v_after_linhas then
    raise exception 'FALHA teste 1: hash das 8 colunas antigas mudou apos a migration (antes=%/%  depois=%/%)',
      v_before_hash, v_before_linhas, v_after_hash, v_after_linhas;
  end if;

  select count(*) into v_diff_count
  from public.appointments where schedule_revision_at <> created_at;
  if v_diff_count <> 0 then
    raise exception 'FALHA teste 1: % appointments reais (backfill) com schedule_revision_at != created_at', v_diff_count;
  end if;
  raise notice 'OK teste 1: todos os appointments antigos (revision 0, backfill) tem schedule_revision_at = created_at; nenhuma das 8 colunas antigas mudou (% linhas)', v_after_linhas;
end $$;

-- ======================================================================
-- PARTE 2 — contexto de teste (fisioterapeuta real, agendamentos
-- FICTÍCIOS e descartáveis; nenhum dado real é tocado a partir daqui)
-- ======================================================================

create temporary table _wa_fisio as
select fisioterapeuta_id as fisio_id from public.appointments limit 1;

-- ======================================================================
-- TESTE 2 — appointment NOVO após a migration: revision = 0;
-- revision_at == created_at EXATAMENTE (igualdade, não só "nao nulo").
-- ======================================================================

insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status)
select '__wa0021_t1__', fisio_id, '2026-10-10', '14:00:00', 'TESTE 0021 - IGNORAR', 'scheduled'
from _wa_fisio;

insert into _wa_checkpoints
select 'apos_insert', id, schedule_revision, schedule_revision_at, created_at
from public.appointments where id = '__wa0021_t1__';

do $$
declare
  v record;
begin
  select * into v from _wa_checkpoints where step = 'apos_insert';
  if v.schedule_revision <> 0 then raise exception 'FALHA teste 2: esperado revision 0, veio %', v.schedule_revision; end if;
  if v.schedule_revision_at is distinct from v.created_at then
    raise exception 'FALHA teste 2: revision_at (%) difere de created_at (%) no INSERT novo', v.schedule_revision_at, v.created_at;
  end if;
  raise notice 'OK teste 2: INSERT novo comeca em revision 0 com schedule_revision_at == created_at EXATAMENTE (%)', v.created_at;
end $$;

-- ======================================================================
-- TESTES 3 e 4 — cliente manda schedule_revision_at arbitrario e
-- schedule_revision=50 no INSERT -> banco ignora os dois: revision=0,
-- revision_at = NEW.created_at (nao o valor forjado).
-- ======================================================================

insert into public.appointments
  (id, fisioterapeuta_id, date, time, patient_name, status, schedule_revision, schedule_revision_at)
select '__wa0021_t2__', fisio_id, '2026-10-10', '14:00:00', 'TESTE 0021 - IGNORAR', 'scheduled', 50, '2099-01-01T00:00:00Z'
from _wa_fisio;

do $$
declare
  v_rev int;
  v_rev_at timestamptz;
  v_created_at timestamptz;
begin
  select schedule_revision, schedule_revision_at, created_at into v_rev, v_rev_at, v_created_at
  from public.appointments where id = '__wa0021_t2__';

  if v_rev <> 0 then raise exception 'FALHA teste 4: cliente conseguiu setar revision=50 no INSERT, veio %', v_rev; end if;
  if v_rev_at is distinct from v_created_at then
    raise exception 'FALHA teste 3: revision_at (%) nao ficou igual a created_at (%) apos cliente forjar 2099 no INSERT', v_rev_at, v_created_at;
  end if;
  raise notice 'OK testes 3/4: revision=50 e revision_at=2099 enviados pelo cliente no INSERT foram ignorados; banco usou revision=0 e revision_at=created_at (%)', v_rev_at;
end $$;

delete from public.appointments where id = '__wa0021_t2__';

-- ======================================================================
-- TESTE 5 — UPDATE sem mudança de date/time (patient_name, status,
-- patient_id) -> revision e revision_at permanecem EXATAMENTE iguais.
-- ======================================================================

update public.appointments set patient_name = 'TESTE 0021 - RENOMEADO' where id = '__wa0021_t1__';
insert into _wa_checkpoints
select 'apos_patient_name', id, schedule_revision, schedule_revision_at, created_at
from public.appointments where id = '__wa0021_t1__';

update public.appointments set status = 'confirmed' where id = '__wa0021_t1__';
insert into _wa_checkpoints
select 'apos_status', id, schedule_revision, schedule_revision_at, created_at
from public.appointments where id = '__wa0021_t1__';

update public.appointments set patient_id = null where id = '__wa0021_t1__';
insert into _wa_checkpoints
select 'apos_patient_id', id, schedule_revision, schedule_revision_at, created_at
from public.appointments where id = '__wa0021_t1__';

-- cliente tenta forjar revision_at/revision manualmente SEM mudar date/time
update public.appointments set schedule_revision_at = '2099-01-01T00:00:00Z' where id = '__wa0021_t1__';
insert into _wa_checkpoints
select 'apos_revision_at_manual', id, schedule_revision, schedule_revision_at, created_at
from public.appointments where id = '__wa0021_t1__';

update public.appointments set schedule_revision = 999 where id = '__wa0021_t1__';
insert into _wa_checkpoints
select 'apos_revision_manual', id, schedule_revision, schedule_revision_at, created_at
from public.appointments where id = '__wa0021_t1__';

do $$
declare
  v_base record;
  v_name record;
  v_status record;
  v_pid record;
  v_rev_at_manual record;
  v_rev_manual record;
begin
  select * into v_base from _wa_checkpoints where step = 'apos_insert';
  select * into v_name from _wa_checkpoints where step = 'apos_patient_name';
  select * into v_status from _wa_checkpoints where step = 'apos_status';
  select * into v_pid from _wa_checkpoints where step = 'apos_patient_id';
  select * into v_rev_at_manual from _wa_checkpoints where step = 'apos_revision_at_manual';
  select * into v_rev_manual from _wa_checkpoints where step = 'apos_revision_manual';

  if v_name.schedule_revision <> v_base.schedule_revision or v_name.schedule_revision_at is distinct from v_base.schedule_revision_at then
    raise exception 'FALHA teste 5: patient_name mudou revision/revision_at';
  end if;
  if v_status.schedule_revision <> v_base.schedule_revision or v_status.schedule_revision_at is distinct from v_base.schedule_revision_at then
    raise exception 'FALHA teste 5: status mudou revision/revision_at';
  end if;
  if v_pid.schedule_revision <> v_base.schedule_revision or v_pid.schedule_revision_at is distinct from v_base.schedule_revision_at then
    raise exception 'FALHA teste 5: patient_id mudou revision/revision_at';
  end if;
  if v_rev_at_manual.schedule_revision_at is distinct from v_base.schedule_revision_at then
    raise exception 'FALHA teste 5: cliente conseguiu forjar revision_at=2099 sem mudar horario, veio %', v_rev_at_manual.schedule_revision_at;
  end if;
  if v_rev_manual.schedule_revision <> v_base.schedule_revision then
    raise exception 'FALHA teste 5: cliente conseguiu forjar revision=999 sem mudar horario, veio %', v_rev_manual.schedule_revision;
  end if;
  raise notice 'OK teste 5: UPDATEs sem mudanca de date/time (patient_name, status, patient_id, e tentativas de forjar revision/revision_at) preservam revision e revision_at EXATAMENTE iguais (%, %)', v_base.schedule_revision, v_base.schedule_revision_at;
end $$;

-- ======================================================================
-- TESTE 6 — UPDATE de date -> revision +1; revision_at passa a ser
-- clock_timestamp() da alteracao (diferente do anterior, posterior a ele).
-- ======================================================================

select pg_sleep(0.01);
update public.appointments set date = '2026-10-11' where id = '__wa0021_t1__';
insert into _wa_checkpoints
select 'apos_date', id, schedule_revision, schedule_revision_at, created_at
from public.appointments where id = '__wa0021_t1__';

do $$
declare
  v_a record;
  v_b record;
begin
  select * into v_a from _wa_checkpoints where step = 'apos_insert';
  select * into v_b from _wa_checkpoints where step = 'apos_date';
  if v_b.schedule_revision <> 1 then raise exception 'FALHA teste 6: esperado revision 1, veio %', v_b.schedule_revision; end if;
  if not (v_b.schedule_revision_at > v_a.schedule_revision_at) then
    raise exception 'FALHA teste 6: revision_at deveria ser estritamente posterior ao anterior (antes=% depois=%)', v_a.schedule_revision_at, v_b.schedule_revision_at;
  end if;
  raise notice 'OK teste 6: alterar date incrementa revision (agora %) e revision_at passa a ser clock_timestamp() da alteracao (de % para %)', v_b.schedule_revision, v_a.schedule_revision_at, v_b.schedule_revision_at;
end $$;

-- ======================================================================
-- TESTE 7 — UPDATE de time -> mesma regra.
-- ======================================================================

select pg_sleep(0.01);
update public.appointments set time = '15:00:00' where id = '__wa0021_t1__';
insert into _wa_checkpoints
select 'apos_time', id, schedule_revision, schedule_revision_at, created_at
from public.appointments where id = '__wa0021_t1__';

do $$
declare
  v_a record;
  v_b record;
begin
  select * into v_a from _wa_checkpoints where step = 'apos_date';
  select * into v_b from _wa_checkpoints where step = 'apos_time';
  if v_b.schedule_revision <> 2 then raise exception 'FALHA teste 7: esperado revision 2, veio %', v_b.schedule_revision; end if;
  if not (v_b.schedule_revision_at > v_a.schedule_revision_at) then
    raise exception 'FALHA teste 7: revision_at deveria ser estritamente posterior ao anterior (antes=% depois=%)', v_a.schedule_revision_at, v_b.schedule_revision_at;
  end if;
  raise notice 'OK teste 7: alterar time incrementa revision (agora %) e revision_at avanca (de % para %)', v_b.schedule_revision, v_a.schedule_revision_at, v_b.schedule_revision_at;
end $$;

-- ======================================================================
-- TESTE 8 — date + time no mesmo UPDATE -> somente UMA nova revisao.
-- ======================================================================

select pg_sleep(0.01);
update public.appointments set date = '2026-10-12', time = '16:00:00' where id = '__wa0021_t1__';
insert into _wa_checkpoints
select 'apos_date_e_time', id, schedule_revision, schedule_revision_at, created_at
from public.appointments where id = '__wa0021_t1__';

do $$
declare
  v_a record;
  v_b record;
begin
  select * into v_a from _wa_checkpoints where step = 'apos_time';
  select * into v_b from _wa_checkpoints where step = 'apos_date_e_time';
  if v_b.schedule_revision <> 3 then raise exception 'FALHA teste 8: esperado revision 3 (incremento unico), veio %', v_b.schedule_revision; end if;
  if not (v_b.schedule_revision_at > v_a.schedule_revision_at) then
    raise exception 'FALHA teste 8: revision_at deveria avancar exatamente 1 vez (antes=% depois=%)', v_a.schedule_revision_at, v_b.schedule_revision_at;
  end if;
  raise notice 'OK teste 8: date+time juntos incrementam revision so 1 vez (agora %) com 1 novo revision_at (%)', v_b.schedule_revision, v_b.schedule_revision_at;
end $$;

-- ======================================================================
-- TESTE 9 — duas remarcacoes em momentos diferentes: revision_at da
-- segunda deve ser estritamente posterior a da primeira (sem sleep no
-- codigo de producao; aqui so no teste, para robustez deterministica).
-- ======================================================================

select pg_sleep(0.01);
update public.appointments set date = '2026-10-13' where id = '__wa0021_t1__'; -- remarcacao 1 desta etapa (revision 4)
insert into _wa_checkpoints
select 'apos_remarcacao_1', id, schedule_revision, schedule_revision_at, created_at
from public.appointments where id = '__wa0021_t1__';

select pg_sleep(0.01);
update public.appointments set date = '2026-10-14' where id = '__wa0021_t1__'; -- remarcacao 2 (revision 5)
insert into _wa_checkpoints
select 'apos_remarcacao_2', id, schedule_revision, schedule_revision_at, created_at
from public.appointments where id = '__wa0021_t1__';

do $$
declare
  v1 record;
  v2 record;
begin
  select * into v1 from _wa_checkpoints where step = 'apos_remarcacao_1';
  select * into v2 from _wa_checkpoints where step = 'apos_remarcacao_2';
  if v2.schedule_revision <> v1.schedule_revision + 1 then
    raise exception 'FALHA teste 9: esperado incremento de 1 entre remarcacoes, veio % -> %', v1.schedule_revision, v2.schedule_revision;
  end if;
  if not (v2.schedule_revision_at > v1.schedule_revision_at) then
    raise exception 'FALHA teste 9: revision_at da 2a remarcacao deveria ser posterior a da 1a (1a=% 2a=%)', v1.schedule_revision_at, v2.schedule_revision_at;
  end if;
  raise notice 'OK teste 9: duas remarcacoes em momentos diferentes produzem revision_at estritamente crescente (1a=%, 2a=%)', v1.schedule_revision_at, v2.schedule_revision_at;
end $$;

-- ======================================================================
-- TESTE 10 — A -> B -> A -> B: revision termina em 3 (num fixture
-- separado, do zero), cada revisao com seu proprio revision_at crescente.
-- ======================================================================

insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status)
select '__wa0021_abab__', fisio_id, '2026-10-01', '09:00:00', 'TESTE 0021 - ABAB', 'scheduled'
from _wa_fisio;
insert into _wa_checkpoints
select 'abab_0', id, schedule_revision, schedule_revision_at, created_at from public.appointments where id = '__wa0021_abab__';

select pg_sleep(0.01);
update public.appointments set date = '2026-10-02' where id = '__wa0021_abab__'; -- B
insert into _wa_checkpoints
select 'abab_1', id, schedule_revision, schedule_revision_at, created_at from public.appointments where id = '__wa0021_abab__';

select pg_sleep(0.01);
update public.appointments set date = '2026-10-01' where id = '__wa0021_abab__'; -- A de novo
insert into _wa_checkpoints
select 'abab_2', id, schedule_revision, schedule_revision_at, created_at from public.appointments where id = '__wa0021_abab__';

select pg_sleep(0.01);
update public.appointments set date = '2026-10-02' where id = '__wa0021_abab__'; -- B de novo
insert into _wa_checkpoints
select 'abab_3', id, schedule_revision, schedule_revision_at, created_at from public.appointments where id = '__wa0021_abab__';

do $$
declare
  v0 record; v1 record; v2 record; v3 record;
begin
  select * into v0 from _wa_checkpoints where step = 'abab_0';
  select * into v1 from _wa_checkpoints where step = 'abab_1';
  select * into v2 from _wa_checkpoints where step = 'abab_2';
  select * into v3 from _wa_checkpoints where step = 'abab_3';

  if (v0.schedule_revision, v1.schedule_revision, v2.schedule_revision, v3.schedule_revision) <> (0, 1, 2, 3) then
    raise exception 'FALHA teste 10: revisions deveriam ser 0,1,2,3 -- vieram %,%,%,%',
      v0.schedule_revision, v1.schedule_revision, v2.schedule_revision, v3.schedule_revision;
  end if;

  if v0.schedule_revision_at is distinct from v0.created_at then
    raise exception 'FALHA teste 10: revision 0 (abab_0) deveria ter revision_at == created_at, veio % vs %', v0.schedule_revision_at, v0.created_at;
  end if;

  if not (v0.schedule_revision_at < v1.schedule_revision_at
      and v1.schedule_revision_at < v2.schedule_revision_at
      and v2.schedule_revision_at < v3.schedule_revision_at) then
    raise exception
      'FALHA teste 10: os 4 revision_at deveriam ser estritamente crescentes (0:% 1:% 2:% 3:%)',
      v0.schedule_revision_at, v1.schedule_revision_at, v2.schedule_revision_at, v3.schedule_revision_at;
  end if;
  raise notice
    'OK teste 10: A->B->A->B termina em revision 3; revision 0 nasce com revision_at==created_at (%); os 4 revision_at (0:%, 1:%, 2:%, 3:%) sao todos distintos e crescentes, mesmo com o valor de data repetindo',
    v0.created_at, v0.schedule_revision_at, v1.schedule_revision_at, v2.schedule_revision_at, v3.schedule_revision_at;
end $$;

-- ======================================================================
-- TESTE 11 — reaplicar a migration inteira (idempotencia): sem erro.
-- ======================================================================

alter table public.appointments add column if not exists schedule_revision_at timestamptz;
update public.appointments set schedule_revision_at = created_at where schedule_revision_at is null;
do $$
begin
  if exists (select 1 from public.appointments where schedule_revision_at is null) then
    raise exception 'FALHA teste 11: sobrou nulo na 2a aplicacao';
  end if;
end $$;
alter table public.appointments alter column schedule_revision_at set default now();
alter table public.appointments alter column schedule_revision_at set not null;
create or replace function public.set_appointment_schedule_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.schedule_revision = 0;
    new.schedule_revision_at = new.created_at;
  elsif tg_op = 'UPDATE' then
    if new.date is distinct from old.date or new.time is distinct from old.time then
      new.schedule_revision = old.schedule_revision + 1;
      new.schedule_revision_at = clock_timestamp();
    else
      new.schedule_revision = old.schedule_revision;
      new.schedule_revision_at = old.schedule_revision_at;
    end if;
  end if;
  return new;
end;
$$;

select 'OK teste 11: migration reaplicada uma 2a vez sem erro (idempotente)' as resultado;

-- ======================================================================
-- TESTE 12 — migration + rollback (v2, com a trava revisada):
--   12a) trava obrigatoria ainda aborta quando ha schedule_revision > 0;
--   12b) divergencia legitima em revision 0 (created_at corrigido depois
--        da criacao, sem tocar schedule_revision_at) gera AVISO mas NAO
--        aborta o rollback (prova de que a trava nao e um falso positivo);
--   12c) rollback aplicado de fato restaura o estado pos-0020 quando
--        seguro.
-- ======================================================================

-- 12a: confirma que a trava obrigatoria dispara com os dados de teste
-- atuais (que tem revision > 0), capturada para nao abortar a validacao.
do $$
begin
  begin
    if exists (select 1 from public.appointments where schedule_revision > 0) then
      raise exception 'ROLLBACK ABORTADO: existe appointment com schedule_revision > 0';
    end if;
    raise exception 'FALHA teste 12a: a trava obrigatoria nao disparou mesmo havendo revision > 0';
  exception
    when others then
      if sqlerrm like 'ROLLBACK ABORTADO%' then
        raise notice 'OK teste 12a: a trava obrigatoria aborta corretamente quando existe schedule_revision > 0 (%)', sqlerrm;
      else
        raise;
      end if;
  end;
end $$;

-- Limpa os dados de teste com revision > 0 (descartaveis) para poder
-- validar o cenario "seguro" (12b e 12c).
delete from public.appointments where id in ('__wa0021_t1__', '__wa0021_abab__');

-- 12b: cria uma divergencia LEGITIMA em revision 0 — insere um
-- appointment novo (revision 0, revision_at == created_at por
-- construcao) e depois corrige created_at manualmente (simulando um
-- ajuste administrativo fora do fluxo do app), sem tocar
-- schedule_revision_at. Isso NAO deveria abortar o rollback.
insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status)
select '__wa0021_divergente__', fisio_id, '2026-10-15', '10:00:00', 'TESTE 0021 - DIVERGENTE', 'scheduled'
from _wa_fisio;

update public.appointments set created_at = created_at - interval '3 days'
where id = '__wa0021_divergente__';

do $$
declare
  v_divergentes int;
begin
  select count(*) into v_divergentes
  from public.appointments
  where id = '__wa0021_divergente__' and schedule_revision = 0 and schedule_revision_at is distinct from created_at;
  if v_divergentes <> 1 then
    raise exception 'FALHA teste 12b (setup): esperava 1 linha divergente para simular o cenario, veio %', v_divergentes;
  end if;

  if exists (select 1 from public.appointments where schedule_revision > 0) then
    raise exception 'FALHA teste 12b (setup): ainda ha appointments de teste com revision > 0 sobrando';
  end if;

  -- Reproduz a trava revisada do rollback: so aborta por revision > 0;
  -- a divergencia de revision 0 so gera NOTICE.
  if exists (select 1 from public.appointments where schedule_revision > 0) then
    raise exception 'ROLLBACK ABORTADO: existe appointment com schedule_revision > 0';
  end if;

  if v_divergentes > 0 then
    raise notice 'OK teste 12b: divergencia legitima em revision 0 (created_at corrigido manualmente) gera AVISO mas NAO aborta o rollback (% linha(s))', v_divergentes;
  end if;
end $$;

delete from public.appointments where id = '__wa0021_divergente__';

-- 12c: aplica o rollback de fato (igual ao 03_rollback.sql) e confirma
-- que restaura exatamente o estado pos-0020.
create or replace function public.set_appointment_schedule_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.schedule_revision = 0;
  elsif tg_op = 'UPDATE' then
    if new.date is distinct from old.date or new.time is distinct from old.time then
      new.schedule_revision = old.schedule_revision + 1;
    else
      new.schedule_revision = old.schedule_revision;
    end if;
  end if;
  return new;
end;
$$;
alter table public.appointments drop column if exists schedule_revision_at;

do $$
declare
  v_col_exists boolean;
  v_func_def text;
begin
  select exists (select 1 from information_schema.columns where table_name='appointments' and column_name='schedule_revision_at')
    into v_col_exists;
  if v_col_exists then raise exception 'FALHA teste 12c: schedule_revision_at ainda existe apos o rollback'; end if;

  select pg_get_functiondef(p.oid) into v_func_def
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='set_appointment_schedule_revision';
  if position('schedule_revision_at' in v_func_def) > 0 then
    raise exception 'FALHA teste 12c: funcao ainda menciona schedule_revision_at apos o rollback';
  end if;

  raise notice 'OK teste 12c: migration + rollback restauram exatamente o estado pos-0020 quando seguro (sem revision > 0)';
end $$;

select 'rollback_ok' as resultado, 'nada disto sera persistido' as nota;

rollback;
