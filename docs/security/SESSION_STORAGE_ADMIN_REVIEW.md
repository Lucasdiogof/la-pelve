# Sessão Web, anexos e acesso administrativo (2026-10-19)

Estado geral: **DOCUMENTADO PARA REVISÃO**. Nada foi alterado em Auth, RLS ou Storage de produção nesta rodada. Itens sem acesso ao painel ficam como NÃO VERIFICADO.

## Sessão do Supabase na Web
- `supabase_flutter` guarda a sessão em `localStorage`. Um XSS leria o token. Mitigação principal: CSP bloqueante (`CSP_PLAN.md`) e dependências revisadas. Trocar para cookie HttpOnly exigiria um backend intermediário: **não proposto** (sem necessidade demonstrada).
- Em `lib/` não há logout por inatividade nem bloqueio biométrico na Web. Em computador compartilhado, só o logout manual protege. Um bloqueio apenas visual **não revoga** a sessão.
- Propostas (nenhuma implementada):
  1. Logout por inatividade que chama `auth.signOut()` (revogação real), com tempo curto na Web (valor a decidir; sugestão inicial 15 a 30 min sem interação).
  2. Reautenticação (senha) antes de exportar e de excluir a conta. O repositório já tem `verifyPassword`.
  3. Refresh token rotation e expiração do access token: conferir em **Authentication → Sessions/JWT** no painel (NÃO VERIFICADO). Time-box e inatividade de sessão do Supabase são recursos de planos pagos, então a alternativa compatível com o plano atual é o logout por inatividade no cliente.
  4. MFA (TOTP) para profissionais: suportado pelo Supabase Auth; avaliar custo de suporte e recuperação antes de exigir.
  5. Trilha de auditoria de operações críticas (login, exportação, exclusão) sem conteúdo clínico: NÃO IMPLEMENTADA.

## Anexos e Storage
Verificado nas migrations (`0007`, `0008`): buckets `patient-attachments` e `avatars` privados; política por pasta `{auth.uid()}`; acesso por URL assinada de 1 hora (`createSignedUrl(..., 3600)`); anexos abertos com `launchUrl` externo (nova aba/app).
- **Cache dos anexos: NÃO VERIFICADO.** O `Cache-Control` do site estático não protege objetos do Supabase Storage. Teste seguro pendente (precisa de conta de teste e arquivo fictício): conferir o header de resposta de uma URL assinada e se o navegador a guarda no disco. Mitigações possíveis: `cacheControl` no upload, URL curta, abrir na mesma aba autenticada.
- Restrições de tipo e tamanho no servidor: não verificadas (o app usa `file_picker`).
- Acesso após logout: a URL assinada vale até expirar (1 h) mesmo após logout; risco residual aceito ou reduzir a validade (decisão).
- Isolamento entre contas: políticas por pasta no código; **teste com duas contas fictícias pendente**. Existe suíte SQL de RLS no CI para as tabelas WhatsApp; não há teste de isolamento de `patients`/`attachments`.

## Acesso administrativo (NÃO VERIFICADO, precisa do dono)
Responder fora do código: quem tem acesso ao painel do Supabase e à Cloudflare, com qual privilégio e MFA; se o desenvolvedor pode ler `patients`/`evolution_entries` e o Storage via `service_role` ou SQL Editor (tecnicamente sim, no painel do projeto); existência de logs de auditoria; política de suporte (acesso só sob pedido, com registro); revogação de credenciais (token da Cloudflare no GitHub, chaves do Supabase). Recomendação: ativar MFA nas duas contas, registrar acessos a dados clínicos e documentar a política no DPA (`DPA_DRAFT.md`, item 4).
