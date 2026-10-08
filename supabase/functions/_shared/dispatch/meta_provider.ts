// Adapter da WhatsApp Cloud API (Meta). Só transporte + classificação da
// resposta; nenhuma regra de fila. `fetch` é injetado (testes usam mock).
//
// - URL: https://graph.facebook.com/{versão}/{phone_number_id}/messages. A
//   versão vem de configuração explícita (WHATSAPP_GRAPH_API_VERSION), sem
//   default: o projeto ainda não fixou uma.
// - Token só no header Authorization. Nunca em URL, log ou resultado.
// - Timeout explícito (AbortController).
// - Resultado sem texto livre da Meta (só status HTTP e códigos numéricos).

import type { ProviderSendRequest, ProviderSendResult, WhatsappProvider } from "./types.ts";

const GRAPH_VERSION_RE = /^v\d{1,3}\.\d{1,3}$/;
const PHONE_NUMBER_ID_RE = /^\d{5,32}$/;
const MAX_WAMID_LENGTH = 256;
const MAX_RETRY_AFTER_SECONDS = 3600;

/**
 * Códigos da Meta de limite de taxa/capacidade: a mensagem NÃO foi aceita,
 * então pode ser tentada de novo mais tarde (às vezes chegam com HTTP 400).
 *   4 / 80007: limite da aplicação/WABA; 130429: limite de throughput;
 *   131048: limite por spam rate; 131056: limite por par remetente/destino.
 */
const RATE_LIMIT_CODES = new Set([4, 80007, 130429, 131048, 131056]);
/** Token inválido/expirado. */
const AUTH_ERROR_CODES = new Set([190]);

export interface MetaProviderOptions {
  graphApiVersion: string;
  fetchFn?: typeof fetch;
  timeoutMs?: number;
}

export function isValidGraphApiVersion(value: string | undefined): value is string {
  return typeof value === "string" && GRAPH_VERSION_RE.test(value);
}

function numberOrUndefined(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value) ? value : undefined;
}

async function readJson(response: Response): Promise<unknown> {
  try {
    return await response.json();
  } catch {
    return null;
  }
}

function parseRetryAfter(header: string | null): number | undefined {
  if (!header || !/^\d{1,6}$/.test(header)) return undefined;
  return Math.min(Number(header), MAX_RETRY_AFTER_SECONDS);
}

export function createMetaWhatsappProvider(options: MetaProviderOptions): WhatsappProvider {
  if (!isValidGraphApiVersion(options.graphApiVersion)) {
    throw new Error("WHATSAPP_GRAPH_API_VERSION inválida ou ausente (ex.: v23.0)");
  }
  const fetchFn = options.fetchFn ?? fetch;
  const timeoutMs = options.timeoutMs ?? 10_000;

  return {
    async sendTemplate(request: ProviderSendRequest): Promise<ProviderSendResult> {
      if (!PHONE_NUMBER_ID_RE.test(request.phoneNumberId)) {
        return { kind: "rejected", code: "invalid_phone_number_id" };
      }
      if (!request.accessToken) {
        return { kind: "rejected", code: "credential_missing" };
      }

      const url = `https://graph.facebook.com/${options.graphApiVersion}/${request.phoneNumberId}/messages`;
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), timeoutMs);
      let response: Response;
      try {
        response = await fetchFn(url, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${request.accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(request.message),
          signal: controller.signal,
        });
      } catch (error) {
        // Timeout ou falha de rede: a Meta pode ter recebido e enviado.
        const timedOut = error instanceof Error && error.name === "AbortError";
        return { kind: "unknown", code: timedOut ? "timeout" : "network_error" };
      } finally {
        clearTimeout(timer);
      }

      const body = await readJson(response);
      const status = response.status;

      if (status >= 200 && status < 300) {
        const messages = (body as { messages?: unknown } | null)?.messages;
        const wamid = Array.isArray(messages) ? (messages[0] as { id?: unknown } | undefined)?.id : undefined;
        if (typeof wamid === "string" && wamid.trim() && wamid.length <= MAX_WAMID_LENGTH) {
          return { kind: "sent", wamid: wamid.trim() };
        }
        // 2xx sem wamid utilizável: pode ter sido aceita. Não reenviar.
        return { kind: "unknown", code: "invalid_provider_response", httpStatus: status };
      }

      const error = (body as { error?: Record<string, unknown> } | null)?.error ?? {};
      const providerCode = numberOrUndefined(error.code);
      const providerSubcode = numberOrUndefined(error.error_subcode);
      const details = { httpStatus: status, providerCode, providerSubcode };

      if (status === 429 || (providerCode !== undefined && RATE_LIMIT_CODES.has(providerCode))) {
        return {
          kind: "retryable",
          code: "rate_limited",
          ...details,
          retryAfterSeconds: parseRetryAfter(response.headers.get("retry-after")),
        };
      }
      if (status >= 500) {
        return { kind: "retryable", code: "provider_unavailable", ...details };
      }
      if (status === 401 || (providerCode !== undefined && AUTH_ERROR_CODES.has(providerCode))) {
        return { kind: "rejected", code: "auth_error", ...details };
      }
      return { kind: "rejected", code: "request_rejected", ...details };
    },
  };
}
