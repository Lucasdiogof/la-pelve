// HTTP do whatsapp-connect -- PURO (sem Deno.*), testável em Node.
//
// Onboarding do WhatsApp Business de cada profissional (Embedded Signup v4).
// Ações (POST JSON {"action": ...}):
//   availability[JWT]   o fluxo está ligado? (responde mesmo desligado)
//   start       [JWT]   cria um state de uso único e devolve a URL da página
//   config      [state] dados públicos para a página abrir o popup da Meta
//   complete    [state] troca o code por token NO SERVIDOR e grava a conexão
//   status      [JWT]   reavalia templates/estado de uma conexão pendente
//   disconnect  [JWT]   tira a inscrição do webhook, apaga o token, desconecta
//
// Segurança: o App Secret e os tokens nunca saem daqui; o state é aleatório
// (256 bits), guardado só como hash, vinculado à profissional logada, expira
// e só vale uma vez; `complete` usa o state como credencial (a página não tem
// a sessão do app). Respostas e logs só carregam códigos, nunca segredos.

import type { ConnectConfigResult } from "./config.ts";
import type { MetaOnboarding, TemplatesReport } from "./meta_onboarding.ts";

export type UpsertResult =
  | { ok: true; id: string }
  | { ok: false; code: "active_connection" | "phone_in_use" | "error" };

export interface ConnectionRow {
  id: string;
  status: string;
  wabaId: string | null;
  phoneNumberId: string | null;
  displayPhoneNumber: string | null;
}

export interface ConnectStore {
  createAttempt(userId: string, stateHash: string, ttlSeconds: number): Promise<"ok" | "rate_limited" | "error">;
  peekAttempt(stateHash: string): Promise<string | null>;
  consumeAttempt(stateHash: string): Promise<string | null>;
  upsertConnection(input: {
    userId: string;
    wabaId: string;
    phoneNumberId: string;
    displayPhoneNumber: string | null;
    status: "pending" | "connected";
    lastError: Record<string, unknown> | null;
  }): Promise<UpsertResult>;
  setAccessToken(connectionId: string, token: string): Promise<boolean>;
  getAccessToken(userId: string): Promise<string | null>;
  getConnection(userId: string): Promise<ConnectionRow | null>;
  disconnect(userId: string): Promise<boolean>;
}

export interface ConnectHandlerDeps {
  config: ConnectConfigResult;
  store: ConnectStore;
  meta: (config: Extract<ConnectConfigResult, { enabled: true }>["config"]) => MetaOnboarding;
  /** Valida o JWT do app e devolve o id do usuário, ou null. */
  authenticate: (authorization: string | null) => Promise<string | null>;
  log?: (event: string, data: Record<string, unknown>) => void;
}

const STATE_TTL_SECONDS = 15 * 60;
const STATE_RE = /^[0-9a-f]{64}$/;
const NUMERIC_ID_RE = /^\d{5,32}$/;
const SUPPORTED_EVENTS = new Set(["FINISH", "FINISH_WHATSAPP_BUSINESS_APP_ONBOARDING"]);
const MAX_BODY_BYTES = 4096;

const CORS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, content-type, apikey, x-client-info",
  "access-control-allow-methods": "POST, OPTIONS",
};

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...CORS },
  });
}

const fail = (status: number, error: string) => json(status, { ok: false, error });

export async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

export function newState(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  return [...bytes].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function newPin(): string {
  const n = crypto.getRandomValues(new Uint32Array(1))[0] % 1_000_000;
  return n.toString().padStart(6, "0");
}

export function readinessFrom(report: TemplatesReport): {
  ready: boolean;
  code: "templates_pending" | "templates_rejected" | null;
} {
  const states = [report.confirmation, report.reminder];
  if (states.every((s) => s === "approved")) return { ready: true, code: null };
  if (states.some((s) => s === "rejected")) return { ready: false, code: "templates_rejected" };
  return { ready: false, code: "templates_pending" };
}

export function createConnectHandler(deps: ConnectHandlerDeps): (req: Request) => Promise<Response> {
  const log = deps.log ?? ((event, data) => console.log(JSON.stringify({ event, ...data })));

  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
    if (req.method !== "POST") return fail(405, "method_not_allowed");

    const raw = await req.text();
    if (raw.length > MAX_BODY_BYTES) return fail(413, "payload_too_large");
    let input: Record<string, unknown>;
    try {
      const parsed = JSON.parse(raw || "{}");
      if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) throw new Error();
      input = parsed as Record<string, unknown>;
    } catch {
      return fail(400, "invalid_json");
    }

    // Único endpoint que responde mesmo desligado: o app decide se mostra o
    // botão "Conectar" ou a tela segura "Integração em preparação".
    if (input.action === "availability") {
      const userId = await deps.authenticate(req.headers.get("authorization"));
      if (!userId) return fail(401, "unauthorized");
      return json(200, { ok: true, enabled: deps.config.enabled });
    }

    if (!deps.config.enabled) {
      log("whatsapp_connect_not_configured", { action: String(input.action ?? "") });
      return fail(503, "not_configured");
    }
    const config = deps.config.config;
    const meta = deps.meta(config);

    switch (input.action) {
      case "start": {
        const userId = await deps.authenticate(req.headers.get("authorization"));
        if (!userId) return fail(401, "unauthorized");
        const state = newState();
        const created = await deps.store.createAttempt(userId, await sha256Hex(state), STATE_TTL_SECONDS);
        if (created === "rate_limited") return fail(429, "too_many_attempts");
        if (created !== "ok") return fail(500, "internal");
        const url = new URL(config.connectPageUrl);
        url.hash = `state=${state}`;
        log("whatsapp_connect_started", {});
        return json(200, { ok: true, connect_url: url.toString(), expires_in: STATE_TTL_SECONDS });
      }

      case "config": {
        const state = String(input.state ?? "");
        if (!STATE_RE.test(state)) return fail(400, "invalid_state");
        if (!(await deps.store.peekAttempt(await sha256Hex(state)))) return fail(410, "state_expired");
        return json(200, {
          ok: true,
          app_id: config.appId,
          config_id: config.configId,
          graph_version: config.graphApiVersion,
        });
      }

      case "complete":
        return await complete(input, config, meta);

      case "status": {
        const userId = await deps.authenticate(req.headers.get("authorization"));
        if (!userId) return fail(401, "unauthorized");
        return await refreshStatus(userId, meta);
      }

      case "disconnect": {
        const userId = await deps.authenticate(req.headers.get("authorization"));
        if (!userId) return fail(401, "unauthorized");
        const connection = await deps.store.getConnection(userId);
        if (!connection) return json(200, { ok: true });
        // Melhor esforço: tira a inscrição do webhook ANTES de apagar o token.
        const token = await deps.store.getAccessToken(userId);
        let unsubscribed = !connection.wabaId || !token;
        if (token && connection.wabaId) {
          unsubscribed = (await meta.unsubscribeApp(token, connection.wabaId)).ok;
        }
        if (!(await deps.store.disconnect(userId))) return fail(500, "internal");
        log("whatsapp_connect_disconnected", { unsubscribed });
        return json(200, { ok: true, unsubscribed });
      }

      default:
        return fail(400, "unknown_action");
    }
  };

  async function complete(
    input: Record<string, unknown>,
    config: Extract<ConnectConfigResult, { enabled: true }>["config"],
    meta: MetaOnboarding,
  ): Promise<Response> {
    const state = String(input.state ?? "");
    const code = typeof input.code === "string" ? input.code : "";
    const wabaId = String(input.waba_id ?? "");
    const phoneNumberId = String(input.phone_number_id ?? "");
    const event = String(input.event ?? "FINISH");
    if (!STATE_RE.test(state)) return fail(400, "invalid_state");
    if (!code || code.length > 1024) return fail(400, "invalid_code");
    if (!NUMERIC_ID_RE.test(wabaId) || !NUMERIC_ID_RE.test(phoneNumberId)) return fail(400, "invalid_ids");
    if (!SUPPORTED_EVENTS.has(event)) return fail(400, "unsupported_event");

    // O code da Meta vive 30 s: consome o state e troca imediatamente.
    const userId = await deps.store.consumeAttempt(await sha256Hex(state));
    if (!userId) return fail(410, "state_expired");

    const exchanged = await meta.exchangeCode(code);
    if (!exchanged.ok) {
      log("whatsapp_connect_failed", { step: "exchange", code: exchanged.code });
      return fail(502, "exchange_failed");
    }
    const token = exchanged.accessToken;

    // Os ids vieram do navegador: só valem se o token recém-obtido enxerga o
    // número DENTRO dessa WABA (impede ligar o número de outra pessoa).
    const belongs = await meta.phoneBelongsToWaba(token, wabaId, phoneNumberId);
    if (!belongs.ok || !belongs.belongs) {
      log("whatsapp_connect_failed", { step: "ownership" });
      return fail(403, "phone_not_in_waba");
    }
    const phone = await meta.getPhoneNumber(token, phoneNumberId);
    const displayPhoneNumber = phone.ok ? phone.displayPhoneNumber : null;

    const subscribed = await meta.subscribeApp(token, wabaId);
    // Número novo na Cloud API precisa ser registrado; no modo coexistência
    // (WhatsApp Business App) o número já é do app e não se registra.
    let registerOk = true;
    if (event === "FINISH") registerOk = (await meta.registerPhone(token, phoneNumberId, newPin())).ok;

    const templates = await meta.ensureTemplates(token, wabaId);
    const readiness = templates.ok ? readinessFrom(templates.report) : { ready: false, code: "templates_pending" as const };

    let lastError: Record<string, unknown> | null = null;
    if (!subscribed.ok) lastError = { code: "webhook_subscription_failed" };
    else if (!registerOk) lastError = { code: "phone_registration_failed" };
    else if (!readiness.ready) lastError = { code: readiness.code };

    const status = lastError === null ? "connected" : "pending";
    const upserted = await deps.store.upsertConnection({
      userId,
      wabaId,
      phoneNumberId,
      displayPhoneNumber,
      status,
      lastError,
    });
    if (!upserted.ok) {
      const http = upserted.code === "error" ? 500 : 409;
      return fail(http, upserted.code);
    }
    if (!(await deps.store.setAccessToken(upserted.id, token))) {
      log("whatsapp_connect_failed", { step: "store_token" });
      return fail(500, "internal");
    }
    log("whatsapp_connect_completed", { status, event });
    return json(200, { ok: true, status });
  }

  async function refreshStatus(userId: string, meta: MetaOnboarding): Promise<Response> {
    const connection = await deps.store.getConnection(userId);
    if (!connection) return json(200, { ok: true, status: "none" });
    if (connection.status !== "pending" || !connection.wabaId || !connection.phoneNumberId) {
      return json(200, { ok: true, status: connection.status });
    }
    const token = await deps.store.getAccessToken(userId);
    if (!token) return json(200, { ok: true, status: connection.status });
    const templates = await meta.ensureTemplates(token, connection.wabaId);
    if (!templates.ok) return fail(502, "meta_unavailable");
    const readiness = readinessFrom(templates.report);
    // Inscrição no webhook é idempotente: refaz antes de promover a "conectado".
    const resubscribed = await meta.subscribeApp(token, connection.wabaId);
    if (!resubscribed.ok) {
      return json(200, { ok: true, status: "pending", reason: "webhook_subscription_failed" });
    }
    if (readiness.ready) {
      const upserted = await deps.store.upsertConnection({
        userId,
        wabaId: connection.wabaId,
        phoneNumberId: connection.phoneNumberId,
        displayPhoneNumber: connection.displayPhoneNumber,
        status: "connected",
        lastError: null,
      });
      if (!upserted.ok) return fail(500, "internal");
      return json(200, { ok: true, status: "connected" });
    }
    return json(200, { ok: true, status: "pending", reason: readiness.code });
  }
}
