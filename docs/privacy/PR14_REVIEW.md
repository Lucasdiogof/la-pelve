# Revisão técnica do PR #14 (2026-10-19)

> Parecer de engenharia, não jurídico. Nada foi aplicado em produção.

## Respostas diretas
1. **A custódia protege os prontuários?** Não. Registra uma declaração. O app novo chama `confirm_clinical_data_custody('declared_responsibility')` automaticamente ao confirmar na tela; qualquer cliente autenticado pode chamar as duas RPCs em sequência. É um freio contra exclusão acidental, não controle de acesso.
2. **A profissional obtém os dados antes?** Não há exportação no app (pacientes, anamnese, evoluções, agenda, financeiro, anexos). Sem cópia possível, a "custódia" depende de ela guardar os dados por fora.
3. **`export_downloaded`** não era comprovável (o servidor não sabe se houve download). Passou a ser **recusado** (`export_not_available`) até existir exportação verificável.
4. **Exclusão por outros caminhos?** `delete_own_account()` é o único caminho do app. Restam: painel/service role do Supabase e o cascade ao apagar `auth.users` manualmente (acesso administrativo, fora da trava).
5. **Evidência após exclusão:** antes, as colunas ficavam em `profiles` e sumiam no cascade. Agora `account_deletion_log` (sem FK, só hash do id, método, horário e contagens, sem dado de saúde) sobrevive. Prazo de guarda do log: decisão pendente (`DATA_RETENTION.md`).
6. **Backups do Supabase:** não verificado.
7. **Anexos no Storage:** o app apaga arquivos "best effort" e engole falhas (`_deleteAllUserFiles`). Falha parcial deixa arquivos órfãos; e como os arquivos saem antes do RPC, falha do RPC deixa a conta viva sem anexos. Não corrigido neste PR (sem Flutter local para validar); recomendado como follow-up.
8. **Versões antigas:** falham com `custody_not_confirmed` e mensagem genérica; nada é apagado. Não há atualização forçada.
9. **Tabelas cobertas pela trava:** passou a incluir agenda e financeiro, além de pacientes, evoluções e anexos. `patient_consents` e tabelas WhatsApp não contam como "registro clínico" e seguem sem trava.
10. **Dry-run:** `ALTER TABLE profiles` pede lock exclusivo até o ROLLBACK; adicionado `lock_timeout 3s`. Rodar em horário calmo.
11. **Rollback antigo reabria o cascade sem trava.** Padrão agora é `03_rollback_keep_block.sql` (bloqueia exclusão com dados).

## Mudanças feitas nesta revisão
Migration 0039 (log append-only, método único aceito, cobertura ampliada), testes SQL, scripts de pré-flight/dry-run/pós-check, rollback seguro, ordem de liberação.

## Não validado
Testes SQL e Flutter não rodaram localmente (sem Postgres/Flutter na máquina); dependem do CI do PR. Teste de exclusão com tabela financeira/agenda não foi escrito.

## Decisões que não são de engenharia
Aceitar "declaração" como suficiente até a exportação existir; prazo de retenção do log; fluxo de encerramento com retenção (COFFITO 414/2012, Lei 13.787/2018).
