# Embedded Signup — checklist de prontidão (Meta) e roteiros do App Review

Estado em 2026-10-12. Só afirma o que foi verificado no código/produção ou lido na documentação oficial da Meta
(links no fim). O que a documentação não diz está marcado **NÃO CONFIRMADO**.

## 1. Fluxo e onde cada passo vive

| Passo | Onde | Observação |
|---|---|---|
| Botão "Conectar WhatsApp" | Flutter `whatsapp_connection_page.dart` -> `whatsapp-connect` `start` | só aparece com `availability.enabled` (flag desligada hoje) |
| `state` de uso único (256 bits, hash no banco, 15 min) | `whatsapp-connect` | vai no fragmento da URL, nunca em query/Referer |
| Página de onboarding | `web/whatsapp-connect.html` (Cloudflare Workers) | `FB.login` com `config_id`, `response_type: code`, `override_default_response_type` |
| Retorno `WA_EMBEDDED_SIGNUP` | mesma página | aceita só origem `*.facebook.com`; `FINISH` e `FINISH_WHATSAPP_BUSINESS_APP_ONBOARDING` |
| Troca do code (vale 30 s) | `whatsapp-connect` `complete` | `GET /oauth/access_token` com `client_id`, `client_secret`, `code` (sem `redirect_uri`, igual à documentação) |
| Posse do número | `complete` | o token novo precisa enxergar o `phone_number_id` dentro da `waba_id` |
| Token | Vault (`whatsapp_connection_credentials`) | nunca em tabela comum, log ou resposta |
| Webhook por WABA | `POST /{waba}/subscribed_apps` | idempotente |
| Registro do número | `POST /{phone}/register` (PIN de 6 dígitos no Vault) | guard no banco (0032): limite, cooldown, nunca em número já CONNECTED |
| Templates | cria/lê `appointment_confirmation` e `appointment_12h` (pt_BR) | só fica `connected` com os dois APPROVED e conta `AVAILABLE` |
| Estado | `whatsapp_connections.status` | `pending` -> `connected`; `error` em revogação/token |

## 2. Validade do token (corrigido neste ciclo)

- A documentação lida **não informa** o prazo do business token do Embedded Signup. O nome do template de configuração
  ("WhatsApp Embedded Signup Configuration With 60 Expiration Token") sugere 60 dias: **NÃO CONFIRMADO**. Veja a ação 3.1.
- Agora o sistema não depende de saber o prazo:
  - `status` em conexão `connected` consulta `GET /debug_token` (token de app só no header). Inválido/expirado/revogado ->
    conexão vira `error` / `token_invalid`; vencendo em <= 7 dias -> o app mostra a data e o botão **Reconectar**.
  - Se a Meta recusar um envio com erro 190, o dispatcher marca a conexão como `error`/`token_invalid`: os envios param
    em vez de falhar um a um sem aviso, e o app pede reconexão. A marcação é **atômica e vinculada ao token usado**
    (migration 0035, `flag_whatsapp_connection_token_invalid`): o banco trava a linha, relê o token do Vault e compara o
    SHA-256 com o do token recusado; se a profissional já reconectou (token novo no mesmo segredo), desconectou ou trocou
    de número, a resposta velha é ignorada (`stale`/`skipped`). Nenhum token trafega ou é logado, só o hash.
  - Indisponibilidade da Meta (timeout, 429, 5xx) ou recusa da credencial do app NUNCA marcam a conexão: só um
    `is_valid:false` explícito do `/debug_token` conta.
  - Reconectar = repetir o Embedded Signup; uma linha em `error` é regravada com o token novo.
  - A reconexão NÃO reenvia mensagens que já falharam por token (são definitivas).

## 3. Ações que dependem de você (painel da Meta)

1. **Tipo/prazo do token** — App Dashboard -> Facebook Login for Business -> Configurations -> abra a configuração
   `4693096200923752`. Confira em "Access token" o tipo (Business Integration System User) e a expiração. Se houver
   opção de expiração maior, prefira-a; se for 60 dias, mantenha (o app já avisa e pede reconexão).
2. **Client OAuth settings** — App Dashboard -> Facebook Login for Business -> Settings -> Client OAuth settings.
   Todos em **Yes**: Client OAuth login, Web OAuth login, Enforce HTTPS, Embedded Browser OAuth Login, Use Strict Mode for
   redirect URIs, Login with the JavaScript SDK.
3. **Domínio** — nos mesmos Settings, **Allowed domains** e **Valid OAuth redirect URIs** devem conter
   `https://la-pelve.lucasdiogo1234.workers.dev/whatsapp-connect` (e o domínio sem caminho, se o painel pedir).
   Sem isso o popup não devolve `waba_id`/`phone_number_id`/`code`.
4. **Webhooks** — WhatsApp -> Configuration (e/ou Webhooks do app): callback
   `https://lchaboncmgcimafpupad.supabase.co/functions/v1/whatsapp-webhook`, verify token igual ao secret
   `WHATSAPP_VERIFY_TOKEN`, campos assinados: `messages`, `message_template_status_update` e `account_update`
   (a documentação marca `account_update` como obrigatório para Embedded Signup).
5. **App Review (Advanced access)** — pedir `whatsapp_business_management` e `whatsapp_business_messaging`; um vídeo por
   permissão, cada um com explicação escrita (roteiros abaixo). Rascunho não é analisado: é preciso enviar.
6. **Pré-requisitos de conta/app** — verificação do negócio (Lucksrei), URL de política de privacidade e demais campos
   do cadastro do app: a documentação lida não detalha; confira no painel o que está marcado como pendente.
7. **Embedded Signup v2** deixa de existir em 15/10/2026. Usamos configuração v4 (Config ID acima): nada a migrar.

## 4. Antes do primeiro teste real (depende de você + deploy)

Ordem: (a) itens 3.1–3.4 conferidos; (b) definir `WHATSAPP_SELF_CONNECT_ENABLED=true` nos secrets da função
(só então `availability` devolve `true` e o botão aparece no app); (c) conectar com um número de TESTE que seja seu;
(d) conferir `status = connected`, templates APPROVED e webhook respondendo; (e) só depois qualquer envio real, para
paciente de teste com consentimento próprio. Pacientes reais seguem sem consentimento ativo e fora de qualquer teste.

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
