# Auditoria: exclusão de conta e dados clínicos (2026-10-19)

> Rascunho técnico. A interpretação jurídica (prazos, papéis) precisa de revisão de advogado especializado em LGPD.

## Diagnóstico (verificado no código)
`Perfil > Excluir minha conta` chama `AuthRepositoryImpl.deleteAccount()` (`lib/features/auth/data/auth_repository_impl.dart`):

1. Apaga os arquivos do Storage (`avatars` e `patient-attachments`, pasta `{uid}/`), "best effort".
2. Chama o RPC `delete_own_account()` (`security definer`, migration `0009`), que faz `delete from auth.users where id = auth.uid()`.
3. Faz `signOut` e limpa o armazenamento offline local do usuário (`offline.wipeUser`).

Todas as tabelas clínicas referenciam `auth.users(id)` com `ON DELETE CASCADE`, então o passo 2 apaga de forma **irreversível e imediata**:

| Dado | Mecanismo | Sobrevive? |
|---|---|---|
| `profiles` | FK `auth.users` cascade | Não |
| `patients` (inclusive os com `deleted_at`, ou seja, "excluídos" por soft delete) | FK cascade | Não |
| `evolution_entries`, `appointments`, `financial_entries`, `attachments` | FK cascade (direto e via `patients`) | Não |
| `patient_consents`, `whatsapp_connections`, `whatsapp_messages`, `whatsapp_inbound_messages`, `whatsapp_connect_attempts` | FK cascade | Não |
| Arquivos no Storage | Apagados pelo cliente antes do RPC | Não |
| SQLite cifrado local (mobile) | `wipeUser` | Não |
| Backups do Supabase | Não verificável (plano e política não consultados) | NÃO VERIFICADO |

## Riscos encontrados
1. **Perda de prontuário sujeita a guarda.** Pacientes removidos pelo app usam soft delete exatamente porque "prontuário não pode ser apagado" (comentário da migration `0008`), mas a exclusão de **conta** ignora essa regra e apaga tudo, inclusive os já removidos.
2. **Sem exportação:** não existe função de exportar dados no app. A profissional não tem como guardar uma cópia antes de excluir.
3. **Ordem insegura:** os arquivos eram apagados **antes** do RPC. Se o RPC falhasse, a conta continuava viva sem os anexos.
4. **Sem registro do ato:** nada registra que a profissional foi avisada nem que assumiu a guarda.
5. **Papel do fornecedor:** em regra a profissional é controladora dos dados dos pacientes; o fornecedor (operador) apagar tudo ao encerrar a conta sem etapa de custódia deixa a controladora sem os registros que ela mesma deve guardar.

## O que foi implementado (branch `security/lgpd-web-hardening`, PR em rascunho)
Status: **IMPLEMENTADO, PENDENTE DE VALIDAÇÃO** (testes SQL rodam no CI; migration NÃO aplicada em produção).

- Migration `0039_account_deletion_custody_guard.sql` (aditiva e idempotente): colunas `custody_confirmed_at/method` em `profiles`; RPC `confirm_clinical_data_custody(method)`; RPC `check_account_deletion_allowed()`; `delete_own_account()` passa a exigir custódia confirmada nas últimas 24 h quando há pacientes, evoluções ou anexos (erro `custody_not_confirmed`). Não altera nenhum dado existente.
- App: registra a custódia e valida no servidor **antes** de apagar arquivos; o texto de confirmação (pt/en/es) agora informa que prontuários podem ter prazo legal de guarda e que o ato é uma declaração de responsabilidade.
- Teste SQL `supabase/tests/0039_account_deletion_custody_guard.test.sql`.

**Ordem de aplicação:** publicar o app novo primeiro, depois aplicar a migration (apps antigos passam a falhar com segurança, sem apagar nada).

## O que falta (decisão e trabalho)
- **Exportação** (JSON/CSV/PDF com anexos) no app: BLOQUEADO por decisão de formato e por adicionar dependência de compartilhamento/salvamento de arquivo. Com ela, `export_downloaded` passa a ser o caminho principal e `declared_responsibility` o alternativo.
- Fluxo "encerrar conta" separado de "excluir dados": desativar acesso e reter por prazo, com eliminação posterior documentada. Depende de decisão jurídica (`LEGAL_DECISIONS.md`).
- Exclusão de dados de paciente a pedido do titular: é avaliada pela controladora (a profissional), respeitando a guarda. O app já usa soft delete.
- Eliminação definitiva do Storage de arquivos de pacientes com soft delete: não implementada.
- Conferir a política de backup do Supabase (não consultada).
