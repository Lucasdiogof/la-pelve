-- Protege no SERVIDOR os arquivos clínicos referenciados por uma linha em public.attachments.
--
-- Risco: o app antigo removia TODOS os arquivos do bucket 'patient-attachments' antes de chamar delete_own_account().
-- Com a trava da 0039, o RPC recusa a exclusão, mas os arquivos já teriam sido apagados: conta viva, anexos perdidos.
-- O servidor não controla a ordem das chamadas do cliente, então a regra precisa estar no Storage.
--
-- Regra: um objeto do bucket só pode ser removido por um usuário autenticado se NÃO houver mais linha em
-- attachments apontando para ele. O fluxo legítimo de excluir um anexo passa a ser "linha primeiro, arquivo depois"
-- (o app novo faz assim). Num app antigo (arquivo primeiro), a remoção do arquivo é silenciosamente ignorada pelo
-- Storage, a linha é apagada e o arquivo vira órfão: não há perda de dado, mas o arquivo permanece até a limpeza
-- assistida; órfãos também bloqueiam a exclusão da conta (0039). service_role não é afetado (bypass de RLS).
-- Aditiva e idempotente.

create index if not exists attachments_storage_path_idx on public.attachments (storage_path);

drop policy if exists "Keep referenced attachment files" on storage.objects;
create policy "Keep referenced attachment files"
on storage.objects
as restrictive
for delete
to authenticated
using (
  bucket_id <> 'patient-attachments'
  or not exists (
    select 1 from public.attachments a
    where a.storage_path = storage.objects.name
  )
);
