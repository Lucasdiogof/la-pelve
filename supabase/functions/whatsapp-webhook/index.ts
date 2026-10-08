// Webhook da WhatsApp Cloud API.
//   GET:  verificação do webhook (WHATSAPP_VERIFY_TOKEN).
//   POST: exige assinatura X-Hub-Signature-256 válida (WHATSAPP_APP_SECRET).
//         Respostas de confirmação inequívocas da paciente à solicitação de
//         confirmação (lembrete appointment_12h) confirmam a consulta via
//         public.process_whatsapp_confirmation_reply (migration 0025).
//         Statuses (sent/delivered/read/failed) e demais mensagens são
//         ignorados.
// A lógica fica em handler.ts (testável em Node); aqui só se lê o ambiente.
//
// NÃO DEPLOYADA nesta versão.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { createSupabaseConfirmationReplyPort } from "../_shared/inbound/supabase_confirmation_port.ts";
import type { ConfirmationReplyPort } from "../_shared/inbound/types.ts";
import { createWebhookHandler } from "./handler.ts";

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

Deno.serve(
  createWebhookHandler({
    verifyToken: Deno.env.get("WHATSAPP_VERIFY_TOKEN"),
    appSecret: Deno.env.get("WHATSAPP_APP_SECRET"),
    getPort,
  }),
);
