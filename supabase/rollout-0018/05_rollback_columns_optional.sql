-- ROLLBACK da 0018, NÍVEL 2 (OPCIONAL): remove as duas colunas novas.
-- Rode SOMENTE depois do nível 1 e só se realmente quiser as colunas fora.
-- Estas colunas não existiam antes da 0018, então nenhum dado anterior é
-- perdido; mas se já houver valor nelas (alguém preencheu phone_e164 ou
-- mudou o fuso), o script ABORTA para não destruir esse dado novo.

do $$
declare
  n_phone bigint := 0;
  n_tz bigint := 0;
begin
  if exists (select 1 from information_schema.columns
             where table_schema='public' and table_name='patients' and column_name='phone_e164') then
    execute 'select count(*) from public.patients where phone_e164 is not null' into n_phone;
  end if;
  if exists (select 1 from information_schema.columns
             where table_schema='public' and table_name='profiles' and column_name='timezone') then
    execute 'select count(*) from public.profiles where timezone <> ''America/Sao_Paulo''' into n_tz;
  end if;
  if n_phone > 0 or n_tz > 0 then
    raise exception 'ABORTADO: colunas novas ja tem dados (phone_e164 preenchidos=%, profiles com fuso diferente do default=%).', n_phone, n_tz;
  end if;
end $$;

alter table public.patients drop column if exists phone_e164;
alter table public.profiles drop column if exists timezone;
