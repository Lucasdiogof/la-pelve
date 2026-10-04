// Webhook TEMPORÁRIO da WhatsApp Cloud API, só para diagnóstico de envio.
// Não grava nada no banco: apenas escreve nos logs da função.

const VERIFY_TOKEN = Deno.env.get("WHATSAPP_VERIFY_TOKEN");
// Opcional: se definido, os POSTs precisam trazer X-Hub-Signature-256 válido.
const APP_SECRET = Deno.env.get("WHATSAPP_APP_SECRET");

const encoder = new TextEncoder();

function safeEqual(a: string, b: string): boolean {
  const ab = encoder.encode(a);
  const bb = encoder.encode(b);
  let diff = ab.length ^ bb.length;
  for (let i = 0; i < Math.max(ab.length, bb.length); i++) {
    diff |= (ab[i] ?? 0) ^ (bb[i] ?? 0);
  }
  return diff === 0;
}

async function validSignature(raw: string, header: string | null): Promise<boolean> {
  if (!APP_SECRET) return true;
  if (!header?.startsWith("sha256=")) return false;
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(APP_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign("HMAC", key, encoder.encode(raw));
  const hex = Array.from(new Uint8Array(mac))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return safeEqual(hex, header.slice("sha256=".length));
}

function log(event: string, data: unknown) {
  console.log(JSON.stringify({ event, ...(data as object) }));
}

// deno-lint-ignore no-explicit-any
function processPayload(body: any) {
  for (const entry of body?.entry ?? []) {
    for (const change of entry?.changes ?? []) {
      const value = change?.value ?? {};
      const metadata = value.metadata ?? {};

      for (const msg of value.messages ?? []) {
        log("whatsapp_message", {
          wamid: msg.id,
          from: msg.from,
          type: msg.type,
          timestamp: msg.timestamp,
          phone_number_id: metadata.phone_number_id,
          message: msg,
        });
      }

      for (const st of value.statuses ?? []) {
        const failed = st.status === "failed";
        log(failed ? "whatsapp_status_failed" : "whatsapp_status", {
          wamid: st.id,
          status: st.status,
          recipient_id: st.recipient_id,
          timestamp: st.timestamp,
          phone_number_id: metadata.phone_number_id,
          conversation: st.conversation,
          pricing: st.pricing,
          errors: st.errors,
        });
      }

      if (value.errors) {
        log("whatsapp_value_errors", {
          phone_number_id: metadata.phone_number_id,
          errors: value.errors,
        });
      }

      if (!value.messages?.length && !value.statuses?.length && !value.errors) {
        log("whatsapp_other_change", { field: change?.field, value });
      }
    }
  }
}

Deno.serve(async (req) => {
  if (!VERIFY_TOKEN) {
    log("config_error", { error: "WHATSAPP_VERIFY_TOKEN não definido" });
    return new Response("Server misconfigured", { status: 500 });
  }

  if (req.method === "GET") {
    const url = new URL(req.url);
    const mode = url.searchParams.get("hub.mode");
    const token = url.searchParams.get("hub.verify_token") ?? "";
    const challenge = url.searchParams.get("hub.challenge");

    if (mode === "subscribe" && challenge !== null && safeEqual(token, VERIFY_TOKEN)) {
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
    const raw = await req.text();

    if (!(await validSignature(raw, req.headers.get("x-hub-signature-256")))) {
      log("invalid_signature", {});
      return new Response("Invalid signature", { status: 401 });
    }

    try {
      processPayload(JSON.parse(raw));
    } catch (error) {
      log("payload_parse_error", { error: String(error), raw });
    }
    // A Meta reenvia se não receber 200 rápido.
    return new Response("EVENT_RECEIVED", { status: 200 });
  }

  return new Response("Method not allowed", { status: 405 });
});
