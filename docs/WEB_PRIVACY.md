# La Pelve Web: revisão de privacidade e segurança (2026-10-17)

Escopo: versão web do app (Flutter Web em Cloudflare Workers, Worker `la-pelve`, hoje em `la-pelve.lucasdiogo1234.workers.dev`).
Revisão feita sobre o código e as migrations do repositório. **Não houve teste ao vivo com contas reais nem acesso ao painel do Supabase.**
Não é parecer jurídico: a base legal e o texto final da LGPD são do controlador (a profissional) e do dono do produto.

## O que foi verificado e está adequado
| Ponto | Achado |
|---|---|
| RLS | Todas as 14 tabelas criadas nas migrations têm `enable row level security` (patients, evolution_entries, appointments, attachments, financial_entries, patient_consents, profiles e as tabelas WhatsApp). Políticas por `auth.uid() = fisioterapeuta_id`. |
| Storage | Buckets `patient-attachments` e `avatars` são **privados**; política restringe a pasta `{auth.uid()}/...`. Acesso por link temporário. |
| Funções `security definer` | Migration 0031 revoga `execute` de `anon`/`public`; `delete_own_account` só para `authenticated`. |
| Dados clínicos no navegador | **Nenhum.** A web usa a fábrica de armazenamento *stub* (`local_store_factory_stub.dart`): o SQLite cifrado só existe em Android/iOS. Só ficam no navegador preferências (tema, idioma, ocultar financeiro, biometria) e a sessão do Supabase. |
| Chaves no bundle | `scripts/check-bundle-secrets.sh` no build: sem `service_role`/`sb_secret_`. |
| Política de privacidade | `web/privacy.html` (pt/en/es, atualizada em 12/10/2026) e `web/data-deletion.html` cobrem dados, WhatsApp/Meta, retenção, exclusão e direitos LGPD. |
| Exclusão de conta | Existe no app (Perfil, Excluir conta) e remove em cascata. |

## Alterações feitas nesta rodada
- `web/_headers`: HSTS, `nosniff`, `X-Frame-Options: DENY` (impede embutir o app em outro site), `Referrer-Policy`, `Permissions-Policy` (câmera/microfone/geolocalização bloqueados; o app só usa seletor de arquivos) e `Cache-Control: no-cache`.
- `web/index.html`: `<meta name="robots" content="noindex, nofollow">` para o app não ser indexado por buscadores. `privacy.html`, `data-deletion.html` e `whatsapp-connect.html` continuam acessíveis por link (exigência das lojas e da Meta).
- Scripts e checagem de segredos do template; rota `lapelve.lucksrei.com` **comentada** em `wrangler.toml`.

## Riscos residuais e recomendações (decisão do dono)
1. **Sessão em localStorage** (padrão do supabase_flutter na web): vulnerável a XSS. Mitigação adequada seria uma CSP; não foi ativada por falta de teste (CanvasKit exige `wasm-unsafe-eval`). Recomendo testar uma CSP em modo `Content-Security-Policy-Report-Only` antes de divulgar a web a clientes.
2. **Bloqueio biométrico não existe na web.** Em computador compartilhado, o logout manual é a única proteção. Considerar expirar a sessão web mais cedo (configuração de Auth do Supabase, não alterada).
3. **E-mail de cadastro na web** usa `emailRedirectTo = <origem atual>/`. Ao ativar `lapelve.lucksrei.com`, essa URL precisa constar nas Redirect URLs do Supabase (hoje deve constar só a de workers.dev). Alteração de Auth **não feita**; recuperação de senha por código continua sem redirect.
4. **SMTP:** o e-mail embutido do Supabase envia só 2 por hora; confirmar SMTP custom no projeto.
5. **Cloudflare e dados:** o Worker só serve arquivos; os registros clínicos trafegam direto navegador ↔ Supabase (HTTPS). A política já informa isso.
6. **Domínio público:** a URL `workers.dev` já está pública desde o deploy automático existente. Divulgar o subdomínio só depois dos itens 1 a 4 e da sua autorização. Antes de aceitar clientes reais na web, definir o encarregado (DPO)/contato LGPD e o registro de operações de tratamento.
7. Anexos clínicos abertos no navegador são baixados por URL temporária; o cache do navegador pode guardá-los. Não foi testado se o Supabase envia `Cache-Control: no-store` nessas URLs.
