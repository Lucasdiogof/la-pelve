# Minuta de Contrato de Tratamento de Dados (controlador–operador) — RASCUNHO

> **RASCUNHO PARA REVISÃO JURÍDICA. Não é texto legal definitivo do produto e não deve ser publicado nem assinado sem advogado.** Campos `[A PREENCHER]` dependem das partes.

**Partes.** Controladora: `[NOME/CPF-CNPJ da fisioterapeuta ou clínica]`. Operador: `[NOME/CPF-CNPJ do fornecedor do La Pelve]`.

1. **Objeto.** O Operador fornece o aplicativo La Pelve e trata dados pessoais por conta da Controladora para gestão clínica de saúde pélvica.
2. **Finalidades e instruções.** Prontuário, agenda, financeiro, anexos, consentimentos e lembretes por WhatsApp, apenas conforme instruções documentadas da Controladora. O Operador não usa os dados para finalidade própria. `[A PREENCHER: instruções adicionais]`
3. **Dados e titulares.** Pacientes da Controladora (dados comuns e de saúde, sensíveis) e a própria profissional.
4. **Confidencialidade.** Pessoas autorizadas do Operador ficam sujeitas a sigilo. O Operador não acessa prontuários, salvo suporte solicitado ou obrigação legal, com registro. `[A PREENCHER: política de suporte]`
5. **Segurança.** RLS por profissional, buckets privados, HTTPS, segredos fora do app, controles descritos em `docs/WEB_PRIVACY.md` e `docs/security/`.
6. **Suboperadores.** Supabase, Cloudflare, Meta (WhatsApp) e Resend, conforme `SUBPROCESSORS.md`. O Operador informa mudanças e a Controladora pode se opor. `[A PREENCHER: prazo de aviso]`
7. **Transferência internacional.** Conforme `INTERNATIONAL_TRANSFERS.md`; mecanismo `[A DEFINIR com advogado]`.
8. **Direitos dos titulares.** O Operador auxilia a Controladora a atender pedidos em `[A PREENCHER: prazo]`; pedidos recebidos diretamente são encaminhados à Controladora.
9. **Incidentes.** O Operador avisa a Controladora sem demora injustificada e em até `[SUGESTÃO INTERNA: 24 a 48 horas do conhecimento]`, com os fatos disponíveis. Esse prazo contratual é distinto do prazo regulatório da Controladora perante a ANPD (ver `docs/security/INCIDENT_RESPONSE_PLAN.md`).
10. **Retenção e devolução.** Os prontuários podem ter prazo legal de guarda (ver `DATA_RETENTION.md`). Ao encerrar, o Operador disponibiliza exportação à Controladora antes de qualquer eliminação, e só elimina após confirmação da Controladora ou fim do prazo `[A DEFINIR]`.
11. **Exportação.** Formato e prazo `[A PREENCHER]` (funcionalidade ainda não implementada).
12. **Encerramento.** Por qualquer parte, com aviso de `[A PREENCHER]` dias; cumpre o item 10.
13. **Responsabilidades.** `[A PREENCHER com advogado]` (arts. 42 a 45 da LGPD).
14. **Foro e lei aplicável.** Lei brasileira; foro `[A PREENCHER]`.
