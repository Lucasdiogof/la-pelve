import { test } from "node:test";
import assert from "node:assert/strict";
import { readConnectConfig } from "./config.ts";
import { createConnectHandler, readinessFrom, sha256Hex, type ConnectStore, type ConnectionRow } from "./handler.ts";
import type { MetaOnboarding, TemplatesReport } from "./meta_onboarding.ts";

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

function makeStore() {
  const attempts = new Map<string, { user: string; used: boolean }>();
  const connections = new Map<string, ConnectionRow & { user: string; token?: string }>();
  const phoneOwners = new Map<string, string>();
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
      const owner = phoneOwners.get(i.phoneNumberId);
      if (owner && owner !== i.userId) return { ok: false, code: "phone_in_use" };
      const existing = connections.get(i.userId);
      if (existing?.status === "connected" && existing.phoneNumberId !== i.phoneNumberId) {
        return { ok: false, code: "active_connection" };
      }
      const id = existing?.id ?? `conn-${++seq}`;
      connections.set(i.userId, {
        id,
        user: i.userId,
        status: i.status,
        wabaId: i.wabaId,
        phoneNumberId: i.phoneNumberId,
        displayPhoneNumber: i.displayPhoneNumber,
        token: existing?.token,
      });
      phoneOwners.set(i.phoneNumberId, i.userId);
      return { ok: true, id };
    },
    async setAccessToken(id, token) {
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
      const c = connections.get(user);
      if (c) {
        c.status = "disconnected";
        c.token = undefined;
      }
      return true;
    },
  };
  return { store, attempts, connections };
}

function makeMeta(overrides: Partial<MetaOnboarding> = {}, report?: TemplatesReport) {
  const calls: string[] = [];
  const meta: MetaOnboarding = {
    async exchangeCode() {
      calls.push("exchange");
      return { ok: true, accessToken: SECRET_TOKEN };
    },
    async getPhoneNumber() {
      return { ok: true, displayPhoneNumber: "+55 62 99999-0000" };
    },
    async phoneBelongsToWaba() {
      return { ok: true, belongs: true };
    },
    async subscribeApp() {
      calls.push("subscribe");
      return { ok: true };
    },
    async unsubscribeApp() {
      calls.push("unsubscribe");
      return { ok: true };
    },
    async registerPhone() {
      calls.push("register");
      return { ok: true };
    },
    async ensureTemplates() {
      return { ok: true, report: report ?? { confirmation: "approved", reminder: "approved" } };
    },
    ...overrides,
  };
  return { meta, calls };
}

function build(opts: { meta?: MetaOnboarding; users?: Record<string, string> } = {}) {
  const s = makeStore();
  const m = opts.meta ? { meta: opts.meta, calls: [] as string[] } : makeMeta();
  const logs: string[] = [];
  const users = opts.users ?? { "Bearer jwt-a": "user-a", "Bearer jwt-b": "user-b" };
  const handler = createConnectHandler({
    config,
    store: s.store,
    meta: () => m.meta,
    authenticate: async (auth) => (auth ? (users[auth] ?? null) : null),
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
  return { ...s, ...m, call, logs };
}

async function startFor(h: ReturnType<typeof build>, auth: string): Promise<string> {
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

test("config: sem a chave/segredos a conexão fica desligada e responde not_configured", async () => {
  assert.equal(readConnectConfig(() => undefined).enabled, false);
  const partial = readConnectConfig((n) => ({ ...env, META_ES_CONFIG_ID: "" })[n]);
  assert.deepEqual(!partial.enabled && partial.missing, ["META_ES_CONFIG_ID"]);
  const off = createConnectHandler({
    config: readConnectConfig(() => undefined),
    store: makeStore().store,
    meta: () => makeMeta().meta,
    authenticate: async (auth) => (auth ? "user-a" : null),
    log: () => {},
  });
  const res = await off(
    new Request("https://x.test", { method: "POST", headers: { authorization: "x" }, body: JSON.stringify({ action: "start" }) }),
  );
  assert.equal(res.status, 503);
  assert.deepEqual(await res.json(), { ok: false, error: "not_configured" });
  const avail = await off(
    new Request("https://x.test", { method: "POST", headers: { authorization: "x" }, body: JSON.stringify({ action: "availability" }) }),
  );
  assert.deepEqual(await avail.json(), { ok: true, enabled: false });
  const anon = await off(new Request("https://x.test", { method: "POST", body: JSON.stringify({ action: "availability" }) }));
  assert.equal((await anon.json() as { error: string }).error, "unauthorized");
});

test("start exige sessão; devolve URL HTTPS com state só no fragmento", async () => {
  const h = build();
  assert.equal((await h.call({ action: "start" })).status, 401);
  assert.equal((await h.call({ action: "start" }, "Bearer falso")).status, 401);
  const res = await h.call({ action: "start" }, "Bearer jwt-a");
  const body = (await res.json()) as { connect_url: string };
  const url = new URL(body.connect_url);
  assert.equal(url.protocol, "https:");
  assert.equal(url.search, "");
  assert.match(url.hash, /^#state=[0-9a-f]{64}$/);
  // só o hash fica guardado
  const state = url.hash.slice(7);
  assert.equal(h.attempts.has(state), false);
  assert.equal(h.attempts.has(await sha256Hex(state)), true);
});

test("fluxo completo: troca o code no servidor, grava token e conexão da dona do state", async () => {
  const h = build();
  const state = await startFor(h, "Bearer jwt-a");
  const res = await h.call(complete(state));
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { ok: true, status: "connected" });
  assert.deepEqual(h.calls, ["exchange", "subscribe", "register"]);
  const conn = h.connections.get("user-a")!;
  assert.equal(conn.status, "connected");
  assert.equal(conn.phoneNumberId, "222222222222");
  assert.equal(conn.token, SECRET_TOKEN);
  assert.equal(h.connections.has("user-b"), false);
  assert.ok(!h.logs.join("\n").includes(SECRET_TOKEN), "token nunca em log");
});

test("replay: o mesmo state não completa duas vezes", async () => {
  const h = build();
  const state = await startFor(h, "Bearer jwt-a");
  assert.equal((await h.call(complete(state))).status, 200);
  const again = await h.call(complete(state));
  assert.equal(again.status, 410);
  assert.deepEqual(h.calls.filter((c) => c === "exchange").length, 1);
});

test("state inventado/malformado não troca nada na Meta", async () => {
  const h = build();
  assert.equal((await h.call(complete("zzz"))).status, 400);
  assert.equal((await h.call(complete("a".repeat(64)))).status, 410);
  assert.deepEqual(h.calls, []);
});

test("state de A nunca grava na conta de B (cada state é da própria profissional)", async () => {
  const h = build();
  const stateA = await startFor(h, "Bearer jwt-a");
  const stateB = await startFor(h, "Bearer jwt-b");
  assert.equal((await h.call(complete(stateA, { phone_number_id: "333333333333" }))).status, 200);
  assert.equal(h.connections.get("user-a")!.phoneNumberId, "333333333333");
  assert.equal((await h.call(complete(stateB, { phone_number_id: "444444444444" }))).status, 200);
  assert.equal(h.connections.get("user-b")!.phoneNumberId, "444444444444");
  assert.notEqual(h.connections.get("user-a")!.token, undefined);
});

test("duas profissionais não compartilham o mesmo número", async () => {
  const h = build();
  assert.equal((await h.call(complete(await startFor(h, "Bearer jwt-a")))).status, 200);
  const res = await h.call(complete(await startFor(h, "Bearer jwt-b")));
  assert.equal(res.status, 409);
  assert.deepEqual(await res.json(), { ok: false, error: "phone_in_use" });
  assert.equal(h.connections.has("user-b"), false);
});

test("conexão ativa não é trocada sem desconectar antes", async () => {
  const h = build();
  assert.equal((await h.call(complete(await startFor(h, "Bearer jwt-a")))).status, 200);
  const res = await h.call(complete(await startFor(h, "Bearer jwt-a"), { phone_number_id: "555555555555" }));
  assert.equal(res.status, 409);
  assert.equal(h.connections.get("user-a")!.phoneNumberId, "222222222222");
});

test("ids vindos do navegador só valem se o token enxerga o número na WABA", async () => {
  const { meta } = makeMeta({ phoneBelongsToWaba: async () => ({ ok: true, belongs: false }) });
  const h = build({ meta });
  const res = await h.call(complete(await startFor(h, "Bearer jwt-a")));
  assert.equal(res.status, 403);
  assert.equal(h.connections.size, 0);
});

test("falha da troca de code na Meta: nada é gravado e o erro é genérico", async () => {
  const { meta } = makeMeta({ exchangeCode: async () => ({ ok: false, code: "meta_rejected" }) });
  const h = build({ meta });
  const res = await h.call(complete(await startFor(h, "Bearer jwt-a")));
  assert.equal(res.status, 502);
  assert.deepEqual(await res.json(), { ok: false, error: "exchange_failed" });
  assert.equal(h.connections.size, 0);
});

test("templates ainda em análise: conexão fica pendente, não conectada", async () => {
  const { meta } = makeMeta({}, { confirmation: "approved", reminder: "pending" });
  const h = build({ meta });
  const res = await h.call(complete(await startFor(h, "Bearer jwt-a")));
  assert.deepEqual(await res.json(), { ok: true, status: "pending" });
  assert.equal(h.connections.get("user-a")!.status, "pending");
});

test("coexistência (WhatsApp Business App) não registra o número na Cloud API", async () => {
  const h = build();
  const state = await startFor(h, "Bearer jwt-a");
  await h.call(complete(state, { event: "FINISH_WHATSAPP_BUSINESS_APP_ONBOARDING" }));
  assert.ok(!h.calls.includes("register"));
});

test("eventos não suportados e ids inválidos são recusados antes de consumir o state", async () => {
  const h = build();
  const state = await startFor(h, "Bearer jwt-a");
  assert.equal((await h.call(complete(state, { event: "CANCEL" }))).status, 400);
  assert.equal((await h.call(complete(state, { waba_id: "abc" }))).status, 400);
  assert.equal((await h.call(complete(state))).status, 200, "state continuava válido");
});

test("status: pendente vira conectado quando os templates são aprovados", async () => {
  let report: TemplatesReport = { confirmation: "approved", reminder: "pending" };
  const { meta } = makeMeta({ ensureTemplates: async () => ({ ok: true, report }) });
  const h = build({ meta });
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  assert.equal(h.connections.get("user-a")!.status, "pending");
  let res = await h.call({ action: "status" }, "Bearer jwt-a");
  assert.deepEqual(await res.json(), { ok: true, status: "pending", reason: "templates_pending" });
  report = { confirmation: "approved", reminder: "approved" };
  res = await h.call({ action: "status" }, "Bearer jwt-a");
  assert.deepEqual(await res.json(), { ok: true, status: "connected" });
  assert.equal((await h.call({ action: "status" })).status, 401);
});

test("disconnect: tira o webhook, apaga o token e só afeta a própria conexão", async () => {
  const h = build();
  await h.call(complete(await startFor(h, "Bearer jwt-a")));
  assert.equal((await h.call({ action: "disconnect" })).status, 401);
  const res = await h.call({ action: "disconnect" }, "Bearer jwt-b");
  assert.equal(res.status, 200, "B não tem conexão: no-op");
  assert.equal(h.connections.get("user-a")!.status, "connected");
  await h.call({ action: "disconnect" }, "Bearer jwt-a");
  const conn = h.connections.get("user-a")!;
  assert.equal(conn.status, "disconnected");
  assert.equal(conn.token, undefined);
  assert.ok(h.calls.includes("unsubscribe"));
});

test("config da página só responde para state válido; JSON/método inválidos", async () => {
  const h = build();
  const state = await startFor(h, "Bearer jwt-a");
  const ok = await h.call({ action: "config", state });
  assert.deepEqual(await ok.json(), {
    ok: true,
    app_id: "1234567890",
    config_id: "9876543210",
    graph_version: "v25.0",
  });
  assert.equal((await h.call({ action: "config", state: "b".repeat(64) })).status, 410);
  assert.equal((await h.call({ action: "nope" })).status, 400);
  const get = await build().call({}, undefined);
  assert.equal(get.status, 400);
});

test("readinessFrom classifica os estados dos templates", () => {
  assert.equal(readinessFrom({ confirmation: "approved", reminder: "approved" }).ready, true);
  assert.equal(readinessFrom({ confirmation: "missing", reminder: "approved" }).code, "templates_pending");
  assert.equal(readinessFrom({ confirmation: "rejected", reminder: "approved" }).code, "templates_rejected");
});
