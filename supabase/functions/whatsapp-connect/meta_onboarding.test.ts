import { test } from "node:test";
import assert from "node:assert/strict";
import { readConnectConfig } from "./config.ts";
import {
  CONFIRMATION_TEMPLATE_TEXT,
  REMINDER_TEMPLATE_TEXT,
  createMetaOnboarding,
  templateDefinitions,
} from "./meta_onboarding.ts";

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
const TOKEN = "TOKEN-123456789012345";

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

test("exchangeCode: segue o contrato oficial (GET /oauth/access_token com client_id, client_secret e code)", async () => {
  const f = fakeFetch(() => jsonRes({ access_token: "EAAB-token-0000000000000" }));
  const result = await createMetaOnboarding({ config, fetchFn: f.fn }).exchangeCode("the-code");
  assert.deepEqual(result, { ok: true, accessToken: "EAAB-token-0000000000000" });
  assert.equal(f.calls[0].init.method, "GET");
  const url = new URL(f.calls[0].url);
  assert.equal(url.origin + url.pathname, "https://graph.facebook.com/v25.0/oauth/access_token");
  assert.equal(url.searchParams.get("client_id"), "1234567890");
  assert.equal(url.searchParams.get("client_secret"), "app-secret-app-secret-123");
  assert.equal(url.searchParams.get("code"), "the-code");
  assert.equal(f.calls[0].init.body, undefined);
});

test("exchangeCode aceita a resposta em texto puro descrita na documentação", async () => {
  const f = fakeFetch(() => new Response("EAAB-token-0000000000000", { status: 200 }));
  const result = await createMetaOnboarding({ config, fetchFn: f.fn }).exchangeCode("c");
  assert.deepEqual(result, { ok: true, accessToken: "EAAB-token-0000000000000" });
  const junk = fakeFetch(() => new Response("<html>nope</html>", { status: 200 }));
  assert.deepEqual(await createMetaOnboarding({ config, fetchFn: junk.fn }).exchangeCode("c"), {
    ok: false,
    code: "meta_invalid_response",
  });
});

test("erros da Meta viram só códigos próprios; a URL com o segredo nunca vai no resultado", async () => {
  const rejected = createMetaOnboarding({
    config,
    fetchFn: fakeFetch(() => jsonRes({ error: { message: "segredo vazado?", code: 190 } }, 400)).fn,
  });
  const result = await rejected.exchangeCode("c");
  assert.deepEqual(result, { ok: false, code: "meta_rejected" });
  assert.ok(!JSON.stringify(result).includes("app-secret"));
  const down = createMetaOnboarding({
    config,
    fetchFn: (async () => {
      throw new Error("ECONNRESET https://graph.facebook.com/?client_secret=app-secret");
    }) as unknown as typeof fetch,
  });
  const failed = await down.exchangeCode("c");
  assert.deepEqual(failed, { ok: false, code: "meta_unreachable" });
});

test("registerPhone expõe só o código numérico do erro (ex.: 133016)", async () => {
  const f = fakeFetch(() => jsonRes({ error: { code: 133016, message: "texto livre" } }, 400));
  const r = await createMetaOnboarding({ config, fetchFn: f.fn }).registerPhone(TOKEN, "222222222222", "123456");
  assert.deepEqual(r, { ok: false, code: "meta_rejected", metaCode: 133016 });
  assert.deepEqual(JSON.parse(String(f.calls[0].init.body)), { messaging_product: "whatsapp", pin: "123456" });
});

test("token só no header Authorization, nunca na URL", async () => {
  const f = fakeFetch(() => jsonRes({ data: [{ id: "222222222222" }] }));
  const r = await createMetaOnboarding({ config, fetchFn: f.fn }).phoneBelongsToWaba(TOKEN, "111111111111", "222222222222");
  assert.deepEqual(r, { ok: true, belongs: true });
  assert.ok(!f.calls[0].url.includes("TOKEN"));
  assert.equal((f.calls[0].init.headers as Record<string, string>).authorization, `Bearer ${TOKEN}`);
});

test("phoneBelongsToWaba segue a paginação (número na 2ª página)", async () => {
  const f = fakeFetch((url) =>
    url.includes("after=P2")
      ? jsonRes({ data: [{ id: "222222222222" }] })
      : jsonRes({
          data: [{ id: "999" }],
          paging: { next: "https://graph.facebook.com/v25.0/111111111111/phone_numbers?fields=id&limit=100&after=P2" },
        }),
  );
  const r = await createMetaOnboarding({ config, fetchFn: f.fn }).phoneBelongsToWaba(TOKEN, "111111111111", "222222222222");
  assert.deepEqual(r, { ok: true, belongs: true });
  assert.equal(f.calls.length, 2);
});

test("paginação: ignora next fora de graph.facebook.com e falha se o limite de páginas estoura", async () => {
  const evil = fakeFetch(() => jsonRes({ data: [{ id: "1" }], paging: { next: "https://evil.example/steal" } }));
  const r1 = await createMetaOnboarding({ config, fetchFn: evil.fn }).phoneBelongsToWaba(TOKEN, "1", "222222222222");
  assert.deepEqual(r1, { ok: true, belongs: false });
  assert.equal(evil.calls.length, 1, "não seguiu a URL estranha");

  const endless = fakeFetch(() =>
    jsonRes({ data: [{ id: "1" }], paging: { next: "https://graph.facebook.com/v25.0/1/phone_numbers?after=x" } }),
  );
  const r2 = await createMetaOnboarding({ config, fetchFn: endless.fn, maxPages: 3 }).phoneBelongsToWaba(TOKEN, "1", "222222222222");
  assert.equal(r2.ok, false, "resultado incompleto nunca vira 'não pertence'");
  assert.equal(endless.calls.length, 3);
});

test("ensureTemplates acha template existente na 2ª página (não recria) e cria só o que falta", async () => {
  const f = fakeFetch((url, init) => {
    if (init.method === "POST") return jsonRes({ id: "1", status: "PENDING" });
    if (url.includes("name=appointment_confirmation")) {
      return url.includes("after=P2")
        ? jsonRes({ data: [{ name: "appointment_confirmation", language: "pt_BR", status: "APPROVED" }] })
        : jsonRes({
            data: [{ name: "appointment_confirmation", language: "en_US", status: "APPROVED" }],
            paging: { next: "https://graph.facebook.com/v25.0/111/message_templates?name=appointment_confirmation&after=P2" },
          });
    }
    return jsonRes({ data: [] });
  });
  const r = await createMetaOnboarding({ config, fetchFn: f.fn }).ensureTemplates(TOKEN, "111111111111");
  assert.deepEqual(r, { ok: true, report: { confirmation: "approved", reminder: "pending" } });
  const posts = f.calls.filter((c) => c.init.method === "POST");
  assert.equal(posts.length, 1);
  const created = JSON.parse(String(posts[0].init.body));
  assert.equal(created.name, "appointment_12h");
  assert.equal(created.category, "UTILITY");
  assert.equal(created.allow_category_change, false);
  assert.deepEqual(created.components[1].buttons, [{ type: "QUICK_REPLY", text: "Confirmar" }]);
});

test("textos dos templates: exatamente os aprovados, incluindo as DUAS quebras de linha do aviso", () => {
  const [confirmation, reminder] = templateDefinitions(config);
  assert.equal(
    confirmation.body.components[0].text,
    "Olá, {{1}}! 👋\n\nSua consulta está agendada para o dia {{2}}, às {{3}}. Obrigado!",
  );
  assert.equal(CONFIRMATION_TEMPLATE_TEXT, confirmation.body.components[0].text);
  assert.equal(
    reminder.body.components[0].text,
    "Olá, {{1}}! Podemos confirmar seu atendimento no dia {{2}}, às {{3}}? Se sim, toque em Confirmar abaixo.",
  );
  assert.equal(REMINDER_TEMPLATE_TEXT, reminder.body.components[0].text);
});

test("estados REJECTED/PAUSED são reportados como rejeitados", async () => {
  const f = fakeFetch((url) =>
    jsonRes({
      data: [
        url.includes("appointment_confirmation")
          ? { name: "appointment_confirmation", language: "pt_BR", status: "REJECTED" }
          : { name: "appointment_12h", language: "pt_BR", status: "PENDING" },
      ],
    }),
  );
  const r = await createMetaOnboarding({ config, fetchFn: f.fn }).ensureTemplates(TOKEN, "1");
  assert.deepEqual(r, { ok: true, report: { confirmation: "rejected", reminder: "pending" } });
});

test("getPhoneInfo e getAccountHealth classificam os campos retornados", async () => {
  const phone = fakeFetch(() => jsonRes({ display_phone_number: "+55 62 99999-0000", status: "CONNECTED", is_pin_enabled: true }));
  assert.deepEqual(await createMetaOnboarding({ config, fetchFn: phone.fn }).getPhoneInfo(TOKEN, "222222222222"), {
    ok: true,
    info: { displayPhoneNumber: "+55 62 99999-0000", status: "CONNECTED", isPinEnabled: true },
  });
  for (const [raw, expected] of [
    ["AVAILABLE", "available"],
    ["LIMITED", "limited"],
    ["BLOCKED", "blocked"],
    [undefined, "unknown"],
  ] as const) {
    const f = fakeFetch(() => jsonRes({ health_status: raw ? { can_send_message: raw } : undefined }));
    assert.deepEqual(await createMetaOnboarding({ config, fetchFn: f.fn }).getAccountHealth(TOKEN, "1"), {
      ok: true,
      health: expected,
    });
  }
});

test("debugToken: app token só no header, token do usuário na query; devolve validade e expiração", async () => {
  const f = fakeFetch(() => jsonRes({ data: { is_valid: true, expires_at: 1790000000 } }));
  const result = await createMetaOnboarding({ config, fetchFn: f.fn }).debugToken(TOKEN);
  assert.ok(result.ok);
  if (result.ok) {
    assert.equal(result.info.valid, true);
    assert.equal(result.info.expiresAt?.getTime(), 1790000000 * 1000);
  }
  const url = new URL(f.calls[0].url);
  assert.equal(url.pathname, "/v25.0/debug_token");
  assert.equal(url.searchParams.get("input_token"), TOKEN);
  assert.equal(url.searchParams.has("access_token"), false);
  assert.equal(url.searchParams.has("client_secret"), false);
  const headers = f.calls[0].init.headers as Record<string, string>;
  assert.equal(headers.authorization, "Bearer 1234567890|app-secret-app-secret-123");
});

test("debugToken: expires_at 0 = sem expiração; token inválido; resposta fora do formato", async () => {
  const never = fakeFetch(() => jsonRes({ data: { is_valid: true, expires_at: 0 } }));
  const a = await createMetaOnboarding({ config, fetchFn: never.fn }).debugToken(TOKEN);
  assert.ok(a.ok && a.info.valid && a.info.expiresAt === null);
  const invalid = fakeFetch(() => jsonRes({ data: { is_valid: false } }));
  const b = await createMetaOnboarding({ config, fetchFn: invalid.fn }).debugToken(TOKEN);
  assert.ok(b.ok && !b.info.valid);
  const junk = fakeFetch(() => jsonRes({ data: {} }));
  assert.deepEqual(await createMetaOnboarding({ config, fetchFn: junk.fn }).debugToken(TOKEN), {
    ok: false,
    code: "meta_invalid_response",
  });
});
