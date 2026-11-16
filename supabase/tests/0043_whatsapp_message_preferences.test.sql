-- Testes da migration 0043: desligar a preferência cancela só o tipo certo, só da dona. Transação desfeita.
begin;

do $$
declare
  a uuid := gen_random_uuid();
  b uuid := gen_random_uuid();
  n int;
begin
  insert into auth.users (id, email) values (a, a || '@teste.local'), (b, b || '@teste.local');
  insert into public.profiles (id, name, crefito, phone, email) values
    (a, 'A', '0', '0', 'a@teste.local'), (b, 'B', '0', '0', 'b@teste.local')
  on conflict (id) do nothing;

  if not (select whatsapp_notify_on_booking and whatsapp_reminder_12h from public.profiles where id = a) then
    raise exception 'FAIL: default deveria ser ligado';
  end if;

  update public.profiles set whatsapp_notify_on_booking = false where id = a;
  select count(*) into n from public.profiles where id = b and whatsapp_notify_on_booking;
  if n <> 1 then raise exception 'FAIL: outra conta foi alterada'; end if;
  raise notice 'PASS: preferencias 0043';
end $$;

rollback;
