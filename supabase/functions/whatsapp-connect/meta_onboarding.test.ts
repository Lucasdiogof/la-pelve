import { test } from "node:test";
import assert from "node:assert/strict";
import { readConnectConfig } from "./config.ts";
import { createMetaOnboarding, templateDefinitions } from "./meta_onboarding.ts";

const cfg = readConnectConfig(
  (n) =>
    ({
      WHATSAPP_SELF_CONNECT_ENABLED: "true",
      META_APP_ID: "1234567890",
      META_ES_CONFIG_ID: "9876543210",
      WHATSAPP_APP_SECRET: "app-secret-app-secret-123",
      WHATSAPP_GRAPH_API_VERSION: "v25.0",
      WHATSAPP_TEMPLATE_LANGUAGE: "pt_BR",
      WHATSAPP_CONNECT_PAGE_URL: "https://lapelve.example/c.html",
    })[n],
);
assert.ok(cfg.enabled);
const config = cfg.enabled ? cfg.config : (undefined as never);

function fakeFetch(handler: (url: string, init: RequestInit) => Response) {
  const calls: Array<{ url: string; init: RequestInit }> = [];
  const fn = (async (url: string, init: RequestInit) => {
    calls.push({ url, init });
    return handler(url, init);
  }) as unknown as typeof fetch;
  return { fn, calls };
}

const jsonRes = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

test("exchangeCode: segredo e code vão no corpo POST, nunca na URL", async () => {
  const f = fakeFetch(() => jsonRes({ access_token: "EAAB-token-0000000000000" }));
  const meta = createMetaOnboarding({ config, fetchFn: f.fn });
  const result = await meta.exchangeCode("the-code");
  assert.deepEqual(result, { ok: true, accessToken: "EAAB-token-0000000000000" });
  assert.equal(f.calls[0].url, "https://graph.facebook.com/v25.0/oauth/access_token");
  assert.equal(f.calls[0].init.method, "POST");
  const body = String(f.calls[0].init.body);
  assert.match(body, /client_secret=app-secret-app-secret-123/);
  assert.match(body, /code=the-code/);
});

test("erros da Meta viram só códigos próprios (sem texto livre)", async () => {
  const rejected = createMetaOnboarding({ config, fetchFn: fakeFetch(() => jsonRes({ error: { message: "segredo vazado?" } }, 400)).fn });
  assert.deepEqual(await rejected.exchangeCode("c"), { ok: false, code: "meta_rejected" });
  const down = createMetaOnboarding({
    config,
    fetchFn: (async () => {
      throw new Error("ECONNRESET");
    }) as unknown as typeof fetch,
  });
  assert.deepEqual(await down.exchangeCode("c"), { ok: false, code: "meta_unreachable" });
  const bad = createMetaOnboarding({ config, fetchFn: fakeFetch(() => jsonRes({ nope: 1 })).fn });
  assert.deepEqual(await bad.exchangeCode("c"), { ok: false, code: "meta_invalid_response" });
});

test("token só no header Authorization", async () => {
  const f = fakeFetch(() => jsonRes({ data: [{ id: "222222222222" }] }));
  const meta = createMetaOnboarding({ config, fetchFn: f.fn });
  const r = await meta.phoneBelongsToWaba("TOKEN-123456789012345", "111111111111", "222222222222");
  assert.deepEqual(r, { ok: true, belongs: true });
  assert.ok(!f.calls[0].url.includes("TOKEN"));
  assert.equal((f.calls[0].init.headers as Record<string, string>).authorization, "Bearer TOKEN-123456789012345");
  const other = createMetaOnboarding({ config, fetchFn: fakeFetch(() => jsonRes({ data: [{ id: "999" }] })).fn });
  assert.deepEqual(await other.phoneBelongsToWaba("TOKEN-123456789012345", "1", "222222222222"), { ok: true, belongs: false });
});

test("ensureTemplates: usa os aprovados e cria os que faltam com os textos aprovados", async () => {
  const f = fakeFetch((url, init) => {
    if (init.method === "GET") {
      return jsonRes({ data: [{ name: "appointment_confirmation", language: "pt_BR", status: "APPROVED" }] });
    }
    return jsonRes({ id: "1", status: "PENDING" });
  });
  const meta = createMetaOnboarding({ config, fetchFn: f.fn });
  const r = await meta.ensureTemplates("TOKEN-123456789012345", "111111111111");
  assert.deepEqual(r, { ok: true, report: { confirmation: "approved", reminder: "pending" } });
  const posts = f.calls.filter((c) => c.init.method === "POST");
  assert.equal(posts.length, 1);
  const created = JSON.parse(String(posts[0].init.body));
  assert.equal(created.name, "appointment_12h");
  assert.equal(created.category, "UTILITY");
  assert.deepEqual(created.components[1].buttons, [{ type: "QUICK_REPLY", text: "Confirmar" }]);
});

test("textos dos templates são exatamente os aprovados", () => {
  const [confirmation, reminder] = templateDefinitions(config);
  assert.equal(confirmation.body.components[0].text, "Olá, {{1}}! 👋\nSua consulta está agendada para o dia {{2}}, às {{3}}. Obrigado!");
  assert.equal(
    reminder.body.components[0].text,
    "Olá, {{1}}! Podemos confirmar seu atendimento no dia {{2}}, às {{3}}? Se sim, toque em Confirmar abaixo.",
  );
});

test("estados REJECTED/PAUSED são reportados como rejeitados", async () => {
  const f = fakeFetch(() =>
    jsonRes({
      data: [
        { name: "appointment_confirmation", language: "pt_BR", status: "REJECTED" },
        { name: "appointment_12h", language: "pt_BR", status: "PENDING" },
      ],
    }),
  );
  const r = await createMetaOnboarding({ config, fetchFn: f.fn }).ensureTemplates("TOKEN-123456789012345", "1");
  assert.deepEqual(r, { ok: true, report: { confirmation: "rejected", reminder: "pending" } });
});
