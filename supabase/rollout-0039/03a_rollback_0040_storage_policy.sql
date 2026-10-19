-- REVERTE so a 0040 (protecao dos arquivos de anexos no Storage). ATENCAO: reabre o risco de um app antigo apagar
-- arquivos do bucket antes de a exclusao de conta ser recusada. Use so se a politica bloquear algo legitimo e
-- depois de confirmar que ninguem com dados vai usar o app antigo para excluir conta. O indice e mantido.
begin;
set local lock_timeout = '3s';
drop policy if exists "Keep referenced attachment files" on storage.objects;
commit;
select count(*) = 0 as politica_removida from pg_policies
 where schemaname = 'storage' and tablename = 'objects' and policyname = 'Keep referenced attachment files';
