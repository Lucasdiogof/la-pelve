// Adapter da Cloud API com fetch MOCKADO (nunca rede). Token fictício.

import { test } from "node:test";
import assert from "node:assert/strict";
import { createMetaWhatsappProvider } from "./meta_provider.ts";
import type { MetaTemplateMessage, ProviderSendRequest } from "./types.ts";

const TOKEN = "tok_teste_meta_provider_0123456789";

const message: MetaTemplateMessage = {
  messaging_product: "whatsapp",
  recipient_type: "individual",
  to: "5562911110001",
  type: "template",
  template: { name: "la_pelve_confirmacao", language: { code: "pt_BR" }, components: [] },
};

const request: ProviderSendRequest = { phoneNumberId: "123456789012345", accessToken: TOKEN, message };

interface Call {
  url: string;
  init: RequestInit;
}

function mockFetch(respond: () => Response | Promise<Response>) {
  const calls: Call[] = [];
  const fetchFn = (async (url: string | URL | Request, init?: RequestInit) => {
    calls.push({ url: String(url), init: init ?? {} });
    return await respond();
  }) as typeof fetch;
  return { fetchFn, calls };
}

function jsonResponse(status: number, body: unknown, headers: Record<string, string> = {}) {
  return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json", ...headers } });
}

function provider(fetchFn: typeof fetch, timeoutMs = 1000) {
  return createMetaWhatsappProvider({ graphApiVersion: "v23.0", fetchFn, timeoutMs });
}

test("request: URL com versão e phone_number_id, POST, JSON, token só no header", async () => {
  const { fetchFn, calls } = mockFetch(() => jsonResponse(200, { messages: [{ id: "wamid.ABC" }] }));
  await provider(fetchFn).sendTemplate(request);
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, "https://graph.facebook.com/v23.0/123456789012345/messages");
  assert.equal(calls[0].init.method, "POST");
  const headers = calls[0].init.headers as Record<string, string>;
  assert.equal(headers.Authorization, `Bearer ${TOKEN}`);
  assert.equal(headers["Content-Type"], "application/json");
  assert.deepEqual(JSON.parse(String(calls[0].init.body)), message);
  assert.ok(!calls[0].url.includes(TOKEN), "token nunca na URL");
  assert.ok(!String(calls[0].init.body).includes(TOKEN), "token nunca no corpo");
  assert.ok(calls[0].init.signal instanceof AbortSignal, "timeout explícito");
});

test("2xx com wamid -> sent", async () => {
  const { fetchFn } = mockFetch(() => jsonResponse(200, { messaging_product: "whatsapp", messages: [{ id: "wamid.HBgM" }] }));
  assert.deepEqual(await provider(fetchFn).sendTemplate(request), { kind: "sent", wamid: "wamid.HBgM" });
});

test("400 -> rejected com códigos numéricos, sem texto livre da Meta", async () => {
  const { fetchFn } = mockFetch(() =>
    jsonResponse(400, { error: { message: "(#132001) Template name does not exist +5562911110001", code: 132001, error_subcode: 2494073 } })
  );
  const result = await provider(fetchFn).sendTemplate(request);
  assert.deepEqual(result, {
    kind: "rejected",
    code: "request_rejected",
    httpStatus: 400,
    providerCode: 132001,
    providerSubcode: 2494073,
  });
  assert.ok(!JSON.stringify(result).includes("Template name"));
});

test("401 / código 190 -> rejected auth_error", async () => {
  for (const response of [
    () => jsonResponse(401, { error: { code: 190, message: "Invalid OAuth access token" } }),
    () => jsonResponse(400, { error: { code: 190 } }),
  ]) {
    const { fetchFn } = mockFetch(response);
    const result = await provider(fetchFn).sendTemplate(request);
    assert.equal(result.kind, "rejected");
    assert.equal(result.kind === "rejected" && result.code, "auth_error");
  }
});

test("429 -> retryable rate_limited, com Retry-After", async () => {
  const { fetchFn } = mockFetch(() => jsonResponse(429, { error: { code: 130429 } }, { "retry-after": "120" }));
  assert.deepEqual(await provider(fetchFn).sendTemplate(request), {
    kind: "retryable",
    code: "rate_limited",
    httpStatus: 429,
    providerCode: 130429,
    providerSubcode: undefined,
    retryAfterSeconds: 120,
  });
});

test("limite da Meta vindo como 400 (131056) -> retryable", async () => {
  const { fetchFn } = mockFetch(() => jsonResponse(400, { error: { code: 131056 } }));
  const result = await provider(fetchFn).sendTemplate(request);
  assert.equal(result.kind, "retryable");
});

test("500 -> retryable provider_unavailable", async () => {
  const { fetchFn } = mockFetch(() => jsonResponse(500, { error: { code: 1 } }));
  const result = await provider(fetchFn).sendTemplate(request);
  assert.equal(result.kind, "retryable");
  assert.equal(result.kind === "retryable" && result.code, "provider_unavailable");
});

test("timeout -> unknown (pode ter sido enviada; nunca reenviar)", async () => {
  const fetchFn = ((_url: string, init?: RequestInit) =>
    new Promise((_resolve, reject) => {
      init?.signal?.addEventListener("abort", () => {
        const error = new Error("aborted");
        error.name = "AbortError";
        reject(error);
      });
    })) as typeof fetch;
  assert.deepEqual(await provider(fetchFn, 20).sendTemplate(request), { kind: "unknown", code: "timeout" });
});

test("falha de rede -> unknown", async () => {
  const fetchFn = (async () => {
    throw new TypeError("fetch failed");
  }) as typeof fetch;
  assert.deepEqual(await provider(fetchFn).sendTemplate(request), { kind: "unknown", code: "network_error" });
});

test("resposta JSON inválida: 2xx -> unknown; erro -> classificado pelo status", async () => {
  const ok = mockFetch(() => new Response("<html>oops</html>", { status: 200 }));
  assert.deepEqual(await provider(ok.fetchFn).sendTemplate(request), {
    kind: "unknown",
    code: "invalid_provider_response",
    httpStatus: 200,
  });
  const bad = mockFetch(() => new Response("not json", { status: 502 }));
  const result = await provider(bad.fetchFn).sendTemplate(request);
  assert.equal(result.kind, "retryable");
  const noWamid = mockFetch(() => jsonResponse(200, { messages: [] }));
  assert.equal((await provider(noWamid.fetchFn).sendTemplate(request)).kind, "unknown");
});

test("phone_number_id inválido nem chama a Meta", async () => {
  const { fetchFn, calls } = mockFetch(() => jsonResponse(200, {}));
  const result = await provider(fetchFn).sendTemplate({ ...request, phoneNumberId: "../me" });
  assert.equal(result.kind, "rejected");
  assert.equal(calls.length, 0);
});

test("versão da Graph API é obrigatória e validada", () => {
  for (const version of ["", "23.0", "latest", "v23", "v23.0/x"]) {
    assert.throws(() => createMetaWhatsappProvider({ graphApiVersion: version }), /WHATSAPP_GRAPH_API_VERSION/);
  }
});

test("token nunca aparece em nenhum resultado", async () => {
  const responses = [
    () => jsonResponse(200, { messages: [{ id: "wamid.1" }] }),
    () => jsonResponse(400, { error: { code: 100, message: TOKEN } }),
    () => jsonResponse(401, { error: { code: 190, message: `token ${TOKEN} expired` } }),
    () => jsonResponse(500, { error: { message: TOKEN } }),
  ];
  for (const respond of responses) {
    const { fetchFn } = mockFetch(respond);
    assert.ok(!JSON.stringify(await provider(fetchFn).sendTemplate(request)).includes(TOKEN));
  }
});
