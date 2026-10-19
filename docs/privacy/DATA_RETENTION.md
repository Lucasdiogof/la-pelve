# Retenção de dados (RASCUNHO para revisão jurídica)

Nada aqui é parecer jurídico nem prazo definitivo do produto. Prazos marcados como "decisão" dependem da controladora e de advogado.

## Fontes verificadas
- **Resolução COFFITO nº 414/2012, art. 6º:** a guarda do prontuário é responsabilidade do fisioterapeuta (e da instituição); prazo de guarda de **no mínimo 5 anos a contar do último registro**, ampliável por lei, ordem judicial ou necessidade específica; após o prazo, a destruição deve garantir o sigilo. Fonte consultada: https://www.normasbrasil.com.br/norma/resolucao-414-2012_240928.html (conferir no texto oficial do COFFITO).
- **Lei nº 13.787/2018, art. 6º:** prazo **mínimo de 20 anos a partir do último registro** para prontuários em papel e digitalizados antes da eliminação (a lei trata de digitalização e sistemas informatizados de prontuário). Fonte consultada: https://www2.camara.leg.br/legin/fed/lei/2018/lei-13787-27-dezembro-2018-787543-publicacaooriginal-157119-pl.html
- Como o prazo da lei é "mínimo" e maior que o do conselho, **não se deve presumir que 5 anos basta** para prontuários eletrônicos. Cabe ao advogado confirmar qual prazo vale para cada tipo de registro e de profissional. Esta pesquisa não encontrou posição oficial consolidada sobre a relação entre as duas normas.

## Modelo por categoria
| Categoria | Prazo candidato | Base de retenção candidata | Descarte | Status |
|---|---|---|---|---|
| Prontuário (anamnese, evoluções, plano de tratamento) | A DEFINIR com advogado (mínimos citados: 5 e 20 anos) | Obrigação legal/regulatória | Eliminação segura documentada, só após o prazo e sem impedimento | DECISÃO PENDENTE |
| Anexos clínicos (fotos, exames) vinculados ao prontuário | Mesmo do prontuário | Obrigação legal/regulatória | Idem | DECISÃO PENDENTE |
| Consentimentos (incl. WhatsApp) | Enquanto durar o tratamento + prazo para defesa de direitos (A DEFINIR) | Exercício regular de direitos | Idem | DECISÃO PENDENTE |
| Agenda e mensagens WhatsApp (log de status) | A DEFINIR | Execução do serviço/legítimo interesse (a avaliar) | Eliminação automática (não implementada) | NÃO IMPLEMENTADO |
| Financeiro | A DEFINIR (obrigações fiscais/contábeis da profissional) | Obrigação legal | Idem | DECISÃO PENDENTE |
| Conta e perfil da profissional | Enquanto a conta existir | Execução de contrato | Exclusão só de conta vazia; com dados, bloqueada no servidor (0039) | PARCIAL |
| Logs técnicos (Cloudflare, Supabase, Edge Functions) | NÃO VERIFICADO (depende do plano) | Segurança | Retenção do fornecedor | NÃO VERIFICADO |
| Backups do Supabase | NÃO VERIFICADO | Continuidade | Retenção do fornecedor | NÃO VERIFICADO |

## Regras técnicas propostas
- Exclusão de paciente no app continua sendo **soft delete** (`deleted_at`); não é eliminação.
- Exclusão de conta com qualquer dado é bloqueada no servidor (0039) até existir transferência de custódia; declaração não libera. Não implementar retenção indefinida automática: o prazo e o responsável pela guarda após o encerramento (profissional, clínica ou fornecedor sob contrato) são decisões pendentes.
- Eliminação após o prazo: procedimento manual documentado, com registro (quem, quando, o quê) e sem conteúdo clínico no registro.

- Registro de auditoria (`account_deletion_log`, `data_export_receipts`): proposta de prazo em `ASSISTED_CLOSURE.md`, decisão pendente.
