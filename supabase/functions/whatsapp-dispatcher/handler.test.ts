import { test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { readDispatcherConfig } from "./config.ts";
import { createDispatcherHandler } from "./handler.ts";
import type { PipelineSummary } from "../_shared/pipeline/run_pipeline.ts";

const TOKEN = `dispatcher-${randomUUID()}-${randomUUID()}`;
const URL_BASE = "https://example.test/functions/v1/whatsapp-dispatcher";

const env: Record<string, string> = {
  WHATSAPP_DISPATCHER_TOKEN: TOKEN,
  WHATSAPP_GRAPH_API_VERSION: "v23.0",
  WHATSAPP_TEMPLATE_LANGUAGE: "pt_BR",
  WHATSAPP_TEMPLATE_APPOINTMENT_12H: "la_pelve_confirmacao",
};

const summary: PipelineSummary = {
  materialization: { error: true },
  reconciliation: { error: true },
  dispatch: { claimed: 0, sent: 0, retried: 0, failed: 0, unknownOutcome: 0, cancelled: 0, deferred: 0, leaseLost: 0, errors: 0 },
};

function post(auth?: string) {
  return new Request(URL_BASE, { method: "POST", headers: auth ? { authorization: auth } : {} });
}

test("config: lê templates configurados; tipo sem template fica de fora", () => {
  const result = readDispatcherConfig((n) => env[n]);
  assert.ok(result.ok);
  assert.deepEqual(result.ok && result.config.templates, {
    languageCode: "pt_BR",
    names: { appointment_12h: "la_pelve_confirmacao" },
  });
});

test("config: versão da Graph API, idioma e token são obrigatórios (sem default)", () => {
  const result = readDispatcherConfig(() => undefined);
  assert.equal(result.ok, false);
  assert.deepEqual(!result.ok && result.missing.sort(), [
    "WHATSAPP_DISPATCHER_TOKEN",
    "WHATSAPP_GRAPH_API_VERSION",
    "WHATSAPP_TEMPLATE_LANGUAGE",
  ]);
  const badTemplate = readDispatcherConfig((n) => ({ ...env, WHATSAPP_TEMPLATE_APPOINTMENT_12H: "Nome Com Espaço" })[n]);
  assert.equal(badTemplate.ok, false);
});

test("sem token certo: 401 e o pipeline não roda", async () => {
  let runs = 0;
  const handler = createDispatcherHandler({
    config: readDispatcherConfig((n) => env[n]),
    runPipeline: async () => {
      runs++;
      return summary;
    },
    log: () => {},
  });
  for (const auth of [undefined, "Bearer errado", `Basic ${TOKEN}`, TOKEN, "Bearer "]) {
    assert.equal((await handler(post(auth))).status, 401, String(auth));
  }
  assert.equal(runs, 0);
});

test("configuração incompleta nunca roda, mesmo com algum token", async () => {
  let runs = 0;
  const handler = createDispatcherHandler({
    config: readDispatcherConfig((n) => ({ ...env, WHATSAPP_GRAPH_API_VERSION: "" })[n]),
    runPipeline: async () => {
      runs++;
      return summary;
    },
    log: () => {},
  });
  assert.equal((await handler(post(`Bearer ${TOKEN}`))).status, 401);
  assert.equal(runs, 0);
});

test("token certo: roda e devolve só contagens", async () => {
  const logs: unknown[] = [];
  const handler = createDispatcherHandler({
    config: readDispatcherConfig((n) => env[n]),
    runPipeline: async () => summary,
    log: (event, data) => logs.push({ event, data }),
  });
  const res = await handler(post(`Bearer ${TOKEN}`));
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), summary);
  assert.ok(!JSON.stringify(logs).includes(TOKEN));
});

test("GET não é aceito; falha do pipeline -> 500 sem detalhes", async () => {
  const handler = createDispatcherHandler({
    config: readDispatcherConfig((n) => env[n]),
    runPipeline: async () => {
      throw new Error("detalhe interno +5562911110001");
    },
    log: () => {},
  });
  assert.equal((await handler(new Request(URL_BASE))).status, 405);
  const res = await handler(post(`Bearer ${TOKEN}`));
  assert.equal(res.status, 500);
  assert.ok(!(await res.text()).includes("5562911110001"));
});
