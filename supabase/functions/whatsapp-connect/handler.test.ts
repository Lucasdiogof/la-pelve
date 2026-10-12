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
function makeStore(events: string[]) {
  const attempts = new Map<string, { user: string; used: boolean }>();
  const connections = new Map<string, Conn>();
  const flags = { failSetToken: false, failCount: false, dropTokenBeforePromote: false };
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
  };
  return { store, attempts, connections, flags };
}

interface MetaScript {
  phone: PhoneInfo;
  registerResult: { ok: true } | { ok: false; code: "meta_rejected"; metaCode?: number };
  report: TemplatesReport;
  health: AccountHealth;
  subscribeOk: boolean;
  belongs: boolean;
  exchangeOk: boolean;
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
    async getAccountHealth() {
      events.push("meta:health");
      return { ok: true, health: script.health };
    },
  };
  return { meta, script, pins };
}

function build() {
  const events: string[] = [];
  const s = makeStore(events);
  const m = makeMeta(events);
  const logs: string[] = [];
  const users: Record<string, string> = { "Bearer jwt-a": "user-a", "Bearer jwt-b": "user-b" };
  let clock = NOW;
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

test("número com PIN existente e ainda não registrado: pendência clara, sem inventar PIN", async () => {
  const h = build();
  h.script.phone = { displayPhoneNumber: "+55 62 1", status: "PENDING", isPinEnabled: true };
  const res = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.deepEqual(res, { ok: true, status: "pending", reason: "phone_pin_required" });
  assert.ok(!h.events.includes("meta:register"));
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

test("número novo sem PIN: registra uma vez com PIN de 6 dígitos e conta a tentativa", async () => {
  const h = build();
  h.script.phone = { displayPhoneNumber: "+55 62 1", status: "PENDING", isPinEnabled: false };
  const res = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.equal(res.status, "connected");
  assert.equal(h.events.filter((e) => e === "meta:register").length, 1);
  assert.match(h.pins[0], /^\d{6}$/);
  assert.equal(h.connections.get("user-a")!.setupState.register_attempts.length, 1);
});

test("falha de registro: refresh NÃO promove, mesmo com templates aprovados e webhook ok", async () => {
  const h = build();
  h.script.phone = { displayPhoneNumber: "+55 62 1", status: "PENDING", isPinEnabled: false };
  h.script.registerResult = { ok: false, code: "meta_rejected", metaCode: 100 };
  const first = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.deepEqual(first, { ok: true, status: "pending", reason: "phone_registration_failed" });
  const refresh = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(refresh.status, "pending");
  assert.equal(refresh.reason, "phone_registration_failed");
  assert.equal(h.connections.get("user-a")!.status, "pending");
  assert.equal(h.connections.get("user-a")!.setupState.register_attempts.length, 2, "tentativas contadas");
});

test("registro volta a funcionar no refresh: só então promove", async () => {
  const h = build();
  h.script.phone = { displayPhoneNumber: "+55 62 1", status: "PENDING", isPinEnabled: false };
  h.script.registerResult = { ok: false, code: "meta_rejected" };
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  h.script.registerResult = { ok: true };
  const refresh = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(refresh.status, "connected");
});

test("erro 133016 (10 registros/72 h): bloqueia novas tentativas por 72 h e não promove", async () => {
  const h = build();
  h.script.phone = { displayPhoneNumber: "+55 62 1", status: "PENDING", isPinEnabled: false };
  h.script.registerResult = { ok: false, code: "meta_rejected", metaCode: META_REGISTRATION_RATE_LIMIT };
  const first = await body(await h.call(complete(await startFor(h, "Bearer jwt-a"))));
  assert.equal(first.reason, "phone_registration_rate_limited");
  const until = h.connections.get("user-a")!.setupState.rate_limited_until!;
  assert.equal(Date.parse(until) - NOW.getTime(), 72 * 3600 * 1000);

  h.events.length = 0;
  const again = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(again.reason, "phone_registration_rate_limited");
  assert.ok(!h.events.includes("meta:register"), "não tenta registrar durante o bloqueio");

  h.advance(73 * 3600 * 1000);
  h.script.registerResult = { ok: true };
  const later = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(later.status, "connected");
});

test("margem de segurança: 8 tentativas nas últimas 72 h impedem novo registro", async () => {
  const h = build();
  h.script.phone = { displayPhoneNumber: "+55 62 1", status: "PENDING", isPinEnabled: false };
  h.script.report = { confirmation: "approved", reminder: "pending" };
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  const conn = h.connections.get("user-a")!;
  conn.setupState = {
    ...conn.setupState,
    register_attempts: Array.from({ length: 8 }, (_, i) => new Date(NOW.getTime() - i * 3600_000).toISOString()),
  };
  h.events.length = 0;
  const res = await body(await h.call({ action: "status" }, "Bearer jwt-a"));
  assert.equal(res.reason, "phone_registration_rate_limited");
  assert.ok(!h.events.includes("meta:register"));
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
