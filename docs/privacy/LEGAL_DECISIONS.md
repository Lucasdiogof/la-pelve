# Decisões jurídicas pendentes (para advogado e controladora)

Rascunho técnico, não parecer. Cada item diz o que é **exigência legal efetiva**, **boa prática** ou **decisão do dono**, e o que já foi verificado.

| # | Decisão | Tipo | O que se sabe | Quem decide |
|---|---|---|---|---|
| 1 | Prazo de guarda de prontuário (5 anos COFFITO 414/2012, art. 6º; 20 anos Lei 13.787/2018, art. 6º) | Exigência legal (prazo exato a confirmar) | Ambos são prazos **mínimos** contados do último registro; a guarda é responsabilidade do fisioterapeuta. Relação entre as normas não confirmada. | Advogado + profissional |
| 2 | Quem guarda os prontuários depois que a profissional encerra a conta | Decisão do dono/contrato | Hoje (código do PR #14, não aplicado) a conta com dados não pode ser excluída pelo app; até lá a exclusão em produção ainda apaga em cascata | Dono + advogado |
| 3 | Encarregado (DPO) | Exigência legal ou dispensa | Res. CD/ANPD 18/2024: quem é dispensado de indicar encarregado (agente de pequeno porte, Res. 2/2022) ainda deve oferecer canal de comunicação com o titular. Fontes secundárias indicam que a dispensa **não** vale em tratamento de alto risco (dados sensíveis em larga escala etc.); conferir o texto da Res. 2/2022. Não nomear o desenvolvedor automaticamente. | Dono + advogado |
| 4 | Enquadramento controlador/operador e contrato (DPA) | Exigência legal (art. 39) | `privacy.html` já diz profissional = controladora, La Pelve = operador | Advogado |
| 5 | Base legal por operação | Exigência legal | Ver `ROPA.md`; evitar consentimento genérico | Advogado |
| 6 | Consentimento WhatsApp: guardar a **versão do texto** aceito e a evidência | Boa prática forte | `patient_consents` guarda canal, finalidade, telefone, data e `source`; **não guarda versão do texto**. Revogação existe; opt-out por resposta do paciente não verificado | Dev + advogado |
| 6b | Texto do template de lembrete: o que pode aparecer | Boa prática | Template `appointment_12h` com 3 variáveis; conteúdo exato não conferido na Meta | Dono |
| 7 | Transferência internacional | Exigência legal (arts. 33 e ss.; Res. 19/2024) | Regiões e DPAs não verificados | Dono + advogado |
| 8 | Comunicação de incidente | Exigência legal | Res. CD/ANPD 15/2024: 3 dias úteis a partir do conhecimento, em dobro para pequeno porte (Res. 2/2022); confirmar texto oficial | Controladora |
| 9 | Registro das operações (art. 37) | Exigência legal (simplificável para pequeno porte) | Modelo em `ROPA.md` | Controladora |
| 10 | Política de privacidade: ajustes | Exigência legal | Ver `PRIVACY_POLICY_REVIEW.md` | Advogado |
| 12 | Prazo de guarda do registro de auditoria da exclusão/exportação | Decisão do dono + advogado | Proposta em `ASSISTED_CLOSURE.md` | Advogado |
| 13 | Canal de suporte para encerramento assistido | Decisão do dono | **Definido: marketing@lucksrei.com** (canal único de suporte da marca); já citado nas mensagens do app | Dono |
| 14 | Reter dados de pacientes DEPOIS do pedido de exclusão, para consulta da empresa | **Decisão jurídica; não implementado** | Como operador, usar dado de saúde para finalidade própria exige base legal; os 30 dias existem só para a profissional desistir. Qualquer retenção adicional (defesa de direitos etc.) precisa de prazo, finalidade e acesso restrito definidos pelo advogado | Advogado + dono |
| 11 | Liberação para uso clínico real da versão Web | Decisão do dono | A web está publicada em `lapelve.lucksrei.com` desde 19/10/2026 por autorização do dono; **uso clínico real segue dependendo dos itens acima** | Dono |

Fontes consultadas em 19/10/2026 (conferir no texto oficial): Res. COFFITO 414/2012 (normasbrasil.com.br), Lei 13.787/2018 (camara.leg.br), Res. CD/ANPD 15/2024 e 18/2024 (resumos secundários e DOU).
