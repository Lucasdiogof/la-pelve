# Papéis de tratamento (RASCUNHO para revisão jurídica)

Enquadramento preliminar, a confirmar conforme as operações reais e o contrato entre as partes (LGPD, art. 5º, VI a VIII).

| Operação | Controlador (candidato) | Operador (candidato) | Observação |
|---|---|---|---|
| Dados clínicos e cadastrais dos pacientes (prontuário, agenda, financeiro, anexos) | A fisioterapeuta ou a clínica | O fornecedor do La Pelve | A profissional decide finalidades e meios; o fornecedor trata sob instrução. Confirmar por contrato (`DPA_DRAFT.md`). |
| Cadastro e autenticação da profissional | O fornecedor do La Pelve | Supabase | Dados da relação comercial com o usuário. |
| Mensagens WhatsApp (lembretes) | A profissional (relação com o paciente) | O fornecedor; a Meta atua como fornecedora da plataforma | Conteúdo limitado ao necessário. Papel da Meta a revisar nos termos dela. |
| E-mails de autenticação | O fornecedor | Resend (SMTP) | Só e-mail da profissional. |
| Hospedagem do front estático | O fornecedor | Cloudflare | Não recebe dados clínicos; o navegador fala direto com o Supabase. |
| Logs técnicos e relatórios de segurança | O fornecedor | Cloudflare, Supabase | Tendem a conter IP e metadados. |

## Pontos em aberto
- Quem é o **fornecedor** perante a lei (pessoa física ou jurídica, CNPJ): A PREENCHER pelo dono.
- Quem é a **controladora** em cada cliente real: depende do uso (autônoma ou clínica).
- Se o fornecedor trata algum dado clínico para finalidade própria (métricas, melhoria): NÃO VERIFICADO; se houver, passa a ser controlador dessa operação.
- Bases legais (art. 7º e 11): ver `ROPA.md`; a escolha definitiva é da controladora com advogado. Consentimento genérico não deve sustentar tudo.
