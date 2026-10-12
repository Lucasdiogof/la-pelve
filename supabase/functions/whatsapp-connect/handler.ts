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
import { META_REGISTRATION_RATE_LIMIT, type MetaOnboarding, type TemplatesReport } from "./meta_onboarding.ts";

export type UpsertResult =
  | { ok: true; id: string }
  | { ok: false; code: "active_connection" | "phone_in_use" | "credential_missing" | "error" };

/** Progresso do onboarding persistido em whatsapp_connections.setup_state (sem segredos). */
export interface SetupState {
  mode: "cloud" | "coexistence";
  /** Instantes (ISO) das chamadas a /register nas últimas 72 h. */
  register_attempts: string[];
  /** Enquanto no futuro, não tenta registrar de novo (erro 133016). */
  rate_limited_until?: string;
}

export interface ConnectionRow {
  id: string;
  status: string;
  wabaId: string | null;
  phoneNumberId: string | null;
  displayPhoneNumber: string | null;
  setupState: SetupState;
}

/** Motivos pelos quais uma conexão ainda NÃO está pronta para enviar. */
export type PendingReason =
  | "webhook_subscription_failed"
  | "phone_not_connected"
  | "phone_pin_required"
  | "phone_registration_rate_limited"
  | "phone_registration_retry_later"
  | "phone_registration_failed"
  | "templates_pending"
  | "templates_rejected"
  | "account_limited"
  | "account_blocked"
  | "meta_unavailable";

export interface ConnectStore {
  createAttempt(userId: string, stateHash: string, ttlSeconds: number): Promise<"ok" | "rate_limited" | "error">;
  peekAttempt(stateHash: string): Promise<string | null>;
  consumeAttempt(stateHash: string): Promise<string | null>;
  upsertConnection(input: {
    userId: string;
    wabaId: string;
    phoneNumberId: string;
    displayPhoneNumber: string | null;
    status: "pending" | "connected" | "error";
    lastError: Record<string, unknown> | null;
    setupState: SetupState;
  }): Promise<UpsertResult>;
  /** Quantas OUTRAS profissionais ainda usam a inscrição de webhook desta WABA. */
  countOtherConnectionsOnWaba(userId: string, wabaId: string): Promise<number>;
  setAccessToken(connectionId: string, token: string): Promise<boolean>;
  getAccessToken(userId: string): Promise<string | null>;
  getConnection(userId: string): Promise<ConnectionRow | null>;
  disconnect(userId: string): Promise<boolean>;
  reservePhoneRegistration(userId: string, phoneNumberId: string): Promise<
    { ok: true; pin: string } | { ok: false; reason: "limited" | "cooldown" | "error" }
  >;
  markPhoneRegistrationRateLimited(userId: string, phoneNumberId: string): Promise<boolean>;
}

export interface ConnectHandlerDeps {
  config: ConnectConfigResult;
  store: ConnectStore;
  meta: (config: Extract<ConnectConfigResult, { enabled: true }>["config"]) => MetaOnboarding;
  /** Valida o JWT do app e devolve o id do usuário, ou null. */
  authenticate: (authorization: string | null) => Promise<string | null>;
  now?: () => Date;
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

const REGISTRATION_WINDOW_MS = 72 * 60 * 60 * 1000;
/** Margem sob o limite de 10 registros por número em 72 h da Meta. */
const MAX_REGISTRATIONS_IN_WINDOW = 8;

export function emptySetup(mode: SetupState["mode"] = "cloud"): SetupState {
  return { mode, register_attempts: [] };
}

/**
 * Garante o registro do número SEM nunca inventar PIN para número que já tem
 * verificação em duas etapas, sem registrar o que já está conectado (inclui
 * coexistência) e respeitando o limite de 72 h da Meta.
 */
async function ensurePhoneReady(
  meta: MetaOnboarding,
  store: ConnectStore,
  userId: string,
  token: string,
  phoneNumberId: string,
  setup: SetupState,
  now: Date,
): Promise<{ reason: PendingReason | null; setup: SetupState; displayPhoneNumber: string | null }> {
  const info = await meta.getPhoneInfo(token, phoneNumberId);
  if (!info.ok) return { reason: "meta_unavailable", setup, displayPhoneNumber: null };
  const display = info.info.displayPhoneNumber;
  if (info.info.status === "CONNECTED") return { reason: null, setup, displayPhoneNumber: display };
  // Coexistência: o número é do WhatsApp Business App; nunca se registra aqui.
  if (setup.mode === "coexistence") return { reason: "phone_not_connected", setup, displayPhoneNumber: display };
  if (info.info.isPinEnabled === true) return { reason: "phone_pin_required", setup, displayPhoneNumber: display };
  // Never register a number on incomplete/unexpected Meta data. A missing PIN
  // flag does NOT mean that two-step verification is disabled.
  if (info.info.status !== "PENDING" || info.info.isPinEnabled !== false) {
    return { reason: "phone_not_connected", setup, displayPhoneNumber: display };
  }

  const cutoff = now.getTime() - REGISTRATION_WINDOW_MS;
  const attempts = setup.register_attempts.filter((t) => Date.parse(t) > cutoff);
  const blockedUntil = setup.rate_limited_until ? Date.parse(setup.rate_limited_until) : 0;
  if (blockedUntil > now.getTime() || attempts.length >= MAX_REGISTRATIONS_IN_WINDOW) {
    return {
      reason: "phone_registration_rate_limited",
      setup: { ...setup, register_attempts: attempts },
      displayPhoneNumber: display,
    };
  }
  // Conta a tentativa ANTES de chamar: se a persistência falhar depois, o
  // limite continua protegido.
  const next: SetupState = { ...setup, register_attempts: [...attempts, now.toISOString()] };
  const registered = await meta.registerPhone(token, phoneNumberId, newPin());
  if (registered.ok) return { reason: null, setup: next, displayPhoneNumber: display };
  if (registered.metaCode === META_REGISTRATION_RATE_LIMIT) {
    return {
      reason: "phone_registration_rate_limited",
      setup: { ...next, rate_limited_until: new Date(now.getTime() + REGISTRATION_WINDOW_MS).toISOString() },
      displayPhoneNumber: display,
    };
  }
  return { reason: "phone_registration_failed", setup: next, displayPhoneNumber: display };
}

/** Executa (de forma idempotente) todos os passos e devolve o 1º motivo de pendência. */
async function evaluateReadiness(
  meta: MetaOnboarding,
  store: ConnectStore,
  input: { userId: string; token: string; wabaId: string; phoneNumberId: string; setup: SetupState; now: Date },
): Promise<{ reason: PendingReason | null; setup: SetupState; displayPhoneNumber: string | null }> {
  const subscribed = await meta.subscribeApp(input.token, input.wabaId);
  const phone = await ensurePhoneReady(meta, store, input.userId, input.token, input.phoneNumberId, input.setup, input.now);
  const templates = await meta.ensureTemplates(input.token, input.wabaId);
  const health = await meta.getAccountHealth(input.token, input.wabaId);

  let reason: PendingReason | null = null;
  if (!subscribed.ok) reason = "webhook_subscription_failed";
  else if (phone.reason) reason = phone.reason;
  else if (!templates.ok) reason = "meta_unavailable";
  else {
    const t = readinessFrom(templates.report);
    if (!t.ready) reason = t.code;
    else if (!health.ok || health.health === "unknown") reason = "meta_unavailable";
    else if (health.health === "blocked") reason = "account_blocked";
    else if (health.health === "limited") reason = "account_limited";
  }
  return { reason, setup: phone.setup, displayPhoneNumber: phone.displayPhoneNumber };
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
        // A inscrição de webhook é por WABA: só sai quando nenhuma outra
        // profissional (outro número da mesma WABA) ainda depende dela.
        // Melhor esforço, ANTES de apagar o token.
        let unsubscribed = false;
        let sharedWaba = false;
        const token = await deps.store.getAccessToken(userId);
        if (token && connection.wabaId) {
          const others = await deps.store.countOtherConnectionsOnWaba(userId, connection.wabaId);
          sharedWaba = others !== 0; // inclui falha na contagem (-1): na dúvida, mantém
          if (!sharedWaba) unsubscribed = (await meta.unsubscribeApp(token, connection.wabaId)).ok;
        }
        if (!(await deps.store.disconnect(userId))) return fail(500, "internal");
        log("whatsapp_connect_disconnected", { unsubscribed, sharedWaba });
        return json(200, { ok: true, unsubscribed, shared_waba: sharedWaba });
      }

      default:
        return fail(400, "unknown_action");
    }
  };

  async function complete(
    input: Record<string, unknown>,
    _config: Extract<ConnectConfigResult, { enabled: true }>["config"],
    meta: MetaOnboarding,
  ): Promise<Response> {
    const now = deps.now ?? (() => new Date());
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

    // Só leitura na Meta: os ids vieram do navegador e só valem se o token
    // recém-obtido enxerga o número DENTRO dessa WABA.
    const belongs = await meta.phoneBelongsToWaba(token, wabaId, phoneNumberId);
    if (!belongs.ok || !belongs.belongs) {
      log("whatsapp_connect_failed", { step: "ownership" });
      return fail(403, "phone_not_in_waba");
    }

    // Conflitos locais ANTES de qualquer efeito na Meta (inscrição, registro,
    // templates): a linha 'pending' reserva o número para esta profissional.
    let setup = emptySetup(event === "FINISH" ? "cloud" : "coexistence");
    const claimed = await deps.store.upsertConnection({
      userId,
      wabaId,
      phoneNumberId,
      displayPhoneNumber: null,
      status: "pending",
      lastError: { code: "onboarding_in_progress" },
      setupState: setup,
    });
    if (!claimed.ok) {
      log("whatsapp_connect_failed", { step: "claim", code: claimed.code });
      return fail(claimed.code === "error" ? 500 : 409, claimed.code);
    }

    // Credencial primeiro: nada fica 'connected' sem token persistido.
    if (!(await deps.store.setAccessToken(claimed.id, token))) {
      log("whatsapp_connect_failed", { step: "store_token" });
      await deps.store.upsertConnection({
        userId,
        wabaId,
        phoneNumberId,
        displayPhoneNumber: null,
        status: "pending",
        lastError: { code: "credential_store_failed" },
        setupState: setup,
      });
      return fail(500, "credential_store_failed");
    }

    const evaluated = await evaluateReadiness(meta, deps.store, { userId, token, wabaId, phoneNumberId, setup, now: now() });
    setup = evaluated.setup;
    const persisted = await persistEvaluation(userId, wabaId, phoneNumberId, evaluated);
    if (!persisted.ok) {
      log("whatsapp_connect_failed", { step: "persist", code: persisted.code });
      return fail(500, persisted.code);
    }
    log("whatsapp_connect_completed", { status: persisted.status, reason: evaluated.reason, event });
    return json(200, { ok: true, status: persisted.status, ...(evaluated.reason ? { reason: evaluated.reason } : {}) });
  }

  async function persistEvaluation(
    userId: string,
    wabaId: string,
    phoneNumberId: string,
    evaluated: { reason: PendingReason | null; setup: SetupState; displayPhoneNumber: string | null },
    fallbackDisplay: string | null = null,
  ): Promise<{ ok: true; status: "connected" | "pending" } | { ok: false; code: string }> {
    const status = evaluated.reason === null ? "connected" : "pending";
    const upserted = await deps.store.upsertConnection({
      userId,
      wabaId,
      phoneNumberId,
      displayPhoneNumber: evaluated.displayPhoneNumber ?? fallbackDisplay,
      status,
      lastError: evaluated.reason === null ? null : { code: evaluated.reason },
      setupState: evaluated.setup,
    });
    if (upserted.ok) return { ok: true, status };
    if (upserted.code === "credential_missing") {
      // Sem token no Vault não existe "conectado": volta a pendente.
      await deps.store.upsertConnection({
        userId,
        wabaId,
        phoneNumberId,
        displayPhoneNumber: fallbackDisplay,
        status: "pending",
        lastError: { code: "credential_store_failed" },
        setupState: evaluated.setup,
      });
    }
    return { ok: false, code: upserted.code === "credential_missing" ? "credential_store_failed" : "internal" };
  }

  async function refreshStatus(userId: string, meta: MetaOnboarding): Promise<Response> {
    const now = deps.now ?? (() => new Date());
    const connection = await deps.store.getConnection(userId);
    if (!connection) return json(200, { ok: true, status: "none" });
    // Conectada/desconectada: nada a reavaliar. Pendente e erro (ex.: conta
    // reabilitada pela Meta) passam pela mesma checagem completa.
    if (
      (connection.status !== "pending" && connection.status !== "error") ||
      !connection.wabaId ||
      !connection.phoneNumberId
    ) {
      return json(200, { ok: true, status: connection.status });
    }
    const token = await deps.store.getAccessToken(userId);
    if (!token) {
      return json(200, { ok: true, status: connection.status, reason: "credential_missing" });
    }
    const evaluated = await evaluateReadiness(meta, {
      token,
      wabaId: connection.wabaId,
      phoneNumberId: connection.phoneNumberId,
      setup: connection.setupState,
      now: now(),
    });
    const persisted = await persistEvaluation(
      userId,
      connection.wabaId,
      connection.phoneNumberId,
      evaluated,
      connection.displayPhoneNumber,
    );
    if (!persisted.ok) return fail(500, persisted.code);
    return json(200, {
      ok: true,
      status: persisted.status,
      ...(evaluated.reason ? { reason: evaluated.reason } : {}),
    });
  }
}
