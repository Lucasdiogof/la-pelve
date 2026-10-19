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

## O que foi implementado (branch `security/lgpd-web-hardening`, PR #14 em rascunho; nada em produção)
- **Exclusão só de conta vazia**, decidida no servidor (migration 0039): bloqueia se houver paciente (inclusive soft-deleted), evolução, agenda, financeiro, anexo, consentimento, mensagem WhatsApp ou **qualquer objeto** do bucket de anexos. Trava a linha do usuário antes de revalidar, para que dado criado durante a exclusão não seja levado pelo cascade.
- **Sequência segura no app:** pré-checagem no servidor -> só o avatar é removido pelo cliente -> RPC. Anexos clínicos nunca são removidos pelo cliente (o risco 3 acima deixa de existir).
- **0040:** o Storage recusa remover arquivo referenciado por anexo (protege contra o app antigo).
- **Exportação ZIP verificada** (`DATA_EXPORT.md`), com recibo conferido pelo servidor.
- **Log mínimo** sem FK (`account_deletion_log`), sobrevive ao cascade.
- Texto do app em pt/en/es; a declaração de responsabilidade foi removida.

## O que falta
Transferência de custódia, encerramento assistido e eliminação por estados (`ASSISTED_CLOSURE.md`), decisões jurídicas, política de backup do Supabase, limpeza de órfãos, tela de versão mínima.
