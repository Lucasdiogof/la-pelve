-- Testes da migration 0041: exclusão definitiva com 30 dias de arrependimento. Transação desfeita; dados fictícios.
begin;

create function pg_temp.check(cond boolean, label text) returns void
language plpgsql as $$
begin
  if cond is not true then raise exception 'FAIL: %', label; end if;
  raise notice 'PASS: %', label;
end $$;

create function pg_temp.new_user() returns uuid
language plpgsql as $$
declare v_id uuid;
begin
  insert into auth.users (id, email) values (gen_random_uuid(), gen_random_uuid() || '@teste.local') returning id into v_id;
  insert into public.profiles (id, name, crefito, phone, email) values (v_id, 'Teste', '0', '0', 'x@teste.local') on conflict (id) do nothing;
  return v_id;
end $$;

create function pg_temp.act_as(p_id uuid) returns void
language sql as $$ select set_config('request.jwt.claim.sub', p_id::text, true) $$;

create function pg_temp.err(p_sql text) returns text
language plpgsql as $$
begin
  execute p_sql;
  return 'ok';
exception when others then
  return sqlerrm;
end $$;

do $$
declare
  u uuid := pg_temp.new_user();
  other uuid := pg_temp.new_user();
  r jsonb;
  r2 jsonb;
  v_appt text := 'appt-' || gen_random_uuid();
  v_msg uuid;
  v_consent uuid;
begin
  -- fixture: paciente, consentimento, consulta, mensagem agendada e conexão WhatsApp conectada
  insert into public.patients (id, fisioterapeuta_id, name, phone, phone_e164) values ('pat-gp', u, 'Fictícia', '+5562911110000', '+5562911110000');
  insert into public.patient_consents (fisioterapeuta_id, patient_id, channel, purpose, contact_value, source)
  values (u, 'pat-gp', 'whatsapp', 'appointment_reminder', '+5562911110000', 'teste') returning id into v_consent;
  insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status, patient_id)
  values (v_appt, u, current_date + 2, '10:00', 'x', 'scheduled', 'pat-gp');
  insert into public.whatsapp_messages (fisioterapeuta_id, patient_id, appointment_id, reminder_type,
    schedule_revision, scheduled_for, destination_phone_e164, consent_id)
  values (u, 'pat-gp', v_appt, 'appointment_12h', 0, now() + interval '1 day', '+5562911110000', v_consent)
  returning id into v_msg;
  insert into public.whatsapp_connections (fisioterapeuta_id, waba_id, phone_number_id, status, connected_at)
  values (u, 'waba-gp', 'pn-gp', 'connected', now());

  -- sem confirmação não pede
  perform pg_temp.act_as(u);
  perform pg_temp.check(pg_temp.err($q$select public.request_account_data_deletion('sim')$q$) = 'confirmation_required', 'sem a confirmação exata não pede exclusão');
  perform pg_temp.check(pg_temp.err($q$select public.request_account_data_deletion(null)$q$) = 'confirmation_required', 'confirmação nula recusada');
  perform pg_temp.check(not exists (select 1 from public.account_deletion_requests where user_id = u), 'nenhum pedido criado sem confirmação');

  -- sem sessão não pede
  perform pg_temp.act_as(null);
  perform set_config('request.jwt.claim.sub', '', true);
  perform pg_temp.check(pg_temp.err($q$select public.request_account_data_deletion('EXCLUIR_TODOS_OS_DADOS')$q$) = 'not authenticated', 'sem sessão não pede');

  -- pedido
  perform pg_temp.act_as(u);
  r := public.request_account_data_deletion('EXCLUIR_TODOS_OS_DADOS');
  perform pg_temp.check((r ->> 'purge_after')::timestamptz between now() + interval '29 days 23 hours' and now() + interval '30 days 1 hour', 'prazo é de 30 dias');
  perform pg_temp.check((select status from public.whatsapp_messages where id = v_msg) = 'cancelled', 'lembrete agendado foi cancelado');
  perform pg_temp.check((select status from public.whatsapp_connections where fisioterapeuta_id = u) = 'disconnected', 'envio de WhatsApp pausado (conexão desconectada)');
  perform pg_temp.check(not exists (select 1 from public.claim_whatsapp_messages_for_dispatch(100, 300, array['appointment_12h'])), 'nada desta conta é despachado');
  perform pg_temp.check(exists (select 1 from public.patients where id = 'pat-gp'), 'dados continuam intactos durante o prazo');
  perform pg_temp.check(public.get_account_deletion_status() is not null, 'status informa o pedido');

  -- idempotente: repetir não renova o prazo
  r2 := public.request_account_data_deletion('EXCLUIR_TODOS_OS_DADOS');
  perform pg_temp.check(r2 = r, 'repetir o pedido devolve o mesmo prazo');
  perform pg_temp.check((select count(*) from public.account_deletion_requests where user_id = u) = 1, 'um único pedido por conta');

  -- exclusão imediata continua bloqueada, mesmo com pedido
  perform pg_temp.check(pg_temp.err($q$select public.delete_own_account()$q$) = 'account_has_data', 'delete_own_account continua bloqueado para conta com dados');

  -- outra conta não enxerga nem cancela o pedido
  perform pg_temp.act_as(other);
  perform pg_temp.check(public.get_account_deletion_status() is null, 'outra conta não vê o pedido');
  perform public.cancel_account_data_deletion();
  perform pg_temp.check(exists (select 1 from public.account_deletion_requests where user_id = u), 'outra conta não cancela o pedido alheio');
  perform pg_temp.check(not exists (select 1 from public.account_deletion_requests where user_id = other), 'outra conta continua sem pedido');

  -- app não chama as funções de serviço
  perform pg_temp.check(not has_function_privilege('authenticated', 'public.finalize_account_deletion(uuid)', 'execute'), 'authenticated não finaliza exclusão');
  perform pg_temp.check(not has_function_privilege('authenticated', 'public.list_due_account_deletions(integer)', 'execute'), 'authenticated não lista pedidos vencidos');
  perform pg_temp.check(not has_function_privilege('anon', 'public.request_account_data_deletion(text)', 'execute'), 'anon não pede exclusão');
  perform pg_temp.check(has_function_privilege('service_role', 'public.finalize_account_deletion(uuid)', 'execute'), 'service_role finaliza exclusão');
  perform pg_temp.check(not has_table_privilege('authenticated', 'public.account_deletion_requests', 'select'), 'authenticated não lê a tabela de pedidos');

  -- cancelar dentro do prazo restaura a conexão e apaga o pedido; mensagens canceladas não voltam
  perform pg_temp.act_as(u);
  perform public.cancel_account_data_deletion();
  perform pg_temp.check(not exists (select 1 from public.account_deletion_requests where user_id = u), 'cancelamento remove o pedido');
  perform pg_temp.check((select status from public.whatsapp_connections where fisioterapeuta_id = u) = 'connected', 'cancelamento restaura a conexão WhatsApp');
  perform pg_temp.check((select status from public.whatsapp_messages where id = v_msg) = 'cancelled', 'mensagens canceladas não são recriadas pelo cancelamento');
  perform public.cancel_account_data_deletion();
  perform pg_temp.check(true, 'cancelar de novo é idempotente');
end $$;

-- Purga: não finaliza antes do prazo, nem sem arquivos removidos; finaliza e registra depois.
do $$
declare
  u uuid := pg_temp.new_user();
  r text;
begin
  insert into public.patients (id, fisioterapeuta_id, name) values ('pat-purge', u, 'Fictícia');
  insert into storage.objects (bucket_id, name) values ('patient-attachments', u || '/pat-purge/a_doc.pdf');
  insert into storage.objects (bucket_id, name) values ('avatars', u || '/foto.jpg');
  perform pg_temp.act_as(u);
  perform public.request_account_data_deletion('EXCLUIR_TODOS_OS_DADOS');

  r := pg_temp.err(format('select public.finalize_account_deletion(%L)', u));
  perform pg_temp.check(r = 'grace_period_not_over', 'não finaliza antes do prazo (' || r || ')');
  perform pg_temp.check(not exists (select 1 from public.list_due_account_deletions(10) where user_id = u), 'pedido no prazo não aparece como vencido');

  update public.account_deletion_requests set requested_at = now() - interval '31 days', purge_after = now() - interval '1 day' where user_id = u;
  perform pg_temp.check(exists (select 1 from public.list_due_account_deletions(10) where user_id = u), 'pedido vencido aparece na lista');

  perform pg_temp.check(pg_temp.err('select public.cancel_account_data_deletion()') = 'deletion_deadline_passed', 'depois do prazo não dá mais para cancelar');

  r := pg_temp.err(format('select public.finalize_account_deletion(%L)', u));
  perform pg_temp.check(r = 'storage_not_empty', 'não finaliza com arquivo ainda no Storage (' || r || ')');
  perform pg_temp.check(exists (select 1 from auth.users where id = u) and exists (select 1 from public.patients where id = 'pat-purge'), 'recusa não apagou nada');

  delete from storage.objects where name like u || '/%'; -- o que a Edge Function faz pela API
  perform public.finalize_account_deletion(u);
  perform pg_temp.check(not exists (select 1 from auth.users where id = u), 'finaliza depois de o Storage esvaziar');
  perform pg_temp.check(not exists (select 1 from public.patients where id = 'pat-purge'), 'dados removidos na finalização');
  perform pg_temp.check(exists (select 1 from public.account_deletion_log
    where user_hash = encode(sha256(convert_to(u::text, 'utf8')), 'hex')
      and counts ->> 'via' = 'grace_period' and (counts ->> 'patients')::int = 1), 'log registra a exclusão com contagens, sem id em claro');
  perform public.finalize_account_deletion(u);
  perform pg_temp.check(true, 'finalizar de novo é idempotente');
  perform pg_temp.check(pg_temp.err(format('select public.finalize_account_deletion(%L)', gen_random_uuid())) = 'ok', 'usuário inexistente não falha');
end $$;

-- Sem pedido, finalize recusa.
do $$
declare u uuid := pg_temp.new_user();
begin
  perform pg_temp.check(pg_temp.err(format('select public.finalize_account_deletion(%L)', u)) = 'no_deletion_request', 'finalize sem pedido é recusado');
  perform pg_temp.check(exists (select 1 from auth.users where id = u), 'usuário sem pedido preservado');
end $$;

rollback;
