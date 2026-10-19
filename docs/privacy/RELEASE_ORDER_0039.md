# Ordem de liberação: bloqueio de exclusão com dados (migrations 0039 e 0040)

Status: **PREPARADO, NADA APLICADO.** O PR #14 está em rascunho. Nada foi mergeado, publicado ou aplicado em produção. Cada passo marcado com **[AUTORIZAÇÃO]** só roda com o seu "pode".

## O que mudou no desenho
A "confirmação de custódia" por declaração foi **removida**. A regra agora é: **conta com qualquer dado vinculado não pode ser excluída pelo app** (bloqueio no servidor, que resiste a chamadas diretas das RPCs). Só conta realmente vazia exclui. Contas com dados passam por encerramento assistido (`ASSISTED_CLOSURE.md`). É proteção temporária, não política de retenção.

- **0039:** `check_account_deletion_allowed()`, `delete_own_account()` (trava a linha do usuário, revalida e só então apaga), `record_data_export()` (recibo), tabelas `account_deletion_log` e `data_export_receipts` (sem FK, só hash e contagens, sem dado de saúde). Não altera nenhuma tabela existente.
- **0040:** política restritiva em `storage.objects`: usuário autenticado não remove arquivo do bucket de anexos enquanto houver linha em `attachments` apontando para ele. Cria índice em `attachments(storage_path)`.

## Por que a ordem importa (versões do app)
| App | Exclusão de conta com dados | Exclusão de anexo isolado |
|---|---|---|
| **Antigo** (1.0.2) | Remove os arquivos do Storage **antes** de chamar `delete_own_account()`. Sem a 0040, a RPC recusa mas os arquivos já se foram: **perda de anexos com conta viva**. Com a 0040, a remoção dos arquivos referenciados é ignorada pelo Storage e a RPC recusa: nada se perde. | Remove o arquivo primeiro: com a 0040 o Storage ignora, a linha é apagada e o arquivo vira **órfão** (não se perde nada; fica até limpeza assistida; órfão bloqueia exclusão de conta). |
| **Novo** (este PR) | Nenhum anexo é removido pelo cliente; o servidor decide antes. | Linha primeiro, depois o arquivo. |

Por isso: **0039 e 0040 são aplicadas juntas, nunca só a 0039.** O app novo não depende da migration para ser seguro (ele não apaga anexos), e funciona antes dela: a pré-checagem `check_account_deletion_allowed` ainda não existe e retornaria erro genérico de servidor até a migration; por isso o app novo deve estar publicado antes, mas a exclusão só funcionará (mesmo para contas vazias) depois da migration.

## Passos
**0. Revisão e merge do PR #14** **[AUTORIZAÇÃO]**
- Conferir o diff, o CI (Flutter, Edge Functions, testes SQL) e que `AUTO_DEPLOY` não está definido (Settings > Variables do GitHub). O merge não deve fazer deploy.

**1. Pré-flight (somente leitura)** **[AUTORIZAÇÃO para acessar produção]**
```
npx.cmd supabase db query -f supabase/rollout-0039/01_preflight_readonly.sql --linked --project-ref lchaboncmgcimafpupad
```
Esperado: PASS; as linhas INFO mostram órfãos no Storage e anexos sem arquivo (anotar: viram trabalho de limpeza assistida).

**2. App mobile novo** **[AUTORIZAÇÃO]** — versão em `pubspec.yaml` (hoje `1.0.2+5`; sugestão `1.0.3+6`); AAB Android e build iOS (`scripts/build_ios.sh`); esperar aprovação e adoção. Não há atualização forçada: **o app antigo continua em campo**; com 0040 aplicada ele só perde a capacidade de apagar arquivos referenciados. Avaliar tela de versão mínima antes de depender da adoção.

**3. Web nova** **[AUTORIZAÇÃO]** — `gh workflow run deploy.yml --ref main`. Atualiza para todos.

**4. Go/no-go** — app novo aprovado nas lojas e Web publicada; decisão do dono sobre quem ainda usa o app antigo; exportação testada em dispositivo real com conta de teste; aprovação do dono.

**5. Dry-run em produção (transação revertida)** **[AUTORIZAÇÃO]**
```
npx.cmd supabase db query -f supabase/rollout-0039/02_dry_run_in_rollback.sql --linked --project-ref lchaboncmgcimafpupad
```
Tem `lock_timeout` de 3 s e roda em horário calmo: `CREATE INDEX` em `attachments` bloqueia escritas nessa tabela até o ROLLBACK. Depois, reexecutar o pré-flight para confirmar que nada persistiu.

**6. Aplicar** **[AUTORIZAÇÃO]** — `0039` e depois `0040`, em sequência:
```
npx.cmd supabase db query -f supabase/migrations/0039_account_deletion_custody_guard.sql --linked --project-ref lchaboncmgcimafpupad
npx.cmd supabase db query -f supabase/migrations/0040_protect_referenced_attachment_files.sql --linked --project-ref lchaboncmgcimafpupad
```
Ambas aditivas e idempotentes; nenhum dado é alterado.

**7. Pós-check (somente leitura)** — `supabase/rollout-0039/04_postcheck_readonly.sql`; esperado PASS.

**8. Teste ponta a ponta com conta descartável** **[AUTORIZAÇÃO]** — dados inteiramente fictícios, nunca prontuário real: (a) conta vazia exclui; (b) conta com paciente e anexo: app novo mostra o bloqueio e nada some; (c) app antigo: exclusão falha e os anexos continuam abrindo; (d) exportar e conferir o ZIP contra o manifesto.

## Rollback e contingência (nenhum restaura o cascade)
| Situação | Script | Efeito |
|---|---|---|
| A trava bloqueia algo legítimo ou tem defeito | `03_rollback_0039_disable_deletion.sql` (**padrão**) | Desliga a exclusão de conta para todos. Perda de dado impossível. Recuperação: reaplicar a 0039 corrigida. |
| A política de Storage bloqueia algo legítimo | `03a_rollback_0040_storage_policy.sql` | Remove só a política. **Reabre o risco do app antigo apagar arquivos antes da recusa.** |
| Voltar ao cascade sem trava | `03b_rollback_UNGUARDED_DANGEROUS.sql` | **Só com decisão expressa do dono.** Restaura o apagamento em cascata desprotegido. |
O rollback do front é o workflow `rollback-web.yml`.

## Ainda pendente (não faz parte desta liberação)
Transferência de custódia com verificação independente, fluxo "encerrar acesso" separado de "eliminar dados", prazos de retenção (decisão jurídica), CSP bloqueante, limpeza assistida de órfãos. Ver `LEGAL_DECISIONS.md`, `ASSISTED_CLOSURE.md`, `DATA_EXPORT.md`.
