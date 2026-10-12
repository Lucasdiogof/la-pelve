# Integração WhatsApp (lembretes de agendamento) — estado e próximos passos

## >>> ATUALIZAÇÃO 2026-10-12 (rollout do PR #11 em produção — verificado)

- `main` = `47e462e`. Edge Functions publicadas a partir dela, todas `ACTIVE`, `verify_jwt=false` (autenticação própria): `whatsapp-webhook` **v26**, `whatsapp-connect` **v11**, `whatsapp-dispatcher` **v13**, `whatsapp-scheduler-dry-run` **v20**.
- Smoke tests HTTP (sem credenciais, sem efeito colateral): webhook POST sem assinatura 401, com assinatura inválida 401, GET com verify token errado 403; dispatcher POST sem Bearer 401, com Bearer falso 401, GET 405; scheduler-dry-run POST sem/ com Bearer falso 401; connect GET 405, `start` sem auth 503 `not_configured` (onboarding DESLIGADO: `WHATSAPP_SELF_CONNECT_ENABLED` ausente), `availability` sem auth 401.
- Banco (somente leitura): funções da 0034 presentes (`templates_verified_at` nas duas de escrita), sem EXECUTE para `anon`/`authenticated`; cron `*/5 * * * *` ativo, 30 execuções `succeeded` e 30 respostas HTTP 200 nas últimas 3 h; 0 consentimentos ativos (3 revogados); 81 consultas, 20 pacientes; mensagens: 0 `scheduled`/`processing` (1 `sent`, 3 `failed`, 5 `cancelled`, todas antigas).
- Não verificado: logs de runtime das funções (a API de analytics de logs do Supabase respondeu "Backend error"/tabelas inexistentes); conferir no Dashboard → Edge Functions → Logs.

## >>> ATUALIZAÇÃO 2026-10-12 (histórico de templates, reavaliação automática, logs, app)

- Bug da auditoria do PR #10: o `whatsapp-connect` regravava `setup_state` inteiro e apagava `setup_state.templates`. **`0034_whatsapp_template_history_merge.sql`**:
  - `upsert_whatsapp_connection_from_signup` (mesma assinatura): `templates` e `templates_verified_at` são chaves do SERVIDOR, mantidas da linha travada (nunca do cliente; só valem para a mesma WABA). Entrada `evaluated_at` (início da avaliação, não é gravada). `connected` é recusado com **WA010** se há evento negativo de template mais novo que `max(evaluated_at, templates_verified_at)`; ao conectar, `templates_verified_at = evaluated_at`.
  - `apply_whatsapp_template_status` ignora eventos com instante `<= templates_verified_at` (a consulta completa à Meta já os refletiu): REJECTED atrasado não rebaixa mais.
  - `list_whatsapp_template_reevaluation_candidates(waba)`: pendentes só por template.
  - `whatsapp-connect`: manda `evaluated_at`; WA010 → fica `pending/templates_pending` (nunca conecta).
- **Reavaliação automática:** APPROVED/REINSTATED/UNARCHIVED de template da prontidão no webhook disparam (em segundo plano, `EdgeRuntime.waitUntil`) uma checagem só de LEITURA na Meta com o token da conexão: número CONNECTED + os dois templates aprovados + conta disponível. Só então promove, pelo mesmo upsert (WA010 vale). O evento sozinho nunca conecta; nada é criado/inscrito/registrado na Meta. Não depende de `WHATSAPP_SELF_CONNECT_ENABLED` (o onboarding segue desligado).
- **Logs:** removidos wamid (confirmação), ids de mensagem/consulta (despacho, materialização, reconciliação) e texto bruto de erro (dry-run).
- **App:** na edição da consulta, bloco "Lembretes pelo WhatsApp" (aviso de agendamento / pedido de confirmação / aviso de remarcação) com Programado/Enviando/Enviado/Entregue/Lido/Não entregue/Cancelado e horário; só leitura via RLS, sem telefone/wamid; some quando não há lembrete.

## >>> ATUALIZAÇÃO 2026-10-12 (PR #10, webhooks de status e de templates)

- `0033_whatsapp_status_and_template_webhooks.sql`:
  - `apply_whatsapp_message_status(phone_number_id, wamid, status, occurred_at, error_code)`: só casa o wamid se a conexão da dona da mensagem usa o `phone_number_id` do webhook; `sent < delivered < read` monotônico (duplicado/atrasado = `unchanged`); `failed` só a partir de sent/delivered (nunca depois de read), grava `error = {code: delivery_failed, provider_code}` e **não volta para a fila** (o claim só pega `scheduled`); delivered/read posteriores vencem um failed de entrega; `failed/send_outcome_unknown` nunca é tocado. Resultado: `updated | unchanged | not_found | invalid`.
  - `apply_whatsapp_template_status(waba, nome, idioma, evento, at)`: registra em `whatsapp_connections.setup_state.templates["nome:idioma"]` (ignora evento mais antigo que o registrado). REJECTED/DISABLED/DELETED/PENDING_DELETION/ARCHIVED/LOCKED → `connected` vira `pending` com `templates_rejected`; PAUSED/PENDING/IN_APPEAL/LIMIT_EXCEEDED → `pending` com `templates_pending`; APPROVED/REINSTATED/UNARCHIVED/FLAGGED só registram — **nunca promovem** (volta a `connected` só pela reavaliação completa do `whatsapp-connect status`, que consulta a Meta).
- `whatsapp-webhook`: statuses[] e `message_template_status_update` processados depois da assinatura HMAC; só os templates da prontidão (`WHATSAPP_TEMPLATE_APPOINTMENT_CONFIRMATION`/`_12H`, idioma `WHATSAPP_TEMPLATE_LANGUAGE`); falha de persistência → 500 (Meta reenvia; tudo idempotente). Logs só com contagens/tipos (sem wamid, telefone, número ou texto da Meta). Status que chega antes de o despacho gravar o wamid vira `not_found` (o `sent` já é gravado pelo despacho; delivered/read seguintes casam).
- **Na Meta (painel do app → Webhooks → WhatsApp Business Account):** o campo `message_template_status_update` precisa estar assinado para os eventos de template chegarem (`messages` e `account_update` já estavam).
- **Cron:** rodou `*/5` de ~00:30 a ~04:20 UTC de 12/10 e voltou a `*/30` (padrão idêntico a `rollout-0028/04_cron_back_to_30min.sql`; sem log de quem executou). Sem motivo técnico para 30 min (gate 0028 aplicado), restaurado para `*/5` com `cron.alter_job` no MESMO job (`la_pelve_whatsapp_dispatcher_30min` — o nome ficou histórico; nada recriado, mesmo token no Vault).
- `whatsapp-connect`: com a chave desligada, o log `whatsapp_connect_not_configured` lista os NOMES das variáveis que faltam (nunca valores), para conferir os secrets antes de ligar.

## >>> ATUALIZAÇÃO 2026-10-12 (PR #8, guard de registro do número)

- `0031_security_definer_function_grants.sql` já estava na `main` e aplicada; o guard virou **`0032_whatsapp_phone_registration_guard.sql`**.
- Guard por `phone_number_id` (tabela `whatsapp_phone_registration_guard`, RLS sem policy, só `service_role` via RPC):
  - `reserve_whatsapp_phone_registration(fisio, phone, existing_pin_only)`: advisory lock por número + `FOR UPDATE`; só conexão `pending`/`error` da própria profissional; limite 8/72 h, intervalo mínimo de 10 min, bloqueio vigente; a tentativa é gravada **antes** da chamada a `/register` (commit da RPC). Devolve `reserved` + PIN, `limited`, `cooldown`, `pin_unknown` ou `error`.
  - PIN de 2FA: 6 dígitos gerados uma vez por número (pgcrypto), só no Vault (`la_pelve_wa_pin_<phone_number_id>`). Reconexão de número que nós registramos usa o mesmo PIN; número com 2FA de terceiros → `phone_pin_required`, nada é enviado.
  - `mark_whatsapp_phone_registration_limited`: resposta 133016 da Meta → bloqueio de 72 h (nunca encurta). Desconectar/reconectar não zera nada.
- Edge Function: timeout/rede no `/register` = resultado desconhecido → `phone_registration_retry_later` (tentativa já contada); 133005 (PIN incorreto) → `phone_pin_required`. `setup_state.register_attempts`/`rate_limited_until` ficaram legados (não são mais lidos nem escritos).
- CI: job novo "SQL migrations and tests" (Postgres 16 + `supabase_vault` v0.3.1 compilado) aplica TODAS as migrations num banco descartável e roda `supabase/tests/*.test.sql`.

## >>> ATUALIZAÇÃO 2026-10-11 (branch `feature/whatsapp-e2e-20261011`)

**Validado em produção:** E2E real do `appointment_12h` (Meta aceitou, a paciente de teste tocou em
Confirmar, o webhook mudou a consulta para `confirmed`). Conexão em uso: a de teste da Lucksrei.
`appointments` está na publicação `supabase_realtime` (RLS por `fisioterapeuta_id`).

**Neste PR (nada disso foi aplicado/deployado em produção):**

| Item | Estado |
|---|---|
| Realtime Agenda/Home (`AgendaCubit.startRealtime`) | corrigido (mocks) e testado; edição de consulta não regrava `status` |
| `0028_whatsapp_informative_gate.sql` | **não aplicada**. Dry-run revertido em produção: antes 5 avisos legados seriam reservados, depois da trava 0 |
| cron 5 min | script pronto (`rollout-0028/03_cron_5min.sql`), **não aplicado** (hoje `*/30`) |
| `0028` e `0029` | **aplicadas em produção em 11/10/2026** (pela proprietária). A Edge Function `whatsapp-connect` NÃO foi deployada e o onboarding segue desligado |
| `0030_whatsapp_connect_hardening.sql` | **não aplicada** (correções da revisão do PR #6). Validada em transação revertida em produção |
| `web/whatsapp-connect.html` (página de onboarding) | vai junto com o deploy web (Cloudflare) |
| Tela Perfil → WhatsApp | conectar / atualizar / desconectar; sem backend liberado continua "Integração em preparação" |

**Bloqueios externos (Meta), dependem da conta da Lucksrei:** ver a seção "Embedded Signup" abaixo.

### Embedded Signup — como funciona e o que falta ligar

1. App chama `whatsapp-connect` `start` (JWT) -> state aleatório de 256 bits (só o hash no banco, TTL 15 min, uso único) -> URL HTTPS da página.
2. A página (`web/whatsapp-connect.html`) pega `app_id`/`config_id` via `config` (valida o state sem consumi-lo), abre `FB.login` (Embedded Signup v4) e recebe `code` + `WA_EMBEDDED_SIGNUP` (`waba_id`, `phone_number_id`).
3. `complete` consome o state, troca o code **no servidor** (30 s de validade), confere que o número pertence à WABA, inscreve o app no webhook da WABA, registra o número (exceto coexistência), garante os templates e grava o token no Vault via `set_whatsapp_connection_access_token`. Só vira `connected` com os dois templates APROVADOS; antes disso fica `pending`.
4. Sem `WHATSAPP_SELF_CONNECT_ENABLED=true` + `META_APP_ID`, `META_ES_CONFIG_ID`, `WHATSAPP_CONNECT_PAGE_URL` (+ App Secret e versão da Graph já existentes), `availability` devolve `enabled:false` e o app não mostra o botão.

Pré-requisitos na Meta (não verificáveis daqui): Tech Provider aprovado, App Review com `whatsapp_business_management` e `whatsapp_business_messaging` (acesso avançado), configuração Embedded Signup v4 (Facebook Login for Business), domínio da página em *Allowed domains* e *Valid OAuth redirect URIs*, webhook `account_update` assinado. Embedded Signup v2 deixa de existir em 15/10/2026 (usar v4).

### Correções da revisão (PR #6)

- Token: a linha é reservada como `pending`, o token vai ao Vault **antes** de qualquer efeito na Meta e `connected` só é gravado se a credencial existir (o banco recusa com `WA009`). Falha de gravação deixa `pending/credential_store_failed`, sem tocar na WABA.
- Registro do número: nunca inventa PIN. Número já `CONNECTED` não é registrado; com PIN existente fica `phone_pin_required`; coexistência nunca registra; tentativas ficam em `setup_state` (limite próprio de 8 por 72 h, e bloqueio de 72 h ao receber `133016`). `status` reavalia tudo e só promove com registro válido.
- WABA compartilhada: a inscrição do webhook só é removida quando nenhuma outra profissional usa a mesma WABA (na dúvida, mantém).
- Conflitos locais (número de outra profissional, conexão ativa) são checados **antes** de inscrever/registrar/criar templates; leituras na Meta (troca do code, posse do número) vêm antes da reserva.
- Troca do code: `GET /oauth/access_token` (contrato da documentação). Listagens de números e templates seguem `paging.next` (só `graph.facebook.com`, limite de páginas; resultado incompleto nunca vira "não pertence").
- `account_update`: o `whatsapp-webhook` (com HMAC) aplica `PARTNER_REMOVED`, `PARTNER_APP_UNINSTALLED`, `ACCOUNT_DELETED`, `ACCOUNT_OFFBOARDED` (revoga: apaga token e desconecta), `DISABLED_UPDATE`/violação/restrição (`error`, envio para) e reabilitação (`pending`, reavaliação completa). Idempotente. Falta o deploy do webhook novo e assinar `account_update` na Meta.
- Prontidão: só `connected` com webhook inscrito, número `CONNECTED`, os dois templates aprovados e `health_status` não limitado/bloqueado. A cobrança não é consultável por API: a tela de conectada pede para confirmar a forma de pagamento no WhatsApp Manager.
- Template de aviso: o texto tem **duas** quebras de linha depois do emoji (conforme a revisão; não consegui conferir direto na Meta). Só afeta templates criados em novas WABAs.
- Correção de relato: o dry-run da 0028 mede o **claim**; para consultas já ocorridas o `prepare` cancelaria com `appointment_already_occurred`. A trava continua útil contra avisos antigos de consultas futuras.

Limitações conhecidas: retorno ao app é por "voltar e atualizar" (o app relê ao voltar do background); universal link/deep link fica para uma etapa nativa. O PIN de duas etapas gerado no registro do número não é guardado (recuperável pelo Business Manager). A desconexão remove token e inscrição do webhook, mas não revoga a autorização na Meta.

---

Última atualização: 2026-10-08. Projeto Supabase: `lchaboncmgcimafpupad` (fisioterapia_pelvica).
Nenhum segredo está neste arquivo; só os NOMES dos secrets.

## >>> RETOMAR DAQUI (estado em 2026-10-08, ~05:20 UTC)

Branch `wip/sleepy-keller-gplahy` (não mergeada em `main`). Commits relevantes:
`f04eefd` (telefone no cadastro), `bc34ba5` (inbound: confirmação pela resposta),
`d4f7cc5` (outbound: dispatcher + Vault). Todo o código está no remoto.
Continuação (a partir de `dcd426c`): branch `wip/intelligent-thompson-68i38m`.

**Estado REAL de produção (verificado pelo conector Supabase):**

| Item | Estado |
|---|---|
| Migration 0025 (`whatsapp_inbound_messages` + `process_whatsapp_confirmation_reply`) | **APLICADA** — pre-flight 6/6 PASS, pós-check 9/9 PASS, md5 do corpo da função idêntico ao testado localmente (`d80443d971500d7b9674d3a25e778735`), 70 appointments intactos |
| Migration 0026 (dispatch + credenciais no Vault) | **APLICADA** (2026-10-08 ~03:35 UTC, pelo SQL Editor) — pre-flight 10/10 PASS; pós-check 19/19 PASS (RLS, grants só `service_role`, 5 colunas, 2 triggers, 2 constraints, índice, FK cascade, 0 credenciais, 0 segredos no Vault, contagens 4/18/70 intactas, md5 da função da 0025 inalterado). Corpo das 6 funções idêntico ao do repositório (md5 normalizado, sem comentários/espaços). |
| Edge Function `whatsapp-webhook` | **NOVA VERSÃO EM PRODUÇÃO E VALIDADA — inbound FECHADO.** Deploy 2026-10-08 ~03:44 UTC como v11 (8 arquivos: `whatsapp-webhook/{index,handler}.ts` + `_shared/inbound/*.ts` sem testes; `verify_jwt=false`; bundle `ezbr_sha256` `13cd63e7…`). A plataforma passou a numerar v13 depois de uma atualização de secrets, com o MESMO bundle (mesmo sha). Smoke tests (04:02 UTC): GET válido 200 + challenge; GET token errado 403; POST sem assinatura 401; POST com assinatura inválida 401. Logs: só `webhook_verified`, `webhook_verify_rejected`, `invalid_signature`; nenhum 500, nenhum erro/exceção. Dados: 0 linhas em todas as tabelas WhatsApp, 70 appointments, 0 segredos no Vault. |
| Edge Function `whatsapp-dispatcher` | **PUBLICADA EM MODO INERTE e validada** (v1, ACTIVE, `verify_jwt=false`, também em `supabase/config.toml`). Sem `WHATSAPP_DISPATCHER_TOKEN` toda chamada recebe 401 antes de ler qualquer dado. Smoke tests (05:12 UTC): 3 POSTs (sem Authorization, Bearer falso, Bearer vazio) = 401 `whatsapp_dispatcher_unauthorized`; GET = 405. Nenhum 500, nenhuma exceção, nenhuma escrita no banco. Nenhum secret do dispatcher configurado. |
| `whatsapp-scheduler-dry-run` | sem mudança de código (a numeração foi para v9 pela mesma atualização de secrets) |
| pg_cron / pg_net | não instalados (cron não agendado) |
| Dados | 0 whatsapp_messages, 0 whatsapp_connections, 0 patient_consents, 0 segredos no Vault |
| Histórico de migrations do Supabase | vazio (o projeto aplica arquivos via `db query`, sem histórico; manter assim) |

**Próximos passos, nesta ordem:**

1. ~~Aplicar a 0026~~ FEITO. Observação: o conector MCP do Supabase pede confirmação para qualquer `DROP` (até `drop ... if exists` que não faz nada) e, sem essa confirmação, a chamada estoura os 60s antes de chegar ao Postgres. Não é tempo de execução nem lock. Migrations com `DROP` vão pelo SQL Editor.
2. ~~Deployar a nova `whatsapp-webhook`~~ FEITO e validado (ver tabela). A Meta também executou "Verificar e salvar" com sucesso. O `hub.verify_token` aparece nos logs de borda do Supabase porque a Meta o envia na query string da verificação; isso é esperado. Rotacionar `WHATSAPP_VERIFY_TOKEN` só se houver exposição externa ou necessidade operacional.
3. ~~Deployar `whatsapp-dispatcher` inerte~~ FEITO e validado (ver tabela). Próximo: primeiro E2E real só com `appointment_12h` (template criado na Meta: Utility, pt_BR, 3 variáveis posicionais, 1 botão de resposta rápida "Confirmar"; aguardando aprovação). Secrets do E2E: `WHATSAPP_GRAPH_API_VERSION=v25.0`, `WHATSAPP_TEMPLATE_LANGUAGE=pt_BR`, `WHATSAPP_TEMPLATE_APPOINTMENT_12H=appointment_12h`, `WHATSAPP_DISPATCHER_TOKEN`. NÃO configurar `..._CONFIRMATION` nem `..._RESCHEDULED` por enquanto.
4. Só depois de templates aprovados na Meta + uma conexão `connected` com token (`set_whatsapp_connection_access_token`): `supabase/rollout-0026/05_schedule_cron.sql`.

Rollbacks: `supabase/rollout-0025/02_rollback.sql`, `supabase/rollout-0026/02_rollback.sql`, `06_unschedule_cron.sql`.

Testes locais (precisam de Postgres 16 com `supabase_vault` compilada, PostgREST e Deno; ver cabeçalhos dos scripts): `node --test --experimental-strip-types $(find supabase/functions -name "*.test.ts")` (340), `supabase/tests/run_sql_tests.sh` (121), `supabase/tests/e2e/run_e2e.sh` (8 etapas).

## O que já está em produção

**Banco (migrations aplicadas e verificadas com pós-check PASS)**

- `0018_whatsapp_integration_foundation.sql`
  - `profiles.timezone` (default `America/Sao_Paulo`, check de fuso válido)
  - `patients.phone_e164` (nulo; check `^\+[1-9][0-9]{7,14}$`). `patients.phone` não muda.
  - `patient_consents`: histórico append-only de consentimento (único UPDATE permitido: `revoked_at` de nulo para valor; no máximo um consentimento ativo por paciente/canal/finalidade).
  - `whatsapp_connections`: uma linha por profissional (waba_id, phone_number_id, número exibido, status, datas). Sem token/segredo. Escrita só pelo backend (service role); o app só lê a própria.
  - `whatsapp_messages`: só metadados de envio (sem corpo). `UNIQUE (appointment_id, reminder_type)` impede envio duplicado. Escrita só pelo backend.
  - FKs compostas `(patient_id, fisioterapeuta_id)` e `(appointment_id, fisioterapeuta_id)` impedem associar dado de outro profissional.
- `0019_patient_consents_contact_value.sql`
  - `patient_consents.contact_value text NOT NULL`: telefone E.164 autorizado naquele momento (imutável; check E.164 para `channel = 'whatsapp'`).
  - **Todo INSERT em `patient_consents` precisa enviar `contact_value`.**

As 3 tabelas novas estão vazias. Os dados antigos (profiles, patients, appointments, attachments, evolution_entries, financial_entries) foram comparados antes/depois por hash e não mudaram.

**Edge Function `whatsapp-webhook`** (`supabase/functions/whatsapp-webhook/index.ts`)

- URL: `https://lchaboncmgcimafpupad.supabase.co/functions/v1/whatsapp-webhook` (sem verificação de JWT: `supabase/config.toml`).
- GET: valida `hub.verify_token` e devolve `hub.challenge`. POST: só registra nos logs (mensagens, statuses, wamid, recipient_id, erros completos); não grava no banco.
- Secrets no Supabase: `WHATSAPP_VERIFY_TOKEN` (já rotacionado uma vez) e `WHATSAPP_APP_SECRET` (App Secret do app Meta novo da Lucksrei; com ele a função rejeita POST sem assinatura `X-Hub-Signature-256` válida: 401).
- É um webhook TEMPORÁRIO de diagnóstico. Os valores dos secrets passaram por conversas; trocar quando o diagnóstico acabar.
- A verificação do webhook na Meta e o teste de entrega de `messages` NÃO foram confirmados por quem escreveu este documento.

**Site (repo `lucksrei`, já publicado)**

- Política de privacidade com a seção do WhatsApp: `https://lucksrei.com/projects/la-pelve/privacy/`
- Exclusão de dados: `https://lucksrei.com/projects/la-pelve/data-deletion/`
- A política já promete opt-in por paciente e lembrete neutro. O app ainda não faz isso (ver abaixo).

## Regras de produto (ainda NÃO implementadas)

- Lembrete 12h antes da consulta (`reminder_type = 'appointment_12h'`), no fuso do profissional.
- Consulta criada com menos de 12h de antecedência: sem lembrete.
- Silêncio 22:00–06:59 no fuso do profissional; se `scheduled_for` cair aí, move para 07:00.
- Não envia: consulta cancelada; `appointments.patient_id` nulo; sem consentimento ativo; sem `phone_e164` válido.
- Horário alterado antes do envio: recalcula `scheduled_for`. Remarcação depois do envio: etapa posterior.
- O scheduler deve reler o paciente a partir da consulta no momento do envio e conferir que `contact_value` do consentimento ativo == `patients.phone_e164`. O banco não garante isso. Cancelar mensagens não enviadas se o paciente da consulta mudar.

## Próxima etapa: UX de consentimento no Flutter (nada feito ainda)

Auditoria do fluxo atual (resumo):

- Criar e editar paciente usam o mesmo formulário: `PatientFormPage` (wizard de 11 passos, `PatientFormCubit`). O telefone fica no 1º passo, `PersonalInfoStep`.
- `patients.phone` é gravado já mascarado, ex. `(62) 99999-9999`. Validação (`isValidPhone`): só 10 ou 11 dígitos; não valida DDD nem o 9 do celular. Sem DDI.
- O `toJson` do `Patient` tem lista fixa de colunas e NÃO inclui `phone_e164`: editar paciente hoje não toca nas colunas novas.
- Estado real em produção: 18 registros = 16 ativos + 2 apagados (soft delete). Só 14 de 18 normalizariam como celular válido; 3 têm 11 dígitos sem o 9 após o DDD e 1 tem 10 dígitos (fixo). Esses 4 ficam sem lembrete até serem corrigidos.

Proposta (aguardando decisão do usuário):

1. Switch "Receber lembretes de agendamento pelo WhatsApp" logo abaixo do telefone, no `PersonalInfoStep`, desligado por padrão, com o texto "Confirmo que o paciente autorizou receber lembretes por WhatsApp. O lembrete não inclui informações de saúde."
2. Desabilitado se o telefone não for celular válido (11 dígitos, 9 após o DDD).
3. Consentimento fora de `Patient`/`toJson`: repositório novo sobre `patient_consents` (ler ativo, conceder, revogar). Ausência de linha = desativado. Pacientes existentes continuam desativados; nenhum backfill de consentimento.
4. Ao salvar: primeiro o paciente, depois o consentimento (a FK composta exige o paciente existente). Desligado→ligado: INSERT com `contact_value` = E.164 atual e `source`. Ligado→desligado: `revoked_at`. Se o paciente salvar e o consentimento falhar, avisar o profissional.
5. `phone_e164`: função única `normalizeBrPhoneToE164` (remove máscara, valida DDD e o 9, devolve `+55DDNNNNNNNNN` ou nulo). Gravada no `toJson` só quando o profissional salva o paciente. Sem backfill em massa.
6. Trocar o telefone de um paciente com consentimento ativo: o consentimento era do número antigo.

Decisões pendentes do usuário:

- O switch fica no passo "Dados pessoais" (proposto) ou numa ação separada no detalhe do paciente?
- Telefone fixo (10 dígitos) bloqueado para WhatsApp (proposto)?
- Ao trocar o número: revogar o consentimento automaticamente ou só avisar?
- Backfill opcional de `phone_e164` só dos 14 válidos, ou preencher aos poucos?

## Confirmação da consulta pela resposta da paciente (migration 0025 APLICADA; webhook novo NÃO deployado)

- Solicitação de confirmação = lembrete `appointment_12h` já enviado (`whatsapp_messages` com `status` sent/delivered/read, `wamid` e `sent_at` preenchidos pelo dispatch).
- Migration `0025_whatsapp_confirmation_reply.sql` (rollout em `supabase/rollout-0025/`): tabela `whatsapp_inbound_messages` (dedup por `wamid` da Meta, sem texto nem telefone, só backend), colunas `confirmation_reply_id`/`confirmation_consumed_at` em `whatsapp_messages` e a RPC `process_whatsapp_confirmation_reply` (só `service_role`), que correlaciona, trava e muda `scheduled -> confirmed` numa transação.
- `whatsapp-webhook`: mesma validação GET e de assinatura; POST agora EXIGE `WHATSAPP_APP_SECRET`. Só respostas inequívocas ("sim", "sim, confirmo", "confirmo", "confirmado", "pode confirmar" ou o botão com payload `LA_PELVE_CONFIRM_APPOINTMENT`) chamam a RPC. Logs só com contagens.
- O dispatch (seção seguinte) grava `wamid`/`sent_at`/`status` da `appointment_12h` e manda o template com o botão de resposta rápida com aquele payload.
- Testes: `node --test --experimental-strip-types $(find supabase/functions -name "*.test.ts")` e, com um Postgres local, `supabase/tests/run_sql_tests.sh` e o E2E `whatsapp-webhook/integration.test.ts` (`LA_PELVE_TEST_PGHOST`).

## Envio real (outbound) — código pronto; migration 0026 APLICADA; deploy PENDENTE

- Decisão confirmada: o lembrete `appointment_12h` É a solicitação de confirmação (template com botão de resposta rápida, payload `LA_PELVE_CONFIRM_APPOINTMENT`). O aviso de agendamento (`appointment_confirmation`) e o de remarcação são só informativos.
- Credenciais: access token da Meta por conexão no **Supabase Vault** (`whatsapp_connection_credentials.vault_secret_id`), nunca em coluna comum nem no app. Gravado só por `set_whatsapp_connection_access_token` (só escrita) e lido só dentro de `prepare_whatsapp_message_send` para a mensagem reservada. Apagar a conexão apaga o segredo.
- Migration `0026_whatsapp_dispatch.sql` (rollout em `supabase/rollout-0026/`; aborta sem `supabase_vault`): lease/tentativas em `whatsapp_messages` + RPCs `claim_…` (SKIP LOCKED), `prepare_…` (revalida consentimento, telefone, revisão, status, conexão e credencial) e `complete_…`.
- Edge Function `whatsapp-dispatcher` (pipeline: materialização → reconciliação → envio). Autenticação própria (`WHATSAPP_DISPATCHER_TOKEN`). Secrets: `WHATSAPP_GRAPH_API_VERSION` (obrigatório, sem default), `WHATSAPP_TEMPLATE_LANGUAGE`, `WHATSAPP_TEMPLATE_APPOINTMENT_{CONFIRMATION,12H,RESCHEDULED}` (tipo sem template não sai).
- Cron: `supabase/rollout-0026/05_schedule_cron.sql` (pg_cron + pg_net, a cada 5 min, URL/token no Vault). Não é migration; só depois de deploy e templates aprovados.
- Retry: 429/limite e 5xx tentam de novo (1, 5, 15, 60 min; até 5 envios). 4xx/token inválido falham. Timeout/rede/resposta 2xx inválida: `failed` `send_outcome_unknown`, nunca reenviado.
- Testes: `supabase/tests/run_sql_tests.sh` (precisa de `supabase_vault` compilada localmente) e `supabase/tests/e2e/run_e2e.sh` (supabase-js → PostgREST → Postgres + Vault, provider falso).
- Falta: Embedded Signup (provisionar conexão + token), templates aprovados na Meta em cada WABA, status de entrega (delivered/read/failed) vindos do webhook.

## Depois disso

- **Backlog antes do rollout geral (não implementado):** tipos de mensagem sem template configurado (hoje `appointment_confirmation` e `appointment_rescheduled`) continuam sendo materializados e ficam `scheduled`, porque o claim só reserva os tipos com template. Se um template desses tipos for configurado mais tarde, mensagens antigas que ainda forem elegíveis (consulta futura, mesma revisão, consentimento ativo) podem sair atrasadas. Antes do rollout geral, garantir que esse backlog antigo não seja enviado sem querer (por exemplo, cancelar ou não materializar tipos sem template, ou limitar o atraso máximo no envio).
- Depois do primeiro E2E: resposta automática "Agendamento confirmado com sucesso! ✅ Esperamos você no dia DD/MM, às HH:MM." quando a consulta for confirmada pelo WhatsApp. Não faz parte do `appointment_12h`.

- Cron do dispatcher: script pronto (`rollout-0026/05_schedule_cron.sql`), não aplicado. `pg_cron`/`pg_net` não estão ativos.
- Conexão do WhatsApp de cada profissional (Embedded Signup): exige que a Lucksrei seja Tech Provider na Meta. Credenciais da Meta NÃO ficam nas tabelas deste schema; como serão entregues ainda é decisão em aberto.
- A exclusão de conta (`delete_own_account`) cascateia as tabelas novas; com a 0026, apagar a conexão apaga o token no Vault (trigger). Não desconecta o número na Meta.

## Como trabalhamos aqui (para quem retomar)

- SQL em produção: `npx.cmd supabase db query -f <arquivo> --linked --project-ref lchaboncmgcimafpupad`. Nunca `db push`. Sempre pre-flight read-only, aplicar só a migration, pós-check, e só então commit.
- Scripts em `supabase/rollout-00XX/` (pre-flight, rollback, pós-check). O `03_postcheck.sql` da 0018 é gerado com snapshot de produção e fica fora do Git (`.gitignore`); regenere com `node supabase/rollout-0018/make_postcheck.mjs` imediatamente antes de aplicar.
- O Git neste PC não tem identidade configurada: commitar com `git -c user.name="Lucas Diogo" -c user.email="lucasdiogo1234@gmail.com" commit ...`.
- `core.autocrlf=true`: arquivos viram CRLF no checkout. Ao comparar texto de função/SQL com produção, normalize CRLF para LF.
- Antes de qualquer commit: busca por secrets (nada de tokens, App Secret, service_role no repo).
