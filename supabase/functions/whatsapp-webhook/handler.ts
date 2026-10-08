// Lógica HTTP do whatsapp-webhook -- PURA (sem Deno.*), para ser testável
// em Node. index.ts lê os secrets e o client e só repassa.
//
// GET: verificação do webhook pela Meta (hub.verify_token -> hub.challenge).
// POST: só com X-Hub-Signature-256 válido (HMAC-SHA256 do corpo com o App
// Secret). Como o POST agora pode alterar dados, o App Secret é OBRIGATÓRIO:
// sem ele o POST é recusado (antes, sem o secret, qualquer POST era aceito).
//
// Logs: só eventos e contagens. Nunca token, secret, telefone, texto da
// mensagem ou payload bruto.

import { processInboundWebhook } from "../_shared/inbound/process.ts";
import type { ConfirmationReplyPort, InboundSummary } from "../_shared/inbound/types.ts";

export interface WebhookConfig {
  verifyToken: string | undefined;
  appSecret: string | undefined;
  /** Criada só depois da assinatura validada (ver index.ts). */
  getPort: () => ConfirmationReplyPort;
  log?: (event: string, data: Record<string, unknown>) => void;
}

const encoder = new TextEncoder();

export function safeEqual(a: string, b: string): boolean {
  const ab = encoder.encode(a);
  const bb = encoder.encode(b);
  let diff = ab.length ^ bb.length;
  for (let i = 0; i < Math.max(ab.length, bb.length); i++) {
    diff |= (ab[i] ?? 0) ^ (bb[i] ?? 0);
  }
  return diff === 0;
}

export async function hmacSha256Hex(secret: string, raw: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign("HMAC", key, encoder.encode(raw));
  return Array.from(new Uint8Array(mac))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export async function validSignature(secret: string, raw: string, header: string | null): Promise<boolean> {
  if (!header?.startsWith("sha256=")) return false;
  return safeEqual(await hmacSha256Hex(secret, raw), header.slice("sha256=".length));
}

function defaultLog(event: string, data: Record<string, unknown>) {
  console.log(JSON.stringify({ event, ...data }));
}

export function createWebhookHandler(config: WebhookConfig): (req: Request) => Promise<Response> {
  const log = config.log ?? defaultLog;

  return async (req: Request): Promise<Response> => {
    if (!config.verifyToken) {
      log("config_error", { error: "WHATSAPP_VERIFY_TOKEN não definido" });
      return new Response("Server misconfigured", { status: 500 });
    }

    if (req.method === "GET") {
      const url = new URL(req.url);
      const mode = url.searchParams.get("hub.mode");
      const token = url.searchParams.get("hub.verify_token") ?? "";
      const challenge = url.searchParams.get("hub.challenge");

      if (mode === "subscribe" && challenge !== null && safeEqual(token, config.verifyToken)) {
        log("webhook_verified", {});
        return new Response(challenge, {
          status: 200,
          headers: { "Content-Type": "text/plain" },
        });
      }
      log("webhook_verify_rejected", { mode });
      return new Response("Forbidden", { status: 403 });
    }

    if (req.method === "POST") {
      if (!config.appSecret) {
        log("config_error", { error: "WHATSAPP_APP_SECRET não definido" });
        return new Response("Server misconfigured", { status: 500 });
      }
      const raw = await req.text();
      if (!(await validSignature(config.appSecret, raw, req.headers.get("x-hub-signature-256")))) {
        log("invalid_signature", {});
        return new Response("Invalid signature", { status: 401 });
      }

      let body: unknown;
      try {
        body = JSON.parse(raw);
      } catch {
        // Assinado mas não é JSON: reenviar não muda nada; 200 para a Meta
        // não insistir. Sem logar o corpo.
        log("payload_parse_error", { bytes: raw.length });
        return new Response("EVENT_RECEIVED", { status: 200 });
      }

      let summary: InboundSummary;
      try {
        summary = await processInboundWebhook(body, config.getPort());
      } catch {
        log("webhook_processing_failed", {});
        return new Response("Processing failed", { status: 500 });
      }
      log("webhook_processed", { ...summary });

      // Falha de persistência: 500 faz a Meta reenviar. É seguro porque o
      // processamento é idempotente por wamid (reentrega vira 'duplicate').
      if (summary.errors > 0) {
        return new Response("Processing failed", { status: 500 });
      }
      return new Response("EVENT_RECEIVED", { status: 200 });
    }

    return new Response("Method not allowed", { status: 405 });
  };
}
