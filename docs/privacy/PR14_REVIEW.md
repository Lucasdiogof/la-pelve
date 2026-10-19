# Revisão técnica do PR #14 (atualizada em 2026-10-19, 2ª rodada)

> Parecer de engenharia, não jurídico. Nada foi aplicado em produção.

## Diagnóstico da 1ª rodada (mantido)
A "custódia por declaração" não protegia prontuário: o app a confirmava sozinho e qualquer cliente podia chamar as duas RPCs em sequência; `export_downloaded` não era comprovável; a evidência sumia no cascade; o rollback antigo reabria o cascade.

## Decisão do dono e o que foi feito
Bloquear a exclusão de conta com dados até existir exportação e transferência de custódia confiáveis. Ver `RELEASE_ORDER_0039.md`, `DATA_EXPORT.md`, `ASSISTED_CLOSURE.md`.

| Risco | Antes | Agora |
|---|---|---|
| Perda de anexos | Cliente apagava o Storage antes de a conta ser excluída e ignorava falhas | Cliente nunca remove anexo clínico; servidor decide antes; 0040 faz o Storage recusar a remoção de arquivo referenciado (cobre app antigo) |
| Exclusão com dados | Liberada por declaração | Recusada no servidor para qualquer categoria, inclusive órfãos no Storage |
| Concorrência | Sem tratamento | Trava da linha do usuário antes de revalidar |
| Evidência | Colunas em `profiles` (sumiam) | Log sem FK, hash e contagens |
| Exportação | Inexistente | ZIP verificado, recibo conferido no servidor |
| Rollback | Restaurava o cascade | Padrão desliga a exclusão; cascade só pelo script marcado DANGEROUS |

## Não resolvido
- Custódia legal: exportar não é transferir custódia. Sem fluxo de encerramento, contas com dados ficam sem caminho de saída além do assistido manual.
- App antigo em campo: perde só a capacidade de apagar anexos referenciados; apagar um anexo isolado nele deixa arquivo órfão.
- Concorrência: o teste SQL do CI é de sessão única. Foi verificada à mão, com duas conexões reais em Postgres 16.9 local (fora do CI): inserção concorrente durante a exclusão falha por FK sem criar paciente; exclusão concorrente com inserção pendente é recusada (`account_has_data`) e preserva usuário e paciente. Migrations 0039/0040 reaplicadas duas vezes sem erro; pré-flight, dry-run (nada persiste), pós-check e rollbacks 03/03a executados num banco descartável. Esse banco local não tinha Vault, então as migrations 0026+ foram puladas ali; o CI roda a cadeia completa.
- Exportação em memória; sem assinatura; entrega ao sistema de arquivos não é verificável; não testada em dispositivo real nesta rodada.
- `whatsapp_connections` e credenciais são removidas com a conta (configuração, sem dado de paciente); revogação do token na Meta não é feita pela exclusão.
- Backups do Supabase e prazos jurídicos: pendentes.
