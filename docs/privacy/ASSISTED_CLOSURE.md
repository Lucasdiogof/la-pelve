# Encerramento assistido e separação acesso x dados (desenho; não implementado)

Rascunho técnico. Decisões de prazo e de quem guarda são jurídicas (`LEGAL_DECISIONS.md`).

## Dois atos diferentes
1. **Encerrar acesso à plataforma:** a profissional deixa de usar o La Pelve (fim de contrato). Não apaga nada. Futuro: desativar login e envio de WhatsApp, manter os dados isolados.
2. **Eliminar definitivamente os dados:** só depois de exportação conferida, transferência de custódia (ou decisão documentada) e atendimento do prazo aplicável. Registro mínimo em `account_deletion_log` (sem conteúdo clínico).
Hoje o app faz o ato 2 assim: conta **vazia** exclui na hora; conta **com dados** pede a exclusão de tudo e tem **30 dias para desistir** (0041), depois a rotina `account-purge` apaga. Falta o ato 1 (encerrar sem apagar), a transferência de custódia e o aviso por e-mail perto do fim do prazo. Não existe retenção automática: nada é guardado "por padrão" por 5 ou 20 anos sem decisão jurídica e contratual.

## Situações que exigem tratamento assistido (manual, pelo dono)
| Situação | Tratamento |
|---|---|
| Profissional com pacientes quer sair | Exportar no app; dono confere o recibo e a contagem; decisão sobre custódia (profissional guarda por conta própria, clínica ou fornecedor sob contrato); só então eliminação manual |
| Pedido de exclusão de dado de paciente (art. 18) | Avaliar com a controladora (profissional) se há dever de guarda; app mantém soft delete |
| Conta com arquivos órfãos | Limpeza assistida depois de conferir o conteúdo com a profissional |
| Anexo com linha mas sem arquivo | A exportação falha (o download não existe): resolver antes, com a profissional |
| Profissional falecida/incapaz | Caso jurídico; não executar eliminação sem orientação |
| Ordem judicial / incidente | Congelar eliminação; seguir plano de incidente |

## Proposta de desenho futuro
Estados `active -> access_closed -> custody_transferred -> eligible_for_erasure -> erased`, com data de cada transição em tabela sem dado clínico, eliminação por função de serviço (não pelo cliente) apenas em `eligible_for_erasure`, e Storage removido **depois** da confirmação no banco, com reconciliação periódica para órfãos.

## Retenção do registro de auditoria (PROPOSTA, decisão pendente de revisão jurídica)
`account_deletion_log` e `data_export_receipts` guardam hash do id (pseudonimização, ainda dado pessoal), horário e contagens; nenhum dado de saúde.
- **Necessidade:** demonstrar que a exportação/eliminação ocorreu (prestação de contas e defesa de direitos).
- **Minimização:** sem nomes, sem conteúdo, sem anexos.
- **Proposta:** guardar enquanto puder haver reclamação sobre o ato, hoje estimado em torno do prazo prescricional civil de 5 anos a contar do evento, depois eliminar. Número a ser confirmado ou trocado pelo advogado; não implementado (sem rotina de expurgo).
