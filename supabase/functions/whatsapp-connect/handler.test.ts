import { test } from "node:test";
import assert from "node:assert/strict";
import { readConnectConfig } from "./config.ts";
import {
  createConnectHandler,
  emptySetup,
  readinessFrom,
  sha256Hex,
  type ConnectStore,
  type ConnectionRow,
  type SetupState,
} from "./handler.ts";
import {
  META_REGISTRATION_RATE_LIMIT,
  type AccountHealth,
  type MetaOnboarding,
  type PhoneInfo,
  type TemplatesReport,
} from "./meta_onboarding.ts";

const env: Record<string, string> = {
  WHATSAPP_SELF_CONNECT_ENABLED: "true",
  META_APP_ID: "1234567890",
  META_ES_CONFIG_ID: "9876543210",
  WHATSAPP_APP_SECRET: "app-secret-app-secret-123",
  WHATSAPP_GRAPH_API_VERSION: "v25.0",
  WHATSAPP_TEMPLATE_LANGUAGE: "pt_BR",
  WHATSAPP_CONNECT_PAGE_URL: "https://lapelve.example/whatsapp-connect.html",
};
const config = readConnectConfig((n) => env[n]);
const SECRET_TOKEN = "EAAB-token-secreto-da-meta-0000000000";
const NOW = new Date("2026-10-12T12:00:00Z");

type Conn = ConnectionRow & { user: string; token?: string; lastError: Record<string, unknown> | null };

/** Banco falso que imita as regras das RPCs (WA007/WA008/WA009) e registra a ordem das chamadas. */
interface Guard {
  pin: string;
  attempts: number[];
  last?: number;
  blockedUntil?: number;
}

const HOUR = 3600_000;

/**
 * Banco falso que imita as regras das RPCs (WA007/WA008/WA009 e o guard de
 * registro da 0032, por phone_number_id) e registra a ordem das chamadas.
 */
function makeStore(events: string[], clock: () => Date = () => NOW) {
  const attempts = new Map<string, { user: string; used: boolean }>();
  const connections = new Map<string, Conn>();
  const guards = new Map<string, Guard>();
  const flags = {
    failSetToken: false,
    failCount: false,
    dropTokenBeforePromote: false,
    failReserve: false,
    staleOnConnect: false,
    failFlag: false,
  };
  const upserts: Array<Parameters<ConnectStore["upsertConnection"]>[0]> = [];
  let pinSeq = 0;
  let seq = 0;
  const store: ConnectStore = {
    async createAttempt(user, hash) {
      attempts.set(hash, { user, used: false });
      return "ok";
    },
    async peekAttempt(hash) {
      const a = attempts.get(hash);
      return a && !a.used ? a.user : null;
    },
    async consumeAttempt(hash) {
      const a = attempts.get(hash);
      if (!a || a.used) return null;
      a.used = true;
      return a.user;
    },
    async upsertConnection(i) {
      events.push(`upsert:${i.status}`);
      upserts.push(i);
      // 0034: evento negativo de template mais novo que a avaliação (WA010).
      if (i.status === "connected" && flags.staleOnConnect) return { ok: false, code: "stale_evaluation" };
      for (const c of connections.values()) {
        if (c.phoneNumberId === i.phoneNumberId && c.user !== i.userId) return { ok: false, code: "phone_in_use" };
      }
      const existing = connections.get(i.userId);
      if (existing?.status === "connected" && existing.phoneNumberId !== i.phoneNumberId) {
        return { ok: false, code: "active_connection" };
      }
      if (i.status === "connected") {
        if (flags.dropTokenBeforePromote && existing) existing.token = undefined;
        if (!existing?.token) return { ok: false, code: "credential_missing" };
      }
      const id = existing?.id ?? `conn-${++seq}`;
      connections.set(i.userId, {
        id,
        user: i.userId,
        status: i.status,
        wabaId: i.wabaId,
        phoneNumberId: i.phoneNumberId,
        displayPhoneNumber: i.displayPhoneNumber ?? existing?.displayPhoneNumber ?? null,
        setupState: i.setupState,
        lastError: i.lastError,
        token: existing?.token,
      });
      return { ok: true, id };
    },
    async countOtherConnectionsOnWaba(user, waba) {
      if (flags.failCount) return -1;
      return [...connections.values()].filter(
        (c) => c.wabaId === waba && c.user !== user && (c.status === "pending" || c.status === "connected"),
      ).length;
    },
    async setAccessToken(id, token) {
      events.push("store:token");
      if (flags.failSetToken) return false;
      for (const c of connections.values()) if (c.id === id) c.token = token;
      return true;
    },
    async getAccessToken(user) {
      return connections.get(user)?.token ?? null;
    },
    async getConnection(user) {
      return connections.get(user) ?? null;
    },
    async disconnect(user) {
      events.push("store:disconnect");
      const c = connections.get(user);
      if (c) {
        c.status = "disconnected";
        c.token = undefined;
      }
      return true;
    },
    async reservePhoneRegistration(user, phone, { existingPinOnly }) {
      events.push("store:reserve");
      if (flags.failReserve) return { ok: false, reason: "error" };
      const c = connections.get(user);
      if (!c || c.phoneNumberId !== phone || (c.status !== "pending" && c.status !== "error")) {
        return { ok: false, reason: "error" };
      }
      let g = guards.get(phone);
      if (!g) {
        if (existingPinOnly) return { ok: false, reason: "pin_unknown" };
        g = { pin: String(123456 + ++pinSeq).padStart(6, "0"), attempts: [] };
        guards.set(phone, g);
      }
      const now = clock().getTime();
      if (g.blockedUntil && g.blockedUntil > now) return { ok: false, reason: "limited" };
      g.attempts = g.attempts.filter((t) => t > now - 72 * HOUR);
      if (g.attempts.length >= 8) {
        g.blockedUntil = g.attempts[0] + 72 * HOUR;
        return { ok: false, reason: "limited" };
      }
      if (g.last !== undefined && g.last > now - 10 * 60_000) return { ok: false, reason: "cooldown" };
      g.attempts.push(now);
      g.last = now;
      g.blockedUntil = undefined;
      return { ok: true, pin: g.pin };
    },
    async flagTokenInvalid(user, hash) {
      events.push("store:flag");
      if (flags.failFlag) return "error";
      const c = connections.get(user);
      if (!c || (c.status !== "connected" && c.status !== "pending")) return "skipped";
      if (!c.token || (await sha256Hex(c.token)) !== hash) return "stale";
      c.status = "error";
      c.lastError = { code: "token_invalid" };
      return "flagged";
    },
    async markPhoneRegistrationRateLimited(user, phone) {
      events.push("store:mark_limited");
      const g = guards.get(phone);
      if (!g || connections.get(user)?.phoneNumberId !== phone) return false;
      const now = clock().getTime();
      g.blockedUntil = Math.max(g.blockedUntil ?? now, now + 72 * HOUR);
      return true;
    },
  };
  return { store, attempts, connections, guards, flags, upserts };
}

interface MetaScript {
  phone: PhoneInfo;
  registerResult:
    | { ok: true }
    | { ok: false; code: "meta_rejected" | "meta_unreachable" | "meta_invalid_response"; metaCode?: number };
  report: TemplatesReport;
  health: AccountHealth;
  subscribeOk: boolean;
  belongs: boolean;
  exchangeOk: boolean;
  tokenValid: boolean;
  tokenExpiresAt: Date | null;
  debugFails: boolean;
  /** Roda DENTRO da resposta do /debug_token (simula reconexão no meio do caminho). */
  onDebugToken?: () => void;
}

function makeMeta(events: string[]) {
  const script: MetaScript = {
    phone: { displayPhoneNumber: "+55 62 99999-0000", status: "CONNECTED", isPinEnabled: false },
    registerResult: { ok: true },
    report: { confirmation: "approved", reminder: "approved" },
    health: "available",
    subscribeOk: true,
    belongs: true,
    exchangeOk: true,
    tokenValid: true,
    tokenExpiresAt: null,
    debugFails: false,
  };
  const pins: string[] = [];
  const meta: MetaOnboarding = {
    async exchangeCode() {
      events.push("meta:exchange");
      return script.exchangeOk ? { ok: true, accessToken: SECRET_TOKEN } : { ok: false, code: "meta_rejected" };
    },
    async getPhoneInfo() {
      events.push("meta:phone");
      return { ok: true, info: script.phone };
    },
    async phoneBelongsToWaba() {
      events.push("meta:ownership");
      return { ok: true, belongs: script.belongs };
    },
    async subscribeApp() {
      events.push("meta:subscribe");
      return script.subscribeOk ? { ok: true } : { ok: false, code: "meta_rejected" };
    },
    async unsubscribeApp() {
      events.push("meta:unsubscribe");
      return { ok: true };
    },
    async registerPhone(_t, _p, pin) {
      events.push("meta:register");
      pins.push(pin);
      return script.registerResult;
    },
    async ensureTemplates() {
      events.push("meta:templates");
      return { ok: true, report: script.report };
    },
    async getTemplatesReport() {
      events.push("meta:templates_read");
      return { ok: true, report: script.report };
    },
    async debugToken() {
      script.onDebugToken?.();
      if (script.debugFails) return { ok: false, code: "meta_unreachable" };
      return { ok: true, info: { valid: script.tokenValid, expiresAt: script.tokenExpiresAt } };
    },
    async getAccountHealth() {
      events.push("meta:health");
      return { ok: true, health: script.health };
    },
  };
  return { meta, script, pins };
}

function build() {
  const events: string[] = [];
  let clock = NOW;
  const s = makeStore(events, () => clock);
  const m = makeMeta(events);
  const logs: string[] = [];
  const users: Record<string, string> = { "Bearer jwt-a": "user-a", "Bearer jwt-b": "user-b" };
  const handler = createConnectHandler({
    config,
    store: s.store,
    meta: () => m.meta,
    authenticate: async (auth) => (auth ? (users[auth] ?? null) : null),
    now: () => clock,
    log: (event, data) => logs.push(JSON.stringify({ event, ...data })),
  });
  const call = (body: unknown, auth?: string) =>
    handler(
      new Request("https://x.test/fn", {
        method: "POST",
        headers: auth ? { authorization: auth } : {},
        body: JSON.stringify(body),
      }),
    );
  return { ...s, ...m, events, call, logs, advance: (ms: number) => (clock = new Date(clock.getTime() + ms)) };
}
type H = ReturnType<typeof build>;

async function startFor(h: H, auth: string): Promise<string> {
  const res = await h.call({ action: "start" }, auth);
  assert.equal(res.status, 200);
  const body = (await res.json()) as { connect_url: string };
  return new URL(body.connect_url).hash.replace("#state=", "");
}

const complete = (state: string, extra: Record<string, unknown> = {}) => ({
  action: "complete",
  state,
  code: "code-from-meta",
  waba_id: "111111111111",
  phone_number_id: "222222222222",
  event: "FINISH",
  ...extra,
});

const MUTATING = ["meta:subscribe", "meta:register", "meta:templates"];
const mutations = (h: H) => h.events.filter((e) => MUTATING.includes(e));
const body = async (res: Response) => (await res.json()) as Record<string, unknown>;

// --------------------------------------------------------------------------
// Configuração / state
// --------------------------------------------------------------------------

test("config: com a chave desligada, `missing` diz o que mais falta (só nomes) e o log não vaza valores", async () => {
  const offOnly = readConnectConfig((n) => ({ ...env, WHATSAPP_SELF_CONNECT_ENABLED: "false" })[n]);
  assert.deepEqual(!offOnly.enabled && offOnly.missing, ["WHATSAPP_SELF_CONNECT_ENABLED"]);
  const offAndBroken = readConnectConfig((n) => ({ ...env, WHATSAPP_SELF_CONNECT_ENABLED: "", WHATSAPP_CONNECT_PAGE_URL: "http://x" })[n]);
  assert.deepEqual(!offAndBroken.enabled && offAndBroken.missing, ["WHATSAPP_SELF_CONNECT_ENABLED", "WHATSAPP_CONNECT_PAGE_URL"]);
  const logs: string[] = [];
  const handler = createConnectHandler({
    config: offOnly,
    store: makeStore([]).store,
    meta: () => makeMeta([]).meta,
    authenticate: async () => null,
    log: (event, data) => logs.push(JSON.stringify({ event, ...data })),
  });
  const res = await handler(new Request("https://x.test", { method: "POST", body: JSON.stringify({ action: "config" }) }));
  assert.equal(res.status, 503);
  assert.match(logs[0], /"missing":\["WHATSAPP_SELF_CONNECT_ENABLED"\]/);
  for (const value of Object.values(env)) assert.ok(!logs.join().includes(value) || value === "true");
});

test("config: sem a chave/segredos a conexão fica desligada e responde not_configured", async () => {
  assert.equal(readConnectConfig(() => undefined).enabled, false);
  const partial = readConnectConfig((n) => ({ ...env, META_ES_CONFIG_ID: "" })[n]);
  assert.deepEqual(!partial.enabled && partial.missing, ["META_ES_CONFIG_ID"]);
  const off = createConnectHandler({
    config: readConnectConfig(() => undefined),
    store: makeStore([]).store,
    meta: () => makeMeta([]).meta,
    authenticate: async (auth) => (auth ? "user-a" : null),
    log: () => {},
  });
  const post = (action: string, auth?: string) =>
    off(new Request("https://x.test", { method: "POST", headers: auth ? { authorization: auth } : {}, body: JSON.stringify({ action }) }));
  assert.equal((await post("start", "x")).status, 503);
  assert.deepEqual(await body(await post("availability", "x")), { ok: true, enabled: false });
  assert.equal((await body(await post("availability"))).error, "unauthorized");
});

test("start exige sessão; devolve URL HTTPS com state só no fragmento e guarda só o hash", async () => {
  const h = build();
  assert.equal((await h.call({ action: "start" })).status, 401);
  const res = await h.call({ action: "start" }, "Bearer jwt-a");
  const url = new URL(((await res.json()) as { connect_url: string }).connect_url);
  assert.equal(url.protocol, "https:");
  assert.equal(url.search, "");
  const state = url.hash.slice(7);
  assert.match(state, /^[0-9a-f]{64}$/);
  assert.equal(h.attempts.has(state), false);
  assert.equal(h.attempts.has(await sha256Hex(state)), true);
});

test("replay e state inventado/malformado não trocam nada na Meta", async () => {
  const h = build();
  const state = await startFor(h, "Bearer jwt-a");
  assert.equal((await h.call(complete(state))).status, 200);
  assert.equal((await h.call(complete(state))).status, 410);
  assert.equal(h.events.filter((e) => e === "meta:exchange").length, 1);
  assert.equal((await h.call(complete("zzz"))).status, 400);
  assert.equal((await h.call(complete("a".repeat(64)))).status, 410);
});

test("eventos não suportados e ids inválidos são recusados antes de consumir o state", async () => {
  const h = build();
  const state = await startFor(h, "Bearer jwt-a");
  assert.equal((await h.call(complete(state, { event: "CANCEL" }))).status, 400);
  assert.equal((await h.call(complete(state, { waba_id: "abc" }))).status, 400);
  assert.equal((await h.call(complete(state))).status, 200, "state continuava válido");
});

test("config da página só responde para state válido", async () => {
  const h = build();
  const state = await startFor(h, "Bearer jwt-a");
  assert.deepEqual(await body(await h.call({ action: "config", state })), {
    ok: true,
    app_id: "1234567890",
    config_id: "9876543210",
    graph_version: "v25.0",
  });
  assert.equal((await h.call({ action: "config", state: "b".repeat(64) })).status, 410);
});

// --------------------------------------------------------------------------
// Fluxo feliz e ordem das operações
// --------------------------------------------------------------------------

test("fluxo completo: leituras na Meta -> reserva local -> token no Vault -> efeitos na Meta -> conectada", async () => {
  const h = build();
  const res = await h.call(complete(await startFor(h, "Bearer jwt-a")));
  assert.deepEqual(await body(res), { ok: true, status: "connected" });
  assert.deepEqual(h.events, [
    "meta:exchange",
    "meta:ownership",
    "upsert:pending", // reserva o número ANTES de qualquer efeito na Meta
    "store:token", // credencial persistida antes de qualquer promoção
    "meta:subscribe",
    "meta:phone",
    "meta:templates",
    "meta:health",
    "upsert:connected",
  ]);
  const conn = h.connections.get("user-a")!;
  assert.equal(conn.status, "connected");
  assert.equal(conn.token, SECRET_TOKEN);
  assert.equal(conn.displayPhoneNumber, "+55 62 99999-0000");
  assert.ok(!h.logs.join("\n").includes(SECRET_TOKEN), "token nunca em log");
});

// --------------------------------------------------------------------------
// 1. Persistência do token
// --------------------------------------------------------------------------

test("falha ao gravar o token: nunca fica conectada, nenhum efeito na Meta, retry funciona", async () => {
  const h = build();
  h.flags.failSetToken = true;
  const res = await h.call(complete(await startFor(h, "Bearer jwt-a")));
  assert.equal(res.status, 500);
  assert.equal((await body(res)).error, "credential_store_failed");
  const conn = h.connections.get("user-a")!;
  assert.equal(conn.status, "pending");
  assert.equal(conn.lastError?.code, "credential_store_failed");
  assert.equal(conn.token, undefined);
  assert.deepEqual(mutations(h), [], "nada foi alterado na WABA");

  h.flags.failSetToken = false;
  const retry = await h.call(complete(await startFor(h, "Bearer jwt-a")));
  assert.deepEqual(await body(retry), { ok: true, status: "connected" });
  assert.equal(h.connections.get("user-a")!.token, SECRET_TOKEN);
});

test("se o token some antes da promoção, o banco recusa 'conectada' e a resposta é de erro", async () => {
  const h = build();
  h.flags.dropTokenBeforePromote = true;
  const res = await h.call(complete(await startFor(h, "Bearer jwt-a")));
  assert.equal(res.status, 500);
  const conn = h.connections.get("user-a")!;
  assert.equal(conn.status, "pending");
  assert.equal(conn.lastError?.code, "credential_store_failed");
});

test("refresh sem token no Vault não promove", async () => {
  const h = build();
  h.script.report = { confirmation: "approved", reminder: "pending" };
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  h.connections.get("user-a")!.token = undefined;
  h.script.report = { confirmation: "approved", reminder: "approved" };
  const res = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(res.status, "pending");
  assert.equal(res.reason, "credential_missing");
});

// --------------------------------------------------------------------------
// 2. Registro do telefone (PIN, coexistência, limite de 72 h)
// --------------------------------------------------------------------------

test("número já CONNECTED (inclui PIN existente) não é registrado de novo", async () => {
  const h = build();
  h.script.phone = { displayPhoneNumber: "+55 62 1", status: "CONNECTED", isPinEnabled: true };
  const res = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.equal(res.status, "connected");
  assert.ok(!h.events.includes("meta:register"));
});

test("número com 2FA de terceiros (sem PIN nosso): pendência clara, sem inventar PIN", async () => {
  const h = build();
  h.script.phone = { displayPhoneNumber: "+55 62 1", status: "PENDING", isPinEnabled: true };
  const res = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.deepEqual(res, { ok: true, status: "pending", reason: "phone_pin_required" });
  assert.ok(!h.events.includes("meta:register"));
  assert.equal(h.guards.size, 0, "nenhum PIN criado para número de terceiros");
  assert.equal(h.connections.get("user-a")!.status, "pending");
});

test("dados de telefone incompletos nunca disparam registro automático", async () => {
  for (const patch of [
    { status: null, isPinEnabled: false },
    { status: "PENDING", isPinEnabled: null },
    { status: "UNKNOWN", isPinEnabled: false },
  ]) {
    const h = build();
    h.script.phone = { displayPhoneNumber: "+55 62 1", ...patch };
    const res = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
    assert.equal(res.status, "pending");
    assert.equal(res.reason, "phone_not_connected");
    assert.ok(!h.events.includes("meta:register"));
  }
});

const PENDING_NO_PIN: PhoneInfo = { displayPhoneNumber: "+55 62 1", status: "PENDING", isPinEnabled: false };
const PHONE_ID = "222222222222";

test("número novo sem PIN: reserva no banco ANTES de registrar, com PIN de 6 dígitos do Vault", async () => {
  const h = build();
  h.script.phone = PENDING_NO_PIN;
  const res = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.equal(res.status, "connected");
  assert.deepEqual(
    h.events.filter((e) => e === "store:reserve" || e === "meta:register"),
    ["store:reserve", "meta:register"],
  );
  assert.match(h.pins[0], /^\d{6}$/);
  assert.equal(h.pins[0], h.guards.get(PHONE_ID)!.pin, "PIN é o guardado, nunca aleatório no runtime");
  assert.equal(h.guards.get(PHONE_ID)!.attempts.length, 1);
});

test("falha ao reservar no banco: NÃO chama /register e não promove", async () => {
  const h = build();
  h.script.phone = PENDING_NO_PIN;
  h.flags.failReserve = true;
  const res = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.deepEqual(res, { ok: true, status: "pending", reason: "phone_registration_retry_later" });
  assert.ok(!h.events.includes("meta:register"));
});

test("falha de registro: refresh imediato respeita o intervalo mínimo e NÃO promove", async () => {
  const h = build();
  h.script.phone = PENDING_NO_PIN;
  h.script.registerResult = { ok: false, code: "meta_rejected", metaCode: 100 };
  const first = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.deepEqual(first, { ok: true, status: "pending", reason: "phone_registration_failed" });
  h.events.length = 0;
  const refresh = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.deepEqual(refresh, { ok: true, status: "pending", reason: "phone_registration_retry_later" });
  assert.ok(!h.events.includes("meta:register"), "cooldown: não chama a Meta de novo");
  assert.equal(h.connections.get("user-a")!.status, "pending");
});

test("registro volta a funcionar depois do intervalo: mesmo PIN, só então promove", async () => {
  const h = build();
  h.script.phone = PENDING_NO_PIN;
  h.script.registerResult = { ok: false, code: "meta_rejected" };
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  h.advance(11 * 60_000);
  h.script.registerResult = { ok: true };
  const refresh = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(refresh.status, "connected");
  assert.equal(h.pins.length, 2);
  assert.equal(h.pins[0], h.pins[1], "PIN estável entre tentativas");
  assert.equal(h.guards.get(PHONE_ID)!.attempts.length, 2);
});

test("timeout/rede no /register: resultado desconhecido conta a tentativa e pede para tentar depois", async () => {
  const h = build();
  h.script.phone = PENDING_NO_PIN;
  h.script.registerResult = { ok: false, code: "meta_unreachable" };
  const res = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.deepEqual(res, { ok: true, status: "pending", reason: "phone_registration_retry_later" });
  assert.equal(h.guards.get(PHONE_ID)!.attempts.length, 1);
});

test("erro 133016 (10 registros/72 h): bloqueia o número por 72 h no banco e não promove", async () => {
  const h = build();
  h.script.phone = PENDING_NO_PIN;
  h.script.registerResult = { ok: false, code: "meta_rejected", metaCode: META_REGISTRATION_RATE_LIMIT };
  const first = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.equal(first.reason, "phone_registration_rate_limited");
  assert.ok(h.events.includes("store:mark_limited"));
  assert.equal(h.guards.get(PHONE_ID)!.blockedUntil! - NOW.getTime(), 72 * HOUR);

  h.advance(2 * HOUR);
  h.events.length = 0;
  const again = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(again.reason, "phone_registration_rate_limited");
  assert.ok(!h.events.includes("meta:register"), "não tenta registrar durante o bloqueio");

  h.advance(71 * HOUR);
  h.script.registerResult = { ok: true };
  const later = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(later.status, "connected");
});

test("margem de segurança: 8 tentativas nas últimas 72 h impedem novo registro", async () => {
  const h = build();
  h.script.phone = PENDING_NO_PIN;
  h.script.registerResult = { ok: false, code: "meta_rejected" };
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  for (let i = 0; i < 7; i++) {
    h.advance(11 * 60_000);
    await h.call({ action: "status" }, "Bearer jwt-a");
  }
  assert.equal(h.pins.length, 8);
  h.advance(11 * 60_000);
  h.events.length = 0;
  const res = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(res.reason, "phone_registration_rate_limited");
  assert.ok(!h.events.includes("meta:register"));
});

test("desconectar e reconectar NÃO zera o limite do número", async () => {
  const h = build();
  h.script.phone = PENDING_NO_PIN;
  h.script.registerResult = { ok: false, code: "meta_rejected", metaCode: META_REGISTRATION_RATE_LIMIT };
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  await h.call({ action: "disconnect" }, "Bearer jwt-a");
  h.events.length = 0;
  const res = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.equal(res.reason, "phone_registration_rate_limited");
  assert.ok(!h.events.includes("meta:register"));
});

test("reconexão de número que nós registramos (2FA = nosso PIN): registra com o PIN guardado", async () => {
  const h = build();
  h.script.phone = PENDING_NO_PIN;
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  const pin = h.pins[0];
  await h.call({ action: "disconnect" }, "Bearer jwt-a");
  h.advance(HOUR);
  h.script.phone = { displayPhoneNumber: "+55 62 1", status: "PENDING", isPinEnabled: true };
  const res = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.equal(res.status, "connected");
  assert.deepEqual(h.pins, [pin, pin]);
});

test("PIN recusado pela Meta (133005): pendência de PIN", async () => {
  const h = build();
  h.script.phone = PENDING_NO_PIN;
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  await h.call({ action: "disconnect" }, "Bearer jwt-a");
  h.advance(HOUR);
  h.script.phone = { displayPhoneNumber: "+55 62 1", status: "PENDING", isPinEnabled: true };
  h.script.registerResult = { ok: false, code: "meta_rejected", metaCode: 133005 };
  const res = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.deepEqual(res, { ok: true, status: "pending", reason: "phone_pin_required" });
});

test("coexistência: nunca registra; só conecta se o número já estiver CONNECTED", async () => {
  const h = build();
  h.script.phone = { displayPhoneNumber: "+55 62 1", status: "PENDING", isPinEnabled: null };
  const pending = await body(
    await h.call(complete(await startFor(h, "Bearer jwt-a"), { event: "FINISH_WHATSAPP_BUSINESS_APP_ONBOARDING" })),
  );
  assert.deepEqual(pending, { ok: true, status: "pending", reason: "phone_not_connected" });
  assert.ok(!h.events.includes("meta:register"));
  assert.equal(h.connections.get("user-a")!.setupState.mode, "coexistence");

  h.script.phone = { displayPhoneNumber: "+55 62 1", status: "CONNECTED", isPinEnabled: null };
  const ready = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(ready.status, "connected");
  assert.ok(!h.events.includes("meta:register"));
});

// --------------------------------------------------------------------------
// 4. Conflitos antes de alterar a Meta
// --------------------------------------------------------------------------

test("número já conectado a outra profissional: 409 e NENHUM efeito na WABA", async () => {
  const h = build();
  assert.equal((await h.call(complete(await startFor(h, "Bearer jwt-a")))).status, 200);
  h.events.length = 0;
  const res = await h.call(complete(await startFor(h, "Bearer jwt-b")));
  assert.equal(res.status, 409);
  assert.equal((await body(res)).error, "phone_in_use");
  assert.deepEqual(mutations(h), []);
  assert.equal(h.connections.has("user-b"), false);
});

test("conexão ativa de outro número: 409 e NENHUM efeito na WABA", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  h.events.length = 0;
  const res = await h.call(complete(await startFor(h, "Bearer jwt-a"), { phone_number_id: "555555555555" }));
  assert.equal(res.status, 409);
  assert.deepEqual(mutations(h), []);
  assert.equal(h.connections.get("user-a")!.phoneNumberId, "222222222222");
});

test("ids do navegador que o token não enxerga: 403 sem reservar nada nem alterar a WABA", async () => {
  const h = build();
  h.script.belongs = false;
  const res = await h.call(complete(await startFor(h, "Bearer jwt-a")));
  assert.equal(res.status, 403);
  assert.equal(h.connections.size, 0);
  assert.deepEqual(mutations(h), []);
  assert.ok(!h.events.includes("upsert:pending"));
});

test("falha da troca de code: nada gravado, erro genérico", async () => {
  const h = build();
  h.script.exchangeOk = false;
  const res = await h.call(complete(await startFor(h, "Bearer jwt-a")));
  assert.equal(res.status, 502);
  assert.deepEqual(await body(res), { ok: false, error: "exchange_failed" });
  assert.equal(h.connections.size, 0);
});

test("state de A nunca grava na conta de B", async () => {
  const h = build();
  const stateA = await startFor(h, "Bearer jwt-a");
  const stateB = await startFor(h, "Bearer jwt-b");
  assert.equal((await h.call(complete(stateA, { phone_number_id: "333333333333" }))).status, 200);
  assert.equal((await h.call(complete(stateB, { phone_number_id: "444444444444" }))).status, 200);
  assert.equal(h.connections.get("user-a")!.phoneNumberId, "333333333333");
  assert.equal(h.connections.get("user-b")!.phoneNumberId, "444444444444");
});

// --------------------------------------------------------------------------
// 7. Prontidão operacional
// --------------------------------------------------------------------------

test("webhook não inscrito: pendente (e o refresh não promove enquanto falhar)", async () => {
  const h = build();
  h.script.subscribeOk = false;
  const res = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.deepEqual(res, { ok: true, status: "pending", reason: "webhook_subscription_failed" });
  assert.equal((await body(await h.call({ action: "status" }, "Bearer jwt-a"))).status, "pending");
  h.script.subscribeOk = true;
  assert.equal((await body(await h.call({ action: "status" }, "Bearer jwt-a"))).status, "connected");
});

test("templates em análise/rejeitados: pendente; aprovados no refresh promovem", async () => {
  const h = build();
  h.script.report = { confirmation: "approved", reminder: "pending" };
  assert.equal((await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))))).reason, "templates_pending");
  h.script.report = { confirmation: "rejected", reminder: "approved" };
  assert.equal((await body(await h.call({ action: "status" }, "Bearer jwt-a"))).reason, "templates_rejected");
  h.script.report = { confirmation: "approved", reminder: "approved" };
  assert.equal((await body(await h.call({ action: "status" }, "Bearer jwt-a"))).status, "connected");
});

test("conta limitada/bloqueada e saúde desconhecida não ficam conectadas", async () => {
  const h = build();
  h.script.health = "limited";
  assert.equal((await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))))).reason, "account_limited");
  h.script.health = "blocked";
  assert.equal((await body(await h.call({ action: "status" }, "Bearer jwt-a"))).reason, "account_blocked");
  h.script.health = "unknown";
  const unknown = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(unknown.status, "pending");
  assert.equal(unknown.reason, "meta_unavailable");
});

test("falha ao consultar a saúde da Meta impede promover a conexão", async () => {
  const h = build();
  h.meta.getAccountHealth = async () => ({ ok: false, code: "meta_unreachable" });
  const result = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.equal(result.status, "pending");
  assert.equal(result.reason, "meta_unavailable");
  assert.equal(h.connections.get("user-a")!.status, "pending");
});

test("status reavalia conexão em erro (conta reabilitada) antes de liberar", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  h.connections.get("user-a")!.status = "error";
  h.script.report = { confirmation: "approved", reminder: "pending" };
  assert.equal((await body(await h.call({ action: "status" }, "Bearer jwt-a"))).status, "pending");
  h.script.report = { confirmation: "approved", reminder: "approved" };
  assert.equal((await body(await h.call({ action: "status" }, "Bearer jwt-a"))).status, "connected");
});

test("status exige sessão e não mexe em conexão conectada", async () => {
  const h = build();
  assert.equal((await h.call({ action: "status" })).status, 401);
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  h.events.length = 0;
  assert.equal((await body(await h.call({ action: "status" }, "Bearer jwt-a"))).status, "connected");
  assert.deepEqual(h.events, []);
});

// --------------------------------------------------------------------------
// 3. WABA compartilhada na desconexão
// --------------------------------------------------------------------------

test("desconectar com outra profissional na MESMA WABA preserva a inscrição do webhook", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a"), { phone_number_id: "222222222222" }));
  await h.call(complete(await startFor(h, "Bearer jwt-b"), { phone_number_id: "333333333333" }));
  h.events.length = 0;
  const res = await body(await h.call({ action: "disconnect" }, "Bearer jwt-a"));
  assert.equal(res.shared_waba, true);
  assert.equal(res.unsubscribed, false);
  assert.ok(!h.events.includes("meta:unsubscribe"));
  assert.equal(h.connections.get("user-a")!.status, "disconnected");
  assert.equal(h.connections.get("user-b")!.status, "connected");
  assert.equal(h.connections.get("user-b")!.token, SECRET_TOKEN, "B segue com credencial");
});

test("última profissional da WABA: desconectar tira a inscrição e apaga o token", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  const res = await body(await h.call({ action: "disconnect" }, "Bearer jwt-a"));
  assert.deepEqual(res, { ok: true, unsubscribed: true, shared_waba: false });
  assert.ok(h.events.indexOf("meta:unsubscribe") < h.events.indexOf("store:disconnect"));
  assert.equal(h.connections.get("user-a")!.token, undefined);
});

test("na dúvida (contagem falhou) a inscrição é mantida; sem sessão é 401; sem conexão é no-op", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  h.flags.failCount = true;
  const res = await body(await h.call({ action: "disconnect" }, "Bearer jwt-a"));
  assert.equal(res.unsubscribed, false);
  assert.equal((await h.call({ action: "disconnect" })).status, 401);
  assert.equal((await h.call({ action: "disconnect" }, "Bearer jwt-b")).status, 200);
});

test("readinessFrom classifica os estados dos templates", () => {
  assert.equal(readinessFrom({ confirmation: "approved", reminder: "approved" }).ready, true);
  assert.equal(readinessFrom({ confirmation: "missing", reminder: "approved" }).code, "templates_pending");
  assert.equal(readinessFrom({ confirmation: "rejected", reminder: "approved" }).code, "templates_rejected");
  const s: SetupState = emptySetup();
  assert.deepEqual(s, { mode: "cloud", register_attempts: [] });
});

// --------------------------------------------------------------------------
// 0034: início da avaliação e recusa de 'connected' com avaliação velha
// --------------------------------------------------------------------------

test("upsert pós-avaliação leva evaluated_at = início da avaliação (antes das leituras na Meta)", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  assert.equal(h.upserts.at(-1)!.setupState.evaluated_at, NOW.toISOString());
  assert.equal(h.upserts.at(-1)!.status, "connected");
});

test("evento negativo de template mais novo que a avaliação (WA010): nunca conecta, fica pendente", async () => {
  const h = build();
  h.flags.staleOnConnect = true;
  const res = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.deepEqual(res, { ok: true, status: "pending", reason: "templates_pending" });
  const conn = h.connections.get("user-a")!;
  assert.equal(conn.status, "pending");
  assert.equal(conn.lastError?.code, "templates_pending");
});

test("status: reavaliação com WA010 também não promove", async () => {
  const h = build();
  h.script.report = { confirmation: "approved", reminder: "pending" };
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  h.script.report = { confirmation: "approved", reminder: "approved" };
  h.flags.staleOnConnect = true;
  const res = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(res.status, "pending");
  assert.equal(h.connections.get("user-a")!.status, "pending");
});

// --------------------------------------------------------------------------
// Validade do token (expiração, revogação, reconexão)
// --------------------------------------------------------------------------

test("token inválido no complete: nada é feito na Meta e a conexão vira 'error'/token_invalid", async () => {
  const h = build();
  h.script.tokenValid = false;
  const res = await h.call(complete(await startFor(h, "Bearer jwt-a")));
  assert.equal((await body(res)).status, "error");
  assert.deepEqual(mutations(h), []);
  assert.equal(h.connections.get("user-a")!.status, "error");
  assert.deepEqual(h.connections.get("user-a")!.lastError, { code: "token_invalid" });
});

test("status de conexão conectada com token revogado/expirado: vira error/token_invalid e nada é mutado na Meta", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  h.events.length = 0;
  h.script.tokenValid = false;
  const res = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(res.status, "error");
  assert.equal(res.reason, "token_invalid");
  assert.equal(h.connections.get("user-a")!.status, "error");
  assert.deepEqual(h.connections.get("user-a")!.lastError, { code: "token_invalid" });
  assert.deepEqual(mutations(h), []);
});

test("status de conexão conectada com token a menos de 7 dias de vencer: avisa sem gravar nada", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  const upsertsBefore = h.upserts.length;
  h.script.tokenExpiresAt = new Date(NOW.getTime() + 3 * 24 * 3600_000);
  const res = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(res.status, "connected");
  assert.equal(res.reason, "token_expiring");
  assert.equal(res.token_expires_at, h.script.tokenExpiresAt.toISOString());
  assert.equal(h.upserts.length, upsertsBefore);
  assert.equal(h.connections.get("user-a")!.status, "connected");
});

test("status com token longe de vencer, sem expiração ou consulta à Meta indisponível: conectada e inalterada", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  const upsertsBefore = h.upserts.length;
  h.script.tokenExpiresAt = new Date(NOW.getTime() + 40 * 24 * 3600_000);
  assert.deepEqual(await body(await h.call({ action: "status" }, "Bearer jwt-a")), {
    ok: true,
    status: "connected",
    token_expires_at: h.script.tokenExpiresAt.toISOString(),
  });
  h.script.tokenExpiresAt = null;
  assert.deepEqual(await body(await h.call({ action: "status" }, "Bearer jwt-a")), { ok: true, status: "connected" });
  h.script.tokenValid = false;
  h.script.debugFails = true;
  assert.deepEqual(await body(await h.call({ action: "status" }, "Bearer jwt-a")), { ok: true, status: "connected" });
  assert.equal(h.upserts.length, upsertsBefore);
});

test("reconexão: conexão em error/token_invalid volta a conectada com token novo", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  h.script.tokenValid = false;
  await h.call({ action: "status" }, "Bearer jwt-a");
  assert.equal(h.connections.get("user-a")!.status, "error");
  h.script.tokenValid = true;
  const res = await h.call(complete(await startFor(h, "Bearer jwt-a")));
  assert.equal((await body(res)).status, "connected");
  assert.equal(h.connections.get("user-a")!.status, "connected");
  assert.equal(h.connections.get("user-a")!.lastError, null);
});

test("status em error com token ainda inválido continua error; com token válido reavalia e promove", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  h.script.tokenValid = false;
  await h.call({ action: "status" }, "Bearer jwt-a");
  assert.equal((await body(await h.call({ action: "status" }, "Bearer jwt-a"))).status, "error");
  h.script.tokenValid = true;
  assert.equal((await body(await h.call({ action: "status" }, "Bearer jwt-a"))).status, "connected");
});

test("corrida: reconexão (token novo) no meio da checagem NÃO derruba a conexão renovada", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  h.script.tokenValid = false; // o /debug_token vai dizer que o token VELHO não vale
  h.script.onDebugToken = () => {
    h.connections.get("user-a")!.token = "token-novo-da-reconexao-000000";
  };
  const res = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(res.status, "connected");
  assert.equal(res.reason, undefined);
  assert.equal(h.connections.get("user-a")!.status, "connected");
  assert.equal(h.connections.get("user-a")!.lastError, null);
});

test("conexão desconectada no meio da checagem não é afetada", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  h.script.tokenValid = false;
  h.script.onDebugToken = () => {
    h.connections.get("user-a")!.status = "disconnected";
  };
  const res = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(res.status, "disconnected");
  assert.equal(h.connections.get("user-a")!.status, "disconnected");
  assert.equal(h.connections.get("user-a")!.lastError, null);
});

test("falha ao marcar no banco: 500 e a conexão fica como estava", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  h.script.tokenValid = false;
  h.flags.failFlag = true;
  assert.equal((await h.call({ action: "status" }, "Bearer jwt-a")).status, 500);
  assert.equal(h.connections.get("user-a")!.status, "connected");
});

test("o hash enviado ao banco é o SHA-256 do token e o token nunca aparece em resposta nem log", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  h.script.tokenValid = false;
  const res = await h.call({ action: "status" }, "Bearer jwt-a");
  const text = await res.text();
  assert.ok(!text.includes(SECRET_TOKEN));
  assert.ok(h.logs.every((l) => !l.includes(SECRET_TOKEN)));
  assert.equal(h.connections.get("user-a")!.status, "error");
});

test("Meta indisponível (timeout/429/5xx) NUNCA marca a conexão como inválida", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  h.script.tokenValid = false; // ignorado: a consulta falha
  h.script.debugFails = true;
  const before = h.events.length;
  assert.deepEqual(await body(await h.call({ action: "status" }, "Bearer jwt-a")), { ok: true, status: "connected" });
  assert.equal(h.events.slice(before).includes("store:flag"), false);
  assert.equal(h.connections.get("user-a")!.status, "connected");
});
