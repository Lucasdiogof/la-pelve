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
import { parseAccountUpdates } from "../_shared/account/parse_account_update.ts";
import type { AccountEventPort } from "../_shared/account/types.ts";
import { parseStatuses } from "../_shared/delivery/parse_statuses.ts";
import type { DeliveryStatusPort, StatusApplyResult } from "../_shared/delivery/status_port.ts";
import { parseTemplateStatusUpdates } from "../_shared/templates/parse_template_status.ts";
import type { TemplateStatusPort } from "../_shared/templates/template_port.ts";
import type { ReevaluationSummary } from "../_shared/templates/reevaluate.ts";

/** Eventos de template que tiram (ou podem tirar) a conexão de "pronta": entram no contador de alerta. */
const NEGATIVE_TEMPLATE_EVENTS = new Set([
  "REJECTED", "DISABLED", "DELETED", "PENDING_DELETION", "ARCHIVED", "LOCKED", "PAUSED", "PENDING", "IN_APPEAL", "LIMIT_EXCEEDED",
]);

/** Eventos que PODEM ter deixado a conexão pronta (nunca conectam sozinhos). */
const POSITIVE_TEMPLATE_EVENTS = new Set(["APPROVED", "REINSTATED", "UNARCHIVED"]);

/** A Meta documenta payloads de até 3 MB; este é o teto padrão do corpo (configurável). */
export const DEFAULT_MAX_BODY_BYTES = 3 * 1024 * 1024;
const MIN_MAX_BODY_BYTES = 1024;
const HARD_MAX_BODY_BYTES = 10 * 1024 * 1024;

/**
 * Lê WHATSAPP_WEBHOOK_MAX_BODY_BYTES: inteiro entre 1 KiB e 10 MiB. Ausente ou
 * inválido volta ao padrão (nunca "sem limite").
 */
export function parseMaxBodyBytes(value: string | undefined): number {
  if (!value || !/^\d{1,9}$/.test(value)) return DEFAULT_MAX_BODY_BYTES;
  const n = Number(value);
  return n >= MIN_MAX_BODY_BYTES && n <= HARD_MAX_BODY_BYTES ? n : DEFAULT_MAX_BODY_BYTES;
}

export interface WebhookConfig {
  verifyToken: string | undefined;
  appSecret: string | undefined;
  /** Teto do corpo do POST em bytes (lido em streaming, antes da assinatura). Padrão: 3 MiB. */
  maxBodyBytes?: number;
  /** Criada só depois da assinatura validada (ver index.ts). */
  getPort: () => ConfirmationReplyPort;
  /** Eventos account_update (revogação/restrição). Criada só depois da assinatura validada. */
  getAccountPort?: () => AccountEventPort;
  /** Status de entrega (statuses[]). Criada só depois da assinatura validada. */
  getStatusPort?: () => DeliveryStatusPort;
  /** message_template_status_update. Criada só depois da assinatura validada. */
  getTemplatePort?: () => TemplateStatusPort;
  /**
   * Templates que importam para a prontidão da conexão (nome + idioma). Eventos
   * de outros templates da WABA são ignorados.
   */
  templates?: { names: string[]; language: string };
  /**
   * Reavaliação COMPLETA (leituras na Meta) das conexões da WABA pendentes por
   * template, disparada por um evento de aprovação. null = indisponível.
   */
  reevaluate?: (wabaId: string) => Promise<ReevaluationSummary | null>;
  /** Executa trabalho depois da resposta (EdgeRuntime.waitUntil); sem ele, aguarda. */
  defer?: (task: Promise<unknown>) => void;
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

export async function hmacSha256Hex(secret: string, raw: string | Uint8Array): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign("HMAC", key, typeof raw === "string" ? encoder.encode(raw) : (raw as BufferSource));
  return Array.from(new Uint8Array(mac))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export async function validSignature(secret: string, raw: string | Uint8Array, header: string | null): Promise<boolean> {
  if (!header?.startsWith("sha256=")) return false;
  return safeEqual(await hmacSha256Hex(secret, raw), header.slice("sha256=".length));
}

/**
 * Lê o corpo em streaming: guarda no máximo `maxBytes` (nunca carrega o corpo
 * inteiro para decidir). Passou do teto -> devolve null, DESCARTANDO o resto
 * pedaço a pedaço (memória constante): no runtime da Supabase a resposta só
 * sai depois que o corpo é consumido; cancelar a leitura ou parar de ler
 * deixava o 413 pendurado até o timeout (testado em produção com 3,2 MB e 18 MB).
 * Devolve os bytes ORIGINAIS (o HMAC é sobre eles) quando cabe.
 */
export async function readBodyLimited(req: Request, maxBytes: number): Promise<Uint8Array | null> {
  if (!req.body) return new Uint8Array(0);
  const declared = Number(req.headers.get("content-length"));
  let exceeded = Number.isFinite(declared) && declared > maxBytes;
  const reader = req.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.byteLength;
    if (total > maxBytes) exceeded = true;
    if (!exceeded) chunks.push(value); // excedente: só descarta
  }
  if (exceeded) return null;
  const out = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    out.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return out;
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
      const maxBytes = config.maxBodyBytes ?? DEFAULT_MAX_BODY_BYTES;
      const bytes = await readBodyLimited(req, maxBytes);
      if (bytes === null) {
        // Antes de qualquer HMAC/JSON: corpo grande demais nunca é processado.
        log("payload_too_large", { limit_bytes: maxBytes });
        return new Response("Payload too large", { status: 413, headers: { connection: "close" } });
      }
      if (!(await validSignature(config.appSecret, bytes, req.headers.get("x-hub-signature-256")))) {
        log("invalid_signature", {});
        return new Response("Invalid signature", { status: 401 });
      }
      const raw = new TextDecoder().decode(bytes);

      let body: unknown;
      try {
        body = JSON.parse(raw);
      } catch {
        // Assinado mas não é JSON: reenviar não muda nada; 200 para a Meta
        // não insistir. Sem logar o corpo.
        log("payload_parse_error", { bytes: bytes.byteLength });
        return new Response("EVENT_RECEIVED", { status: 200 });
      }

      // account_update: revogação/restrição da WABA. Falha => 500 (a Meta
      // reenvia); aplicar o mesmo evento de novo é idempotente.
      const accountEvents = config.getAccountPort ? parseAccountUpdates(body) : [];
      if (config.getAccountPort && accountEvents.length > 0) {
        try {
          const accountPort = config.getAccountPort();
          let applied = 0;
          for (const accountEvent of accountEvents) {
            const changed = await accountPort.applyAccountEvent(accountEvent);
            if (changed === null) {
              log("account_update_failed", { events: accountEvents.length });
              return new Response("Processing failed", { status: 500 });
            }
            applied += changed;
          }
          log("account_update_processed", { events: accountEvents.length, connectionsChanged: applied });
        } catch {
          log("account_update_failed", { events: accountEvents.length });
          return new Response("Processing failed", { status: 500 });
        }
      }

      // Status de entrega: idempotente e monotônico no banco; falha => 500
      // (a Meta reenvia) depois de processar o resto do payload.
      let persistenceErrors = 0;
      if (config.getStatusPort) {
        const parsedStatuses = parseStatuses(body);
        if (parsedStatuses.statuses.length > 0 || parsedStatuses.ignored > 0) {
          const counts: Partial<Record<StatusApplyResult, number>> = {};
          let failures = 0;
          try {
            const statusPort = config.getStatusPort();
            for (const status of parsedStatuses.statuses) {
              const result = await statusPort.applyStatus(status);
              if (result === null) failures++;
              else counts[result] = (counts[result] ?? 0) + 1;
            }
          } catch {
            failures = parsedStatuses.statuses.length;
          }
          persistenceErrors += failures;
          log("delivery_status_processed", {
            statuses: parsedStatuses.statuses.length,
            ignored: parsedStatuses.ignored,
            ...counts,
            errors: failures,
          });
        }
      }

      // Status de template: só os templates da prontidão; nunca promove.
      if (config.getTemplatePort && config.templates) {
        const wanted = new Set(config.templates.names);
        const language = config.templates.language;
        const all = parseTemplateStatusUpdates(body);
        const relevant = all.filter((e) => wanted.has(e.name) && e.language === language);
        if (all.length > 0) {
          let changed = 0;
          let failures = 0;
          try {
            const templatePort = config.getTemplatePort();
            for (const event of relevant) {
              const result = await templatePort.applyTemplateStatus(event);
              if (result === null) failures++;
              else changed += result;
            }
          } catch {
            failures = relevant.length;
          }
          persistenceErrors += failures;
          log("template_status_processed", {
            events: all.length,
            relevant: relevant.length,
            connectionsChanged: changed,
            errors: failures,
            negative: relevant.filter((e) => NEGATIVE_TEMPLATE_EVENTS.has(e.event)).length,
            types: [...new Set(relevant.map((e) => e.event))],
          });
          // Aprovação: só agenda a reavaliação completa (que consulta a Meta).
          const wabas = failures === 0
            ? [...new Set(relevant.filter((e) => POSITIVE_TEMPLATE_EVENTS.has(e.event)).map((e) => e.wabaId))]
            : [];
          if (config.reevaluate && wabas.length > 0) {
            const reevaluate = config.reevaluate;
            const task = (async () => {
              for (const wabaId of wabas) {
                try {
                  const result = await reevaluate(wabaId);
                  log("template_reevaluation", result ? { ...result } : { unavailable: true });
                } catch {
                  log("template_reevaluation", { errors: 1 });
                }
              }
            })();
            if (config.defer) config.defer(task);
            else await task;
          }
        }
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
      if (summary.errors > 0 || persistenceErrors > 0) {
        return new Response("Processing failed", { status: 500 });
      }
      return new Response("EVENT_RECEIVED", { status: 200 });
    }

    return new Response("Method not allowed", { status: 405 });
  };
}
