# Fornecedores e suboperadores (RASCUNHO)

Informações não consultadas em contrato aparecem como NÃO VERIFICADO. Não foram lidos os DPAs; só o que o código e a configuração mostram.

| Fornecedor | Função | Dados que toca | Evidência no projeto | Região / países | DPA / mecanismo de transferência |
|---|---|---|---|---|---|
| Supabase | Banco (Postgres), Auth, Storage, Edge Functions, Realtime | Todos os dados clínicos e de conta | Projeto do La Pelve (ref no `README`/env) | NÃO VERIFICADO (a CLI usada nesta auditoria não enxerga o projeto) | NÃO VERIFICADO |
| Cloudflare | Hospedagem estática (Workers Assets), DNS, TLS | Nenhum dado clínico (só arquivos do app); IP e metadados de acesso | `wrangler.toml`, headers publicados | Rede global | NÃO VERIFICADO |
| Meta (WhatsApp Business Platform) | Envio de lembretes | Telefone e variáveis do template | Edge Functions `whatsapp-*` | NÃO VERIFICADO | NÃO VERIFICADO |
| Resend | SMTP de e-mails de autenticação | E-mail da profissional | SMTP `smtp.resend.com:465` (print do painel, 19/10/2026) | NÃO VERIFICADO | NÃO VERIFICADO |
| GitHub | Código e CI | Sem dados de pacientes (chaves públicas no build) | Workflows | Global | NÃO APLICÁVEL a dados clínicos |

Ação: o dono precisa consultar, para cada fornecedor, o DPA vigente, a região do projeto, a lista de suboperadores e a política de backup.
