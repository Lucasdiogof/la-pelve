# Integração WhatsApp (lembretes de agendamento) — estado e próximos passos

Última atualização: 2026-10-08. Projeto Supabase: `lchaboncmgcimafpupad` (fisioterapia_pelvica).
Nenhum segredo está neste arquivo; só os NOMES dos secrets.

## >>> RETOMAR DAQUI (estado em 2026-10-08, ~04:10 UTC)

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
| Edge Function `whatsapp-dispatcher` | NÃO deployada |
| `whatsapp-scheduler-dry-run` | sem mudança de código (a numeração foi para v9 pela mesma atualização de secrets) |
| pg_cron / pg_net | não instalados (cron não agendado) |
| Dados | 0 whatsapp_messages, 0 whatsapp_connections, 0 patient_consents, 0 segredos no Vault |
| Histórico de migrations do Supabase | vazio (o projeto aplica arquivos via `db query`, sem histórico; manter assim) |

**Próximos passos, nesta ordem:**

1. ~~Aplicar a 0026~~ FEITO. Observação: o conector MCP do Supabase pede confirmação para qualquer `DROP` (até `drop ... if exists` que não faz nada) e, sem essa confirmação, a chamada estoura os 60s antes de chegar ao Postgres. Não é tempo de execução nem lock. Migrations com `DROP` vão pelo SQL Editor.
2. ~~Deployar a nova `whatsapp-webhook`~~ FEITO e validado (ver tabela). Atenção: a verificação GET da Meta manda `hub.verify_token` na URL, e os logs de borda do Supabase gravam a URL inteira. O valor atual de `WHATSAPP_VERIFY_TOKEN` está nesses logs e já foi compartilhado fora do cofre de segredos: rotacionar antes (ou logo depois) de configurar o webhook no app Meta.
3. Deployar `whatsapp-dispatcher` (`verify_jwt=false`, autenticação própria). Fica inerte (401) até configurar os secrets `WHATSAPP_DISPATCHER_TOKEN` (>= 32 chars), `WHATSAPP_GRAPH_API_VERSION` (ex.: `v23.0`), `WHATSAPP_TEMPLATE_LANGUAGE` (`pt_BR`) e os `WHATSAPP_TEMPLATE_APPOINTMENT_*`.
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

- Cron do dispatcher: script pronto (`rollout-0026/05_schedule_cron.sql`), não aplicado. `pg_cron`/`pg_net` não estão ativos.
- Conexão do WhatsApp de cada profissional (Embedded Signup): exige que a Lucksrei seja Tech Provider na Meta. Credenciais da Meta NÃO ficam nas tabelas deste schema; como serão entregues ainda é decisão em aberto.
- A exclusão de conta (`delete_own_account`) cascateia as tabelas novas; com a 0026, apagar a conexão apaga o token no Vault (trigger). Não desconecta o número na Meta.

## Como trabalhamos aqui (para quem retomar)

- SQL em produção: `npx.cmd supabase db query -f <arquivo> --linked --project-ref lchaboncmgcimafpupad`. Nunca `db push`. Sempre pre-flight read-only, aplicar só a migration, pós-check, e só então commit.
- Scripts em `supabase/rollout-00XX/` (pre-flight, rollback, pós-check). O `03_postcheck.sql` da 0018 é gerado com snapshot de produção e fica fora do Git (`.gitignore`); regenere com `node supabase/rollout-0018/make_postcheck.mjs` imediatamente antes de aplicar.
- O Git neste PC não tem identidade configurada: commitar com `git -c user.name="Lucas Diogo" -c user.email="lucasdiogo1234@gmail.com" commit ...`.
- `core.autocrlf=true`: arquivos viram CRLF no checkout. Ao comparar texto de função/SQL com produção, normalize CRLF para LF.
- Antes de qualquer commit: busca por secrets (nada de tokens, App Secret, service_role no repo).
