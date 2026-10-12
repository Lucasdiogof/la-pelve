// Webhook da WhatsApp Cloud API.
//   GET:  verificação do webhook (WHATSAPP_VERIFY_TOKEN).
//   POST: exige assinatura X-Hub-Signature-256 válida (WHATSAPP_APP_SECRET).
//         Respostas de confirmação inequívocas da paciente à solicitação de
//         confirmação (lembrete appointment_12h) confirmam a consulta via
//         public.process_whatsapp_confirmation_reply (migration 0025).
//         Statuses (sent/delivered/read/failed) atualizam whatsapp_messages
//         (apply_whatsapp_message_status, migration 0033) e
//         message_template_status_update registra o estado dos templates da
//         prontidão (apply_whatsapp_template_status). account_update: 0030.
// A lógica fica em handler.ts (testável em Node); aqui só se lê o ambiente.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { createSupabaseConfirmationReplyPort } from "../_shared/inbound/supabase_confirmation_port.ts";
import type { ConfirmationReplyPort } from "../_shared/inbound/types.ts";
import { createSupabaseAccountEventPort } from "../_shared/account/supabase_account_port.ts";
import type { AccountEventPort } from "../_shared/account/types.ts";
import { createSupabaseDeliveryStatusPort, type DeliveryStatusPort } from "../_shared/delivery/status_port.ts";
import { createSupabaseTemplateStatusPort, type TemplateStatusPort } from "../_shared/templates/template_port.ts";
import { reevaluateAfterApproval } from "../_shared/templates/reevaluate.ts";
import { createSupabaseReevaluationPort } from "../_shared/templates/reevaluation_port.ts";
import { createMetaOnboarding } from "../whatsapp-connect/meta_onboarding.ts";
import { isValidGraphApiVersion } from "../_shared/dispatch/meta_provider.ts";
import { createWebhookHandler, parseMaxBodyBytes } from "./handler.ts";

let port: ConfirmationReplyPort | null = null;

/** Client service_role só no servidor; criado sob demanda, depois da assinatura validada. */
function getPort(): ConfirmationReplyPort {
  if (port) return port;
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceRoleKey) {
    throw new Error("SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY ausentes do ambiente da function");
  }
  port = createSupabaseConfirmationReplyPort(
    createClient(url, serviceRoleKey, { auth: { persistSession: false } }),
  );
  return port;
}

let accountPort: AccountEventPort | null = null;

function getAccountPort(): AccountEventPort {
  if (accountPort) return accountPort;
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceRoleKey) {
    throw new Error("SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY ausentes do ambiente da function");
  }
  accountPort = createSupabaseAccountEventPort(
    createClient(url, serviceRoleKey, { auth: { persistSession: false } }),
  );
  return accountPort;
}

let statusPort: DeliveryStatusPort | null = null;
function getStatusPort(): DeliveryStatusPort {
  statusPort ??= createSupabaseDeliveryStatusPort(adminClient());
  return statusPort;
}

let templatePort: TemplateStatusPort | null = null;
function getTemplatePort(): TemplateStatusPort {
  templatePort ??= createSupabaseTemplateStatusPort(adminClient());
  return templatePort;
}

function adminClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceRoleKey) {
    throw new Error("SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY ausentes do ambiente da function");
  }
  return createClient(url, serviceRoleKey, { auth: { persistSession: false } });
}

// Mesmos nomes/defaults do whatsapp-connect (templates exigidos na prontidão).
const templates = {
  names: [
    Deno.env.get("WHATSAPP_TEMPLATE_APPOINTMENT_CONFIRMATION") || "appointment_confirmation",
    Deno.env.get("WHATSAPP_TEMPLATE_APPOINTMENT_12H") || "appointment_12h",
  ],
  language: Deno.env.get("WHATSAPP_TEMPLATE_LANGUAGE") || "pt_BR",
};

// Reavaliação depois de aprovação: só LEITURAS na Meta (telefone, templates,
// saúde) com o token da própria conexão. Não depende do onboarding estar
// ligado; sem versão da Graph válida, fica indisponível.
const graphApiVersion = Deno.env.get("WHATSAPP_GRAPH_API_VERSION");
async function reevaluate(wabaId: string) {
  if (!isValidGraphApiVersion(graphApiVersion)) return null;
  const meta = createMetaOnboarding({
    config: {
      appId: "",
      configId: "",
      appSecret: "",
      graphApiVersion,
      languageCode: templates.language,
      connectPageUrl: "",
      confirmationTemplate: templates.names[0],
      reminderTemplate: templates.names[1],
    },
  });
  return await reevaluateAfterApproval(wabaId, createSupabaseReevaluationPort(adminClient()), meta);
}

// deno-lint-ignore no-explicit-any
const edgeRuntime = (globalThis as any).EdgeRuntime as { waitUntil?: (p: Promise<unknown>) => void } | undefined;

Deno.serve(
  createWebhookHandler({
    verifyToken: Deno.env.get("WHATSAPP_VERIFY_TOKEN"),
    appSecret: Deno.env.get("WHATSAPP_APP_SECRET"),
    maxBodyBytes: parseMaxBodyBytes(Deno.env.get("WHATSAPP_WEBHOOK_MAX_BODY_BYTES")),
    getPort,
    getAccountPort,
    getStatusPort,
    getTemplatePort,
    templates,
    reevaluate,
    defer: edgeRuntime?.waitUntil ? (task) => edgeRuntime.waitUntil!(task) : undefined,
  }),
);
