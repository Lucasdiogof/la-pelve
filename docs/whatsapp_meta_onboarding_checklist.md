# Embedded Signup — prontidão (Meta) e roteiros do App Review

Estado em 2026-10-12. Só afirma o que foi **verificado** (código, produção ou documentação oficial da Meta). O que a
documentação não diz está marcado **NÃO CONFIRMADO**. Nada aqui afirma que uma permissão foi aprovada: isso só se vê no
painel da Meta.

## 0. Atualização 2026-10-29 (Etapa 1: domínio e OAuth)

- Domínio oficial: `https://lapelve.lucksrei.com` (Worker `la-pelve`, rota em `wrangler.toml`). O `workers.dev` foi desativado e responde 404.
- `WHATSAPP_CONNECT_PAGE_URL` ainda aponta para o `workers.dev` (conferido pelo hash do secret) e **precisa** passar a `https://lapelve.lucksrei.com/whatsapp-connect` antes de ligar o onboarding.
- Página `/whatsapp-connect` no ar (200, título conferido), SDK `connect.facebook.net` acessível, CSP da página bate com o script em produção, `postMessage` só aceita `facebook.com`/`*.facebook.com`, tokens só no servidor, `META_APP_ID` = 2811023262627717 (hash conferido). Onboarding segue DESLIGADO.

## 1. Concluído e verificado

| Item | Evidência |
|---|---|
| Página pública do onboarding | `https://lapelve.lucksrei.com/whatsapp-connect` responde 200 com o título "La Pelve · Conectar WhatsApp" (o site é SPA: outras rotas inexistentes também devolvem 200, por isso conferi o título) |
| Configuração do JavaScript SDK | `web/whatsapp-connect.html` segue o exemplo oficial: `FB.init({appId, version})` com versão da Graph vinda do servidor (`v25.0`) e `FB.login` com `config_id`, `response_type: 'code'`, `override_default_response_type: true`, `extras: {setup: {}}` |
| Tratamento do retorno do popup | ouve `message` só de `*.facebook.com`, `type = WA_EMBEDDED_SIGNUP`; trata `FINISH`, `FINISH_WHATSAPP_BUSINESS_APP_ONBOARDING` e `CANCEL`; o `state` vai no fragmento da URL (não vai ao servidor nem ao Referer) |
| Troca do code | `GET /oauth/access_token` com `client_id`, `client_secret`, `code`, sem `redirect_uri`, igual à documentação; só no servidor, em até 30 s (validade do code) |
| Posse do número | o token novo precisa enxergar o `phone_number_id` dentro da `waba_id` recebida do navegador |
| Token guardado | Vault (nunca em tabela comum, log ou resposta); renovado no mesmo segredo na reconexão |
| Assinatura de webhook por WABA | `POST /{waba}/subscribed_apps` (idempotente); removida ao desconectar se nenhuma outra profissional usa a WABA |
| Registro do número | `POST /{phone}/register` com PIN de 6 dígitos no Vault; guard no banco (limite 10/72 h da Meta, cooldown, nunca em número já CONNECTED) |
| Webhook (endpoint) | `GET` com verify token errado = 403; `POST` sem/ com assinatura inválida = 401; corpo acima de 3 MiB = 413 (testado com 3,2 MB e 18 MB); HMAC-SHA256 em tempo constante sobre os bytes originais |
| Eventos tratados | `messages` (resposta "Confirmar" da paciente), `statuses` (sent/delivered/read/failed), `message_template_status_update` (só os 2 templates da prontidão) e `account_update` (revogação/restrição) |
| Templates | `appointment_confirmation` e `appointment_12h`, `pt_BR`, categoria UTILITY (o de lembrete com botão rápido "Confirmar"); só `connected` com os dois APPROVED e conta `AVAILABLE` |
| Validade do token | `debug_token` na abertura da tela: inválido -> `error`/`token_invalid` com botão Reconectar; vencendo em <= 7 dias -> aviso com a data; validade conhecida é mostrada. O envio com erro 190 também marca a conexão (atômico e vinculado ao hash do token usado, migration 0035). Indisponibilidade da Meta nunca marca |
| Segredos no Supabase | presentes: `META_APP_ID`, `META_ES_CONFIG_ID`, `WHATSAPP_CONNECT_PAGE_URL`, `WHATSAPP_GRAPH_API_VERSION`, `WHATSAPP_TEMPLATE_LANGUAGE`, `WHATSAPP_APP_SECRET`, `WHATSAPP_VERIFY_TOKEN`, `WHATSAPP_DISPATCHER_TOKEN`, `WHATSAPP_TEMPLATE_APPOINTMENT_12H` |
| Onboarding desligado | `WHATSAPP_SELF_CONNECT_ENABLED` ausente: `start` responde 503 `not_configured` e o app não mostra o botão |
| Política de privacidade e exclusão de dados | `https://lapelve.lucksrei.com/privacy` e `https://lapelve.lucksrei.com/data-deletion` servem o próprio HTML (títulos e seções pt/en/es conferidos em produção; rotas inexistentes seguem caindo no app). Texto conferido contra o comportamento real (exclusão de conta em cascata + limpeza best-effort de arquivos, desconexão do WhatsApp, cópias de segurança e Meta fora do nosso controle). Contato público: `marketing@lucksrei.com` (MX do domínio aponta ao Cloudflare Email Routing e o endereço é o contato do site lucksrei.com; **entrega de e-mail não testada por mim**) |
| Saúde | `supabase/ops/whatsapp_health.sql` (migration 0036) resume falhas, fila, conexões, cron e consentimento sem dados de paciente |

## 2. Ações manuais restantes no painel da Meta (nada abaixo foi verificado por mim: não tenho acesso ao painel)

URLs públicas a usar:
- Política de privacidade: `https://lapelve.lucksrei.com/privacy`
- Exclusão de dados: `https://lapelve.lucksrei.com/data-deletion`
- Página do Embedded Signup (Allowed domains e Valid OAuth redirect URIs): `https://lapelve.lucksrei.com/whatsapp-connect`
- Callback do webhook: `https://lchaboncmgcimafpupad.supabase.co/functions/v1/whatsapp-webhook` (verify token = secret `WHATSAPP_VERIFY_TOKEN`)

1. **App settings → Basic:** colar as URLs de privacidade e de exclusão de dados; conferir ícone, categoria e e-mail de contato.
2. **Facebook Login for Business → Settings → Client OAuth settings:** em **Yes**: Client OAuth login, Web OAuth login, Enforce HTTPS, Embedded Browser OAuth Login, Use Strict Mode for redirect URIs, Login with the JavaScript SDK; colocar a URL do Embedded Signup em *Allowed domains* e em *Valid OAuth redirect URIs*.
3. **Configurations → `4693096200923752`:** conferir o tipo e a expiração do token (a documentação lida não informa o prazo: NÃO CONFIRMADO).
4. **WhatsApp → Configuration (webhook):** callback acima; campos `messages`, `message_template_status_update` e `account_update`.
5. **App Review / Tech Provider:** pedir `whatsapp_business_management` e `whatsapp_business_messaging`; um vídeo por permissão com explicação escrita (roteiros na seção 5); enviar. Conferir no painel o que consta como pendente (verificação do negócio etc.).
6. Depois dos itens 1–4: ligar `WHATSAPP_SELF_CONNECT_ENABLED=true` nos secrets da função `whatsapp-connect` para o primeiro teste real.

## 3. Bloqueio técnico

Nenhum bloqueio de código conhecido. O primeiro teste real só depende dos itens 1–5 acima e de ligar
`WHATSAPP_SELF_CONNECT_ENABLED=true` nos secrets da função `whatsapp-connect` (só então o botão aparece no app).

Ordem do primeiro teste: (a) itens 1–5 feitos; (b) ligar a flag; (c) conectar com um número de TESTE seu;
(d) conferir `status = connected`, templates APPROVED, webhook respondendo e `whatsapp_health_summary()` sem problemas;
(e) só depois qualquer envio, para paciente de teste com consentimento próprio. Pacientes reais seguem sem consentimento
ativo.

## 4. Fluxo e onde cada passo vive

| Passo | Onde |
|---|---|
| Botão "Conectar WhatsApp" | Flutter `whatsapp_connection_page.dart` -> `whatsapp-connect` `start` (só com `availability.enabled`) |
| `state` de uso único (256 bits, hash no banco, 15 min) | `whatsapp-connect` |
| Página de onboarding | `web/whatsapp-connect.html` |
| Troca do code, posse do número, Vault, webhook, registro, templates | `whatsapp-connect` `complete` |
| Reavaliação (pendente) e checagem do token (conectada) | `whatsapp-connect` `status` |
| Eventos de template/entrega/conta e respostas da paciente | `whatsapp-webhook` |
| Envio e marcação de token recusado | `whatsapp-dispatcher` + migration 0035 |
| Observabilidade | logs estruturados (`whatsapp_dispatcher_run` com `codes`, `template_status_processed.negative`, `payload_too_large`, `invalid_signature`) e `whatsapp_health_summary()` |

## 5. Roteiros dos vídeos do App Review

### Vídeo 1 — `whatsapp_business_management`

Texto para o campo de explicação: "La Pelve is a scheduling app for pelvic-floor physiotherapists. Each professional
connects her own WhatsApp Business account through Embedded Signup. With this permission the app (a) reads the
professional's WhatsApp Business Account and phone number to confirm they belong to her, (b) subscribes our app to the
account's webhooks, and (c) creates and reads the status of the two utility message templates the app uses
(appointment notice and appointment confirmation request). We only access the assets of professionals who completed
Embedded Signup."

Cena a cena (gravar tela + áudio ou legendas, ~3 min):
1. App La Pelve -> Perfil -> WhatsApp: tela "Conectar WhatsApp" (mostrar o botão).
2. Tocar em Conectar -> abre a página -> "Continuar com a Meta" -> popup oficial do Embedded Signup: escolher/criar a
   conta WhatsApp Business, informar o número de teste, concluir.
3. A página mostra "Conexão concluída"/"aguardando aprovação"; voltar ao app e tocar "Atualizar status": mostrar o
   número conectado.
4. Abrir o WhatsApp Manager -> Message templates: mostrar `appointment_confirmation` e `appointment_12h` criados pelo app,
   com status (Pendente/Aprovado) e a categoria Utility.
5. Voltar ao app e mostrar o status final "Conectado". Encerrar.

### Vídeo 2 — `whatsapp_business_messaging`

Texto para o campo de explicação: "The app sends appointment notices and confirmation requests (template messages) to
patients who gave explicit WhatsApp consent, from the professional's own WhatsApp Business number, and receives the
patient's reply to mark the appointment as confirmed. Messages are only sent for upcoming appointments, never to
patients without an active consent, and replies are used only to confirm the appointment."

Cena a cena (~3 min, usar SOMENTE paciente de teste com o seu número):
1. No app: paciente de teste com telefone e consentimento de WhatsApp registrado (mostrar o campo de consentimento).
2. Criar a consulta (data futura): mostrar na edição da consulta o bloco "Lembretes pelo WhatsApp" com "Programado".
3. Mostrar o WhatsApp do celular de teste recebendo a mensagem do número conectado (tela do aparelho ao lado ou
   WhatsApp Web), com o texto do template e o botão "Confirmar".
4. Tocar "Confirmar" no celular: voltar ao app e mostrar a consulta como Confirmada e o lembrete como Entregue/Lido.
5. Encerrar. Não mostrar dados de pacientes reais nem tokens.

## 6. Fontes (documentação oficial da Meta)

- Embedded Signup — implementação: https://developers.facebook.com/docs/whatsapp/embedded-signup/implementation
- Onboarding como Tech Provider: https://developers.facebook.com/documentation/business-messaging/whatsapp/embedded-signup/onboarding-customers-as-a-tech-provider
- App Review para Tech Providers: https://developers.facebook.com/documentation/business-messaging/whatsapp/solution-providers/app-review
- Access tokens: https://developers.facebook.com/documentation/business-messaging/whatsapp/access-tokens
