-- VALIDAÇÃO LOCAL COMPLETA da 0022 contra o schema real de produção, SEM
-- aplicar nada de verdade: tudo roda dentro de uma transação que termina
-- em ROLLBACK, nunca em COMMIT.
--
--   npx.cmd supabase db query -f supabase/rollout-0022/00_dry_run_full_validation.sql --linked --project-ref lchaboncmgcimafpupad
--
-- Cobre os 18 testes pedidos. Alguns usam pg_sleep(0.01) SOMENTE para
-- garantir, de forma deterministica, que duas chamadas de clock_timestamp()
-- em updates consecutivos difiram — robustez de teste, nunca entra em
-- código de produção.

begin;

create temporary table _wa_checkpoints (
  step text primary key,
  appointment_id text,
  created_at timestamptz,
  schedule_revision int,
  schedule_revision_at timestamptz
);

create temporary table _before_hash as
select md5(string_agg(
  id || '|' || fisioterapeuta_id::text || '|' || date::text || '|' || time::text || '|' ||
  patient_name || '|' || status || '|' || coalesce(patient_id, '<NULL>') || '|' ||
  created_at::text || '|' || schedule_revision::text || '|' || schedule_revision_at::text,
  ',' order by id
)) as h, count(*) as linhas
from public.appointments;

-- ======================================================================
-- PARTE 1 — aplica a migration 0022 (idêntico ao arquivo real)
-- ======================================================================

create or replace function public.set_appointment_schedule_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  creation_time timestamptz;
begin
  if tg_op = 'INSERT' then
    creation_time := clock_timestamp();
    new.created_at = creation_time;
    new.schedule_revision = 0;
    new.schedule_revision_at = creation_time;
  elsif tg_op = 'UPDATE' then
    new.created_at = old.created_at;
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

select 'migration 0022 aplicada (1a vez)' as fase;

-- ======================================================================
-- Nenhuma coluna antiga mudou (a 0022 não faz UPDATE em nenhuma linha)
-- ======================================================================

do $$
declare
  v_after_hash text;
  v_after_linhas int;
  v_before_hash text;
  v_before_linhas int;
begin
  select h, linhas into v_before_hash, v_before_linhas from _before_hash;
  select md5(string_agg(
    id || '|' || fisioterapeuta_id::text || '|' || date::text || '|' || time::text || '|' ||
    patient_name || '|' || status || '|' || coalesce(patient_id, '<NULL>') || '|' ||
    created_at::text || '|' || schedule_revision::text || '|' || schedule_revision_at::text,
    ',' order by id
  )), count(*)
  into v_after_hash, v_after_linhas
  from public.appointments;

  if v_before_hash <> v_after_hash or v_before_linhas <> v_after_linhas then
    raise exception 'FALHA: hash dos appointments existentes mudou so por aplicar a migration (antes=%/%  depois=%/%)',
      v_before_hash, v_before_linhas, v_after_hash, v_after_linhas;
  end if;
  raise notice 'OK: nenhum appointment existente mudou so por aplicar a migration 0022 (% linhas, hash identico)', v_after_linhas;
end $$;

-- ======================================================================
-- PARTE 2 — contexto de teste (fisioterapeuta real, agendamentos
-- FICTÍCIOS e descartáveis; nenhum dado real é tocado a partir daqui)
-- ======================================================================

create temporary table _wa_fisio as
select fisioterapeuta_id as fisio_id from public.appointments limit 1;

-- ======================================================================
-- TESTES 1, 2, 3 — INSERT normal: created_at preenchido pelo banco,
-- revision=0, revision_at == created_at EXATAMENTE.
-- ======================================================================

insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status)
select '__wa0022_t1__', fisio_id, '2026-10-20', '14:00:00', 'TESTE 0022 - IGNORAR', 'scheduled'
from _wa_fisio;

insert into _wa_checkpoints
select 'apos_insert', id, created_at, schedule_revision, schedule_revision_at
from public.appointments where id = '__wa0022_t1__';

do $$
declare
  v record;
begin
  select * into v from _wa_checkpoints where step = 'apos_insert';
  if v.created_at is null then raise exception 'FALHA teste 1: created_at nao foi preenchido pelo banco'; end if;
  if v.schedule_revision <> 0 then raise exception 'FALHA teste 2: esperado revision 0, veio %', v.schedule_revision; end if;
  if v.schedule_revision_at is distinct from v.created_at then
    raise exception 'FALHA teste 3: revision_at (%) difere de created_at (%)', v.schedule_revision_at, v.created_at;
  end if;
  raise notice 'OK testes 1/2/3: INSERT normal -> created_at=% preenchido pelo banco, revision=0, revision_at==created_at exatamente', v.created_at;
end $$;

-- ======================================================================
-- TESTES 4, 5 — INSERT tentando created_at no passado/futuro -> banco ignora.
-- ======================================================================

insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status, created_at)
select '__wa0022_t2__', fisio_id, '2026-10-20', '14:00:00', 'TESTE 0022 - IGNORAR', 'scheduled', '2000-01-01T00:00:00Z'
from _wa_fisio;

do $$
declare
  v_created_at timestamptz;
begin
  select created_at into v_created_at from public.appointments where id = '__wa0022_t2__';
  if v_created_at <= '2001-01-01'::timestamptz then
    raise exception 'FALHA teste 4: cliente conseguiu forjar created_at no passado (2000), veio %', v_created_at;
  end if;
  raise notice 'OK teste 4: created_at forjado no passado (2000) foi ignorado; banco usou %', v_created_at;
end $$;
delete from public.appointments where id = '__wa0022_t2__';

insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status, created_at)
select '__wa0022_t3__', fisio_id, '2026-10-20', '14:00:00', 'TESTE 0022 - IGNORAR', 'scheduled', '2099-01-01T00:00:00Z'
from _wa_fisio;

do $$
declare
  v_created_at timestamptz;
begin
  select created_at into v_created_at from public.appointments where id = '__wa0022_t3__';
  if v_created_at >= '2098-01-01'::timestamptz then
    raise exception 'FALHA teste 5: cliente conseguiu forjar created_at no futuro (2099), veio %', v_created_at;
  end if;
  raise notice 'OK teste 5: created_at forjado no futuro (2099) foi ignorado; banco usou %', v_created_at;
end $$;
delete from public.appointments where id = '__wa0022_t3__';

-- ======================================================================
-- TESTES 6, 7 — INSERT tentando schedule_revision=99 e schedule_revision_at
-- arbitrário -> banco ignora os dois.
-- ======================================================================

insert into public.appointments
  (id, fisioterapeuta_id, date, time, patient_name, status, schedule_revision, schedule_revision_at)
select '__wa0022_t4__', fisio_id, '2026-10-20', '14:00:00', 'TESTE 0022 - IGNORAR', 'scheduled', 99, '2099-01-01T00:00:00Z'
from _wa_fisio;

do $$
declare
  v_rev int;
  v_rev_at timestamptz;
  v_created_at timestamptz;
begin
  select schedule_revision, schedule_revision_at, created_at into v_rev, v_rev_at, v_created_at
  from public.appointments where id = '__wa0022_t4__';
  if v_rev <> 0 then raise exception 'FALHA teste 6: cliente conseguiu setar revision=99 no INSERT, veio %', v_rev; end if;
  if v_rev_at is distinct from v_created_at then
    raise exception 'FALHA teste 7: revision_at (%) nao ficou igual a created_at (%) apos cliente forjar 2099', v_rev_at, v_created_at;
  end if;
  raise notice 'OK testes 6/7: revision=99 e revision_at=2099 enviados pelo cliente no INSERT foram ignorados; banco usou revision=0 e revision_at=created_at (%)', v_rev_at;
end $$;
delete from public.appointments where id = '__wa0022_t4__';

-- ======================================================================
-- TESTES 8, 9 — UPDATE só patient_name / só status -> created_at,
-- revision e revision_at intactos.
-- ======================================================================

update public.appointments set patient_name = 'TESTE 0022 - RENOMEADO' where id = '__wa0022_t1__';
insert into _wa_checkpoints
select 'apos_patient_name', id, created_at, schedule_revision, schedule_revision_at
from public.appointments where id = '__wa0022_t1__';

update public.appointments set status = 'confirmed' where id = '__wa0022_t1__';
insert into _wa_checkpoints
select 'apos_status', id, created_at, schedule_revision, schedule_revision_at
from public.appointments where id = '__wa0022_t1__';

do $$
declare
  v_base record;
  v_name record;
  v_status record;
begin
  select * into v_base from _wa_checkpoints where step = 'apos_insert';
  select * into v_name from _wa_checkpoints where step = 'apos_patient_name';
  select * into v_status from _wa_checkpoints where step = 'apos_status';

  if v_name.created_at is distinct from v_base.created_at
     or v_name.schedule_revision <> v_base.schedule_revision
     or v_name.schedule_revision_at is distinct from v_base.schedule_revision_at then
    raise exception 'FALHA teste 8: UPDATE de patient_name mudou created_at/revision/revision_at';
  end if;
  if v_status.created_at is distinct from v_base.created_at
     or v_status.schedule_revision <> v_base.schedule_revision
     or v_status.schedule_revision_at is distinct from v_base.schedule_revision_at then
    raise exception 'FALHA teste 9: UPDATE de status mudou created_at/revision/revision_at';
  end if;
  raise notice 'OK testes 8/9: UPDATE so de patient_name/status nao muda created_at (%), revision (%) nem revision_at (%)', v_base.created_at, v_base.schedule_revision, v_base.schedule_revision_at;
end $$;

-- ======================================================================
-- TESTES 10, 11 — UPDATE tentando alterar só created_at, e created_at +
-- patient_name juntos -> banco restaura OLD.created_at nos dois casos.
-- ======================================================================

update public.appointments set created_at = '2099-01-01T00:00:00Z' where id = '__wa0022_t1__';
insert into _wa_checkpoints
select 'apos_created_at_manual', id, created_at, schedule_revision, schedule_revision_at
from public.appointments where id = '__wa0022_t1__';

update public.appointments set created_at = '2099-02-01T00:00:00Z', patient_name = 'TESTE 0022 - FORJADO' where id = '__wa0022_t1__';
insert into _wa_checkpoints
select 'apos_created_at_e_nome', id, created_at, schedule_revision, schedule_revision_at
from public.appointments where id = '__wa0022_t1__';

do $$
declare
  v_base record;
  v_manual record;
  v_combo record;
begin
  select * into v_base from _wa_checkpoints where step = 'apos_insert';
  select * into v_manual from _wa_checkpoints where step = 'apos_created_at_manual';
  select * into v_combo from _wa_checkpoints where step = 'apos_created_at_e_nome';

  if v_manual.created_at is distinct from v_base.created_at then
    raise exception 'FALHA teste 10: UPDATE so de created_at conseguiu alterar o valor (esperado %, veio %)', v_base.created_at, v_manual.created_at;
  end if;
  if v_combo.created_at is distinct from v_base.created_at then
    raise exception 'FALHA teste 11: UPDATE de created_at+patient_name conseguiu alterar created_at (esperado %, veio %)', v_base.created_at, v_combo.created_at;
  end if;
  raise notice 'OK testes 10/11: tentativas de alterar created_at (isolado e junto com patient_name) foram ignoradas; permanece %', v_base.created_at;
end $$;

-- ======================================================================
-- TESTES 12, 13 — UPDATE de date / time: created_at permanece OLD;
-- revision +1; revision_at muda.
-- ======================================================================

select pg_sleep(0.01);
update public.appointments set date = '2026-10-21' where id = '__wa0022_t1__';
insert into _wa_checkpoints
select 'apos_date', id, created_at, schedule_revision, schedule_revision_at
from public.appointments where id = '__wa0022_t1__';

do $$
declare
  v_base record;
  v_date record;
begin
  select * into v_base from _wa_checkpoints where step = 'apos_insert';
  select * into v_date from _wa_checkpoints where step = 'apos_date';
  if v_date.created_at is distinct from v_base.created_at then
    raise exception 'FALHA teste 12: UPDATE de date alterou created_at (esperado %, veio %)', v_base.created_at, v_date.created_at;
  end if;
  if v_date.schedule_revision <> 1 then raise exception 'FALHA teste 12: esperado revision 1, veio %', v_date.schedule_revision; end if;
  if not (v_date.schedule_revision_at > v_base.schedule_revision_at) then
    raise exception 'FALHA teste 12: revision_at deveria avancar (antes=% depois=%)', v_base.schedule_revision_at, v_date.schedule_revision_at;
  end if;
  raise notice 'OK teste 12: UPDATE de date -> created_at permanece % (OLD), revision vira %, revision_at avanca para %', v_date.created_at, v_date.schedule_revision, v_date.schedule_revision_at;
end $$;

select pg_sleep(0.01);
update public.appointments set time = '15:00:00' where id = '__wa0022_t1__';
insert into _wa_checkpoints
select 'apos_time', id, created_at, schedule_revision, schedule_revision_at
from public.appointments where id = '__wa0022_t1__';

do $$
declare
  v_date record;
  v_time record;
begin
  select * into v_date from _wa_checkpoints where step = 'apos_date';
  select * into v_time from _wa_checkpoints where step = 'apos_time';
  if v_time.created_at is distinct from v_date.created_at then
    raise exception 'FALHA teste 13: UPDATE de time alterou created_at';
  end if;
  if v_time.schedule_revision <> 2 then raise exception 'FALHA teste 13: esperado revision 2, veio %', v_time.schedule_revision; end if;
  if not (v_time.schedule_revision_at > v_date.schedule_revision_at) then
    raise exception 'FALHA teste 13: revision_at deveria avancar';
  end if;
  raise notice 'OK teste 13: UPDATE de time -> created_at permanece %, revision vira %, revision_at avanca', v_time.created_at, v_time.schedule_revision;
end $$;

-- ======================================================================
-- TESTE 14 — UPDATE date+time+created_at forjado juntos: created_at
-- permanece OLD; revision incrementa so 1; revision_at usa clock_timestamp().
-- ======================================================================

select pg_sleep(0.01);
update public.appointments
set date = '2026-10-22', time = '16:00:00', created_at = '2099-03-01T00:00:00Z'
where id = '__wa0022_t1__';
insert into _wa_checkpoints
select 'apos_date_time_created_forjado', id, created_at, schedule_revision, schedule_revision_at
from public.appointments where id = '__wa0022_t1__';

do $$
declare
  v_time record;
  v_forjado record;
begin
  select * into v_time from _wa_checkpoints where step = 'apos_time';
  select * into v_forjado from _wa_checkpoints where step = 'apos_date_time_created_forjado';
  if v_forjado.created_at is distinct from v_time.created_at then
    raise exception 'FALHA teste 14: created_at forjado (2099) junto com date+time conseguiu passar, veio %', v_forjado.created_at;
  end if;
  if v_forjado.schedule_revision <> 3 then raise exception 'FALHA teste 14: esperado incremento unico para revision 3, veio %', v_forjado.schedule_revision; end if;
  if not (v_forjado.schedule_revision_at > v_time.schedule_revision_at) then
    raise exception 'FALHA teste 14: revision_at deveria usar clock_timestamp() e avancar';
  end if;
  raise notice 'OK teste 14: date+time+created_at forjado juntos -> created_at permanece %, revision vira % (incremento unico), revision_at avanca para %', v_forjado.created_at, v_forjado.schedule_revision, v_forjado.schedule_revision_at;
end $$;

-- ======================================================================
-- TESTE 15 — cliente tenta alterar created_at + schedule_revision +
-- schedule_revision_at NUM UPDATE sem mudar date/time -> os 3 restauram OLD.
-- ======================================================================

update public.appointments
set created_at = '2099-04-01T00:00:00Z', schedule_revision = 777, schedule_revision_at = '2099-04-01T00:00:00Z'
where id = '__wa0022_t1__';
insert into _wa_checkpoints
select 'apos_tres_campos_forjados', id, created_at, schedule_revision, schedule_revision_at
from public.appointments where id = '__wa0022_t1__';

do $$
declare
  v_antes record;
  v_depois record;
begin
  select * into v_antes from _wa_checkpoints where step = 'apos_date_time_created_forjado';
  select * into v_depois from _wa_checkpoints where step = 'apos_tres_campos_forjados';
  if v_depois.created_at is distinct from v_antes.created_at
     or v_depois.schedule_revision <> v_antes.schedule_revision
     or v_depois.schedule_revision_at is distinct from v_antes.schedule_revision_at then
    raise exception 'FALHA teste 15: algum dos 3 campos forjados (created_at/revision/revision_at) sem mudar date/time nao foi restaurado para OLD';
  end if;
  raise notice 'OK teste 15: tentativa de forjar created_at+revision+revision_at sem mudar date/time foi totalmente ignorada; permanecem % / % / %', v_depois.created_at, v_depois.schedule_revision, v_depois.schedule_revision_at;
end $$;

-- ======================================================================
-- TESTE 16 — A -> B -> A -> B: created_at absolutamente constante,
-- revision termina em 3, revision_at muda em cada remarcação.
-- ======================================================================

insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status)
select '__wa0022_abab__', fisio_id, '2026-10-01', '09:00:00', 'TESTE 0022 - ABAB', 'scheduled'
from _wa_fisio;
insert into _wa_checkpoints
select 'abab_0', id, created_at, schedule_revision, schedule_revision_at from public.appointments where id = '__wa0022_abab__';

select pg_sleep(0.01);
update public.appointments set date = '2026-10-02' where id = '__wa0022_abab__';
insert into _wa_checkpoints
select 'abab_1', id, created_at, schedule_revision, schedule_revision_at from public.appointments where id = '__wa0022_abab__';

select pg_sleep(0.01);
update public.appointments set date = '2026-10-01' where id = '__wa0022_abab__';
insert into _wa_checkpoints
select 'abab_2', id, created_at, schedule_revision, schedule_revision_at from public.appointments where id = '__wa0022_abab__';

select pg_sleep(0.01);
update public.appointments set date = '2026-10-02' where id = '__wa0022_abab__';
insert into _wa_checkpoints
select 'abab_3', id, created_at, schedule_revision, schedule_revision_at from public.appointments where id = '__wa0022_abab__';

do $$
declare
  v0 record; v1 record; v2 record; v3 record;
begin
  select * into v0 from _wa_checkpoints where step = 'abab_0';
  select * into v1 from _wa_checkpoints where step = 'abab_1';
  select * into v2 from _wa_checkpoints where step = 'abab_2';
  select * into v3 from _wa_checkpoints where step = 'abab_3';

  if not (v0.created_at = v1.created_at and v1.created_at = v2.created_at and v2.created_at = v3.created_at) then
    raise exception 'FALHA teste 16: created_at deveria ser absolutamente constante (0:% 1:% 2:% 3:%)',
      v0.created_at, v1.created_at, v2.created_at, v3.created_at;
  end if;

  if (v0.schedule_revision, v1.schedule_revision, v2.schedule_revision, v3.schedule_revision) <> (0, 1, 2, 3) then
    raise exception 'FALHA teste 16: revisions deveriam ser 0,1,2,3 -- vieram %,%,%,%',
      v0.schedule_revision, v1.schedule_revision, v2.schedule_revision, v3.schedule_revision;
  end if;

  if not (v0.schedule_revision_at < v1.schedule_revision_at
      and v1.schedule_revision_at < v2.schedule_revision_at
      and v2.schedule_revision_at < v3.schedule_revision_at) then
    raise exception 'FALHA teste 16: os 4 revision_at deveriam ser estritamente crescentes';
  end if;

  raise notice 'OK teste 16: A->B->A->B -> created_at constante (%), revision termina em 3, revision_at cresce em cada remarcacao (0:%, 1:%, 2:%, 3:%)',
    v0.created_at, v0.schedule_revision_at, v1.schedule_revision_at, v2.schedule_revision_at, v3.schedule_revision_at;
end $$;

-- ======================================================================
-- TESTE 17 — migration aplicada DUAS VEZES: sem erro.
-- ======================================================================

create or replace function public.set_appointment_schedule_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  creation_time timestamptz;
begin
  if tg_op = 'INSERT' then
    creation_time := clock_timestamp();
    new.created_at = creation_time;
    new.schedule_revision = 0;
    new.schedule_revision_at = creation_time;
  elsif tg_op = 'UPDATE' then
    new.created_at = old.created_at;
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

select 'OK teste 17: migration 0022 reaplicada uma 2a vez sem erro (idempotente)' as resultado;

-- ======================================================================
-- TESTE 18 — migration + rollback: restaura exatamente a função da 0021.
-- ======================================================================

delete from public.appointments where id in ('__wa0022_t1__', '__wa0022_abab__');

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

do $$
declare
  v_func_def text;
begin
  select pg_get_functiondef(p.oid) into v_func_def
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='set_appointment_schedule_revision';

  if position('creation_time' in v_func_def) > 0 then
    raise exception 'FALHA teste 18: funcao ainda menciona creation_time (0022) apos o rollback';
  end if;
  if position('new.created_at = new.created_at' in v_func_def) > 0 then
    -- apenas defensivo; nao deveria ocorrer
    raise exception 'FALHA teste 18: funcao com logica inesperada apos o rollback';
  end if;

  raise notice 'OK teste 18: migration 0022 + rollback restauram exatamente a funcao da 0021 (sem protecao de created_at)';
end $$;

select 'rollback_ok' as resultado, 'nada disto sera persistido' as nota;

rollback;
