-- ⚠️ DESTRUTIVO E IRREVERSÍVEL. Apaga TODAS as contas e TODOS os dados
-- de TODOS os usuários do projeto Supabase (produção). Não tem como desfazer.
--
-- Rode no Supabase Dashboard: SQL Editor > New query, logado como
-- owner do projeto (precisa de privilégio de superuser/postgres, não
-- funciona com a publishable/anon key do app).
--
-- Como toda tabela (profiles, patients, evolution_entries,
-- financial_entries, appointments, attachments) tem
-- "references auth.users(id) on delete cascade", apagar as linhas de
-- auth.users já apaga tudo em cascata nas tabelas públicas.
-- Arquivos no Storage (avatars, patient-attachments) NÃO são cobertos
-- pela cascata — são removidos à parte, abaixo.

-- 1) Apaga todos os arquivos dos buckets de Storage.
delete from storage.objects
where bucket_id in ('avatars', 'patient-attachments');

-- 2) Apaga todas as contas de autenticação — isso cascade-deleta
--    profiles, patients, evolution_entries, financial_entries,
--    appointments e attachments automaticamente.
delete from auth.users;
