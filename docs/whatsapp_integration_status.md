# Integração WhatsApp (lembretes de agendamento) — estado e próximos passos

Última atualização: 2026-10-04. Projeto Supabase: `lchaboncmgcimafpupad` (fisioterapia_pelvica).
Nenhum segredo está neste arquivo; só os NOMES dos secrets.

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

## Depois disso

- Scheduler de lembretes (cron + função de envio), ainda não existe. `pg_cron`/`pg_net` não estão ativos.
- Conexão do WhatsApp de cada profissional (Embedded Signup): exige que a Lucksrei seja Tech Provider na Meta. Credenciais da Meta NÃO ficam nas tabelas deste schema; como serão entregues ainda é decisão em aberto.
- A exclusão de conta (`delete_own_account`) cascateia as tabelas novas, mas não apaga segredos do Vault nem desconecta o número na Meta.

## Como trabalhamos aqui (para quem retomar)

- SQL em produção: `npx.cmd supabase db query -f <arquivo> --linked --project-ref lchaboncmgcimafpupad`. Nunca `db push`. Sempre pre-flight read-only, aplicar só a migration, pós-check, e só então commit.
- Scripts em `supabase/rollout-0018/` e `supabase/rollout-0019/` (pre-flight, rollback, pós-check). O `03_postcheck.sql` da 0018 é gerado com snapshot de produção e fica fora do Git (`.gitignore`); regenere com `node supabase/rollout-0018/make_postcheck.mjs` imediatamente antes de aplicar.
- O Git neste PC não tem identidade configurada: commitar com `git -c user.name="Lucas Diogo" -c user.email="lucasdiogo1234@gmail.com" commit ...`.
- `core.autocrlf=true`: arquivos viram CRLF no checkout. Ao comparar texto de função/SQL com produção, normalize CRLF para LF.
- Antes de qualquer commit: busca por secrets (nada de tokens, App Secret, service_role no repo).
