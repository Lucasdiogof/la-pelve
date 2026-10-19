# Registro das operações de tratamento (LGPD, art. 37) — MODELO (RASCUNHO)

Preenchimento preliminar a partir do código. `A PREENCHER` = depende do controlador; `NÃO VERIFICADO` = não foi possível comprovar. Não é parecer jurídico. Cada controladora (profissional ou clínica) mantém o seu registro; este modelo é o ponto de partida do fornecedor como operador.

Campos comuns: **Controlador:** A PREENCHER (profissional/clínica, no caso dos dados de pacientes). **Operador:** fornecedor do La Pelve (A PREENCHER: nome/CNPJ). **Encarregado:** NÃO INDICADO (ver `LEGAL_DECISIONS.md`). **Responsável pela operação:** A PREENCHER. **Última revisão:** 2026-10-19.

| # | Operação | Titulares | Dados (sensíveis em negrito) | Finalidade | Base legal candidata (a confirmar) | Origem | Compartilhamento / fornecedores | Transf. internacional | Retenção | Segurança (evidência) |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Cadastro profissional | Fisioterapeutas | nome, CREFITO, telefone, e-mail | Prestar o serviço | Execução de contrato | Titular | Supabase | NÃO VERIFICADO | Enquanto a conta existir | RLS em `profiles` (0038) |
| 2 | Autenticação | Fisioterapeutas | e-mail, senha (hash), sessão | Acesso seguro | Execução de contrato | Titular | Supabase Auth; Resend (e-mails) | NÃO VERIFICADO | Conta | Supabase Auth; SMTP conferido (print 19/10) |
| 3 | Cadastro de pacientes | Pacientes | nome, idade, telefone, profissão, **dados de saúde** | Gestão clínica | Tutela da saúde / obrigação legal (art. 11, II) | Profissional | Supabase | NÃO VERIFICADO | A DEFINIR (`DATA_RETENTION.md`) | RLS por `fisioterapeuta_id` |
| 4 | Anamnese e históricos | Pacientes | **ginecológico, obstétrico, cirúrgico, urinário, sexual, intestinal** | Avaliação clínica | Tutela da saúde | Profissional | Supabase | NÃO VERIFICADO | A DEFINIR | RLS; JSONB em `patients` |
| 5 | Prontuário e evoluções | Pacientes | **registros clínicos** | Atendimento e guarda | Obrigação legal/regulatória (art. 11, II, a) | Profissional | Supabase | NÃO VERIFICADO | A DEFINIR (mín. 5 e 20 anos citados) | RLS; soft delete de pacientes |
| 6 | Agenda | Pacientes | nome, data/hora, status | Organização | Execução do serviço | Profissional | Supabase | NÃO VERIFICADO | A DEFINIR | RLS; Realtime |
| 7 | Financeiro | Pacientes, profissional | valores, formas de pagamento | Controle financeiro | Obrigação legal/contrato | Profissional | Supabase | NÃO VERIFICADO | A DEFINIR | RLS |
| 8 | Anexos clínicos | Pacientes | **fotos e documentos de saúde** | Registro clínico | Tutela da saúde | Profissional | Supabase Storage | NÃO VERIFICADO | A DEFINIR | Bucket privado, política por pasta `{uid}`, URL assinada 1 h |
| 9 | Consentimentos | Pacientes | canal, finalidade, telefone autorizado, datas | Comprovar autorização | Exercício regular de direitos | Profissional | Supabase | NÃO VERIFICADO | A DEFINIR | Histórico append-only (0018/0019). Falta registrar versão do texto aceito (ver `LEGAL_DECISIONS.md`). |
| 10 | Mensagens WhatsApp | Pacientes | telefone, nome do paciente e dados da consulta nas variáveis do template | Lembrete de consulta | Consentimento específico (a confirmar) | Sistema | Meta (WhatsApp Business Platform) | SIM (Meta; local NÃO VERIFICADO) | A DEFINIR | Token cifrado no Vault; webhook com HMAC; logs só com contagens |
| 11 | E-mails transacionais | Profissionais | e-mail | Confirmação e recuperação de senha | Execução de contrato | Sistema | Resend | NÃO VERIFICADO | Retenção do Resend | SMTP com TLS (porta 465) |
| 12 | Logs e relatórios técnicos | Visitantes e profissionais | IP, user-agent, rotas (por fornecedor) | Segurança e operação | Legítimo interesse (a avaliar) | Sistema | Cloudflare, Supabase | NÃO VERIFICADO | NÃO VERIFICADO | CSP Report-Only (sem coletor ainda) |
| 13 | Exportação de dados | Pacientes, profissional | todo o prontuário | Custódia e portabilidade | A DEFINIR | Profissional | — | — | — | NÃO IMPLEMENTADO |
| 14 | Exclusão de conta | Profissional e pacientes | todos | Encerramento | Pedido do titular + guarda | Profissional | Supabase | — | — | Trava de custódia (0039), pendente de aplicação |
