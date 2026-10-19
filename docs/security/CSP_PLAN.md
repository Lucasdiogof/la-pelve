# CSP da La Pelve Web: investigação e plano (2026-10-19)

Estado: **IMPLEMENTADO, PENDENTE DE VALIDAÇÃO** (candidata em `web/_headers`, ainda em Report-Only; nada foi publicado em produção desde `7d0bca5`). A CSP continua **sem bloqueio**. Ativar o bloqueio exige aprovação do dono.

## Estado real publicado (conferido em 19/10/2026)
`https://lapelve.lucksrei.com` envia HSTS, `X-Frame-Options: DENY`, `nosniff`, `Referrer-Policy`, `Permissions-Policy`, `Cache-Control: no-cache` e `Content-Security-Policy-Report-Only` (política antiga, com `www.gstatic.com`, `fonts.gstatic.com` e `https://*.supabase.co`), mais `noindex` no HTML.

## O que foi medido
| Teste | Resultado |
|---|---|
| Flutter 3.47.4 suporta `--no-web-resources-cdn`? | Sim (`flutter build web -h`) |
| Build A (padrão): hosts externos usados | `www.gstatic.com` (CanvasKit .js/.wasm) e `fonts.gstatic.com` (Roboto) |
| Build B (`--no-web-resources-cdn`): requisições externas na tela de login | **Nenhuma**; CanvasKit em `/canvaskit/`, Poppins e Roboto locais |
| Build B: violações de CSP com a política candidata (sem gstatic, Supabase do projeto) em `/`, `/privacy`, `/data-deletion` | **Zero** (Chromium embutido do app de teste) |
| Tamanho | Maior arquivo 7,3 MB (limite de 25 MiB por arquivo da Cloudflare); 70 arquivos |
| Segredos no bundle | `check-bundle-secrets.sh`: OK |
| Regra `! Content-Security-Policy-Report-Only` no `_headers` | Validada com `wrangler dev --local`: `/whatsapp-connect` recebe só a política própria |

Não medido: tempo de carregamento comparado, Firefox/Safari/Edge, service worker (desativado no build atual), fluxo autenticado completo e a página `/whatsapp-connect` com o SDK da Meta (precisa de `state` válido).

## Achado importante: SDK da Meta
`web/whatsapp-connect.html` carrega `https://connect.facebook.net/en_US/sdk.js` e usa popup e frames do Facebook. Uma CSP global bloqueante **quebraria** a conexão do WhatsApp. Por isso a rota `/whatsapp-connect*` tem política própria (`script-src` com o hash da página e `connect.facebook.net`; `frame-src` e `connect-src` com `facebook.com` e `graph.facebook.com`), e o `_headers` remove o header herdado com `!`.

## Diretivas
| Diretiva | Situação candidata | Observação |
|---|---|---|
| `default-src 'self'` | Ok | Base |
| `script-src` | `'self' 'wasm-unsafe-eval'` + 2 hashes (splash e páginas estáticas) | `wasm-unsafe-eval` é exigido pelo CanvasKit. Sem `unsafe-inline`/`unsafe-eval`. Se o splash do `index.html` mudar, o hash muda: recalcular. |
| `style-src` | `'self' 'unsafe-inline'` | Flutter e páginas estáticas usam estilo inline. Removi nenhuma permissão por scanner; avaliar nonces só se o renderer permitir (não testado). |
| `img-src` | `'self' data: blob: https://<ref>.supabase.co` | Avatares/anexos por URL assinada do mesmo host |
| `font-src` | `'self' data:` | Fontes locais no build B |
| `connect-src` | `'self' https://<ref>.supabase.co wss://<ref>.supabase.co` | `<ref>` = projeto da La Pelve; cobre REST, Auth, Storage, Functions e Realtime |
| `worker-src` | `'self' blob:` | Flutter pode usar Workers de blob |
| `manifest-src`, `object-src`, `base-uri`, `form-action`, `frame-ancestors` | restritos | `frame-ancestors 'none'` só vale por header (já é header) |
| `upgrade-insecure-requests` | Não adicionada | HSTS já cobre |
| `report-to`/`report-uri` | Não configuradas | Ver coletor |
| Trusted Types (`require-trusted-types-for 'script'`) | **Não ativar** | Não testado com a engine Flutter e bibliotecas; avaliar só em Report-Only |

## Coleta de relatórios (gratuita), DESENHO, NÃO CRIADO
Criar um Worker público separado exige a sua aprovação. Proposta: Worker `la-pelve-csp-report` com `POST /r`; aceita `application/csp-report` e `application/reports+json`, corpo de no máximo 8 KB; guarda só agregados (`directive`, `blocked-host`, contagem por dia) em D1 ou KV, **sem** URL completa (remove query e fragment), sem IP, sem user-agent; rate limit por binding; retenção de 30 dias; sem acesso ao Supabase. Header: `Reporting-Endpoints: csp="https://.../r"` e `report-to csp` na CSP (Chromium); `report-uri` como fallback (Firefox/Safari têm suporte parcial a `report-to`). Custo: dentro do plano gratuito para este volume (confirmar limites atuais). Sem coletor, o monitoramento é manual pelo console dos navegadores.

## Gate para ativar o bloqueio
1. Publicar o build B com `FLUTTER_WEB_FLAGS=--no-web-resources-cdn` (já no `deploy.yml`) e o novo `_headers`, ainda em Report-Only.
2. Percorrer logado em Chrome, Edge e Firefox: login, logout, recuperação de senha, cadastro, agenda, pacientes fictícios, prontuário, evolução, financeiro, upload e visualização de anexo, foto de perfil, Realtime, `/whatsapp-connect`.
3. Zero violações legítimas de `script-src`, `connect-src`, `worker-src`, `img-src`; zero erros de CanvasKit.
4. Coletor ativo por alguns dias de uso real, sem violações novas.
5. Rollback definido: trocar `Content-Security-Policy` por `...-Report-Only` no `_headers` e republicar (workflow `deploy.yml`) ou reverter com `rollback-web.yml`.
6. Aprovação explícita do dono.
