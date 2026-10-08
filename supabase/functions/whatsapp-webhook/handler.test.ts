// D. Webhook HTTP (handler puro) com uma porta FALSA com estado, que imita
// a idempotência por wamid da RPC. Os secrets são gerados aleatoriamente
// aqui: nenhum valor real em teste.

import { test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { createWebhookHandler, hmacSha256Hex } from "./handler.ts";
import type { ConfirmationReplyInput, ConfirmationReplyOutcome, ConfirmationReplyPort } from "../_shared/inbound/types.ts";

const VERIFY_TOKEN = `verify-${randomUUID()}`;
const APP_SECRET = `secret-${randomUUID()}`;
const URL_BASE = "https://example.test/functions/v1/whatsapp-webhook";
const TS = "1791460800";

/** Porta falsa: 1ª vez por wamid confirma, as seguintes são 'duplicate'. */
function fakePort(outcome: ConfirmationReplyOutcome = { kind: "processed", result: "confirmed" }) {
  const calls: ConfirmationReplyInput[] = [];
  const seen = new Set<string>();
  const port: ConfirmationReplyPort = {
    async processConfirmationReply(input) {
      calls.push(input);
      if (seen.has(input.wamid)) return { kind: "processed", result: "duplicate" };
      seen.add(input.wamid);
      return outcome;
    },
  };
  return { port, calls };
}

function setup(port: ConfirmationReplyPort, overrides: { appSecret?: string | undefined } = {}) {
  const logs: Array<{ event: string; data: Record<string, unknown> }> = [];
  const handler = createWebhookHandler({
    verifyToken: VERIFY_TOKEN,
    appSecret: "appSecret" in overrides ? overrides.appSecret : APP_SECRET,
    getPort: () => port,
    log: (event, data) => logs.push({ event, data }),
  });
  return { handler, logs };
}

async function signedPost(body: unknown, secret = APP_SECRET): Promise<Request> {
  const raw = typeof body === "string" ? body : JSON.stringify(body);
  return new Request(URL_BASE, {
    method: "POST",
    headers: { "content-type": "application/json", "x-hub-signature-256": `sha256=${await hmacSha256Hex(secret, raw)}` },
    body: raw,
  });
}

function textReply(id: string, body = "Sim, confirmo!", extra: Record<string, unknown> = {}) {
  return {
    object: "whatsapp_business_account",
    entry: [
      {
        id: "waba-1",
        changes: [
          {
            field: "messages",
            value: {
              messaging_product: "whatsapp",
              metadata: { display_phone_number: "556230000000", phone_number_id: "pn-1" },
              messages: [{ id, from: "5562911110001", timestamp: TS, type: "text", text: { body }, ...extra }],
            },
          },
        ],
      },
    ],
  };
}

test("GET com verify token certo devolve o challenge", async () => {
  const { handler } = setup(fakePort().port);
  const res = await handler(
    new Request(`${URL_BASE}?hub.mode=subscribe&hub.verify_token=${VERIFY_TOKEN}&hub.challenge=12345`),
  );
  assert.equal(res.status, 200);
  assert.equal(await res.text(), "12345");
});

test("GET com verify token errado -> 403", async () => {
  const { handler } = setup(fakePort().port);
  const res = await handler(new Request(`${URL_BASE}?hub.mode=subscribe&hub.verify_token=errado&hub.challenge=1`));
  assert.equal(res.status, 403);
});

test("D: POST com assinatura inválida continua rejeitado (401) e nada é processado", async () => {
  const { port, calls } = fakePort();
  const { handler } = setup(port);
  const badSecret = await signedPost(textReply("wamid.in.1"), "outro-secret");
  assert.equal((await handler(badSecret)).status, 401);

  const noHeader = new Request(URL_BASE, { method: "POST", body: JSON.stringify(textReply("wamid.in.1")) });
  assert.equal((await handler(noHeader)).status, 401);

  // Corpo alterado depois de assinado.
  const raw = JSON.stringify(textReply("wamid.in.1"));
  const tampered = new Request(URL_BASE, {
    method: "POST",
    headers: { "x-hub-signature-256": `sha256=${await hmacSha256Hex(APP_SECRET, raw)}` },
    body: raw.replace("Sim, confirmo!", "Sim"),
  });
  assert.equal((await handler(tampered)).status, 401);
  assert.equal(calls.length, 0);
});

test("POST sem WHATSAPP_APP_SECRET configurado é recusado (nunca processa sem assinatura)", async () => {
  const { port, calls } = fakePort();
  const { handler } = setup(port, { appSecret: undefined });
  const res = await handler(new Request(URL_BASE, { method: "POST", body: JSON.stringify(textReply("w")) }));
  assert.equal(res.status, 500);
  assert.equal(calls.length, 0);
});

test("D: evento de delivery/read é ignorado: 200 e nenhuma chamada à porta", async () => {
  const { port, calls } = fakePort();
  const { handler } = setup(port);
  const body = {
    entry: [
      {
        changes: [
          {
            field: "messages",
            value: {
              metadata: { phone_number_id: "pn-1" },
              statuses: [
                { id: "wamid.out.1", status: "delivered", timestamp: TS, recipient_id: "5562911110001" },
                { id: "wamid.out.1", status: "read", timestamp: TS, recipient_id: "5562911110001" },
              ],
            },
          },
        ],
      },
    ],
  };
  const res = await handler(await signedPost(body));
  assert.equal(res.status, 200);
  assert.equal(calls.length, 0);
});

test("D: resposta válida aciona exatamente uma confirmação", async () => {
  const { port, calls } = fakePort();
  const { handler, logs } = setup(port);
  const res = await handler(await signedPost(textReply("wamid.in.1", "Sim, confirmo!", { context: { id: "wamid.out.1" } })));
  assert.equal(res.status, 200);
  assert.equal(calls.length, 1);
  assert.deepEqual(calls[0], {
    wamid: "wamid.in.1",
    phoneNumberId: "pn-1",
    fromE164Candidates: ["+5562911110001"],
    receivedAt: "2026-10-08T12:00:00.000Z",
    messageType: "text",
    contextWamid: "wamid.out.1",
  });
  const processed = logs.find((l) => l.event === "webhook_processed");
  assert.deepEqual(processed?.data.results, { confirmed: 1 });
});

test("D: o mesmo webhook (mesmo wamid) duas vezes é idempotente", async () => {
  const { port, calls } = fakePort();
  const { handler, logs } = setup(port);
  const body = textReply("wamid.in.dup");
  assert.equal((await handler(await signedPost(body))).status, 200);
  assert.equal((await handler(await signedPost(body))).status, 200);
  assert.equal(calls.length, 2);
  const results = logs.filter((l) => l.event === "webhook_processed").map((l) => l.data.results);
  assert.deepEqual(results, [{ confirmed: 1 }, { duplicate: 1 }]);
});

test("resposta negativa/ambígua não chama a porta", async () => {
  const { port, calls } = fakePort();
  const { handler } = setup(port);
  for (const text of ["não", "não confirmo", "talvez", "preciso remarcar", "Que horas?"]) {
    assert.equal((await handler(await signedPost(textReply(`w-${text}`, text)))).status, 200);
  }
  assert.equal(calls.length, 0);
});

test("D: payload incompleto não derruba a function", async () => {
  const { port, calls } = fakePort();
  const { handler } = setup(port);
  for (const body of ["{}", "[]", "null", '{"entry":[{"changes":[{"value":{"messages":[{}]}}]}]}', "não é json"]) {
    const res = await handler(await signedPost(body));
    assert.equal(res.status, 200, body);
  }
  assert.equal(calls.length, 0);
});

test("falha de persistência -> 500 para a Meta reenviar (seguro: idempotente)", async () => {
  const { port } = fakePort({ kind: "error", code: "persistence_error" });
  const { handler } = setup(port);
  assert.equal((await handler(await signedPost(textReply("wamid.in.err")))).status, 500);
});

test("porta indisponível (ex.: env do service role ausente) -> 500, sem lançar", async () => {
  const handler = createWebhookHandler({
    verifyToken: VERIFY_TOKEN,
    appSecret: APP_SECRET,
    getPort: () => {
      throw new Error("SUPABASE_SERVICE_ROLE_KEY ausente");
    },
    log: () => {},
  });
  assert.equal((await handler(await signedPost(textReply("w")))).status, 500);
});

test("logs não contêm telefone, texto da mensagem nem secrets", async () => {
  const { port } = fakePort();
  const { handler, logs } = setup(port);
  await handler(await signedPost(textReply("wamid.in.log", "Sim, confirmo!")));
  await handler(await signedPost(textReply("wamid.in.log2"), "errado"));
  await handler(await signedPost("não é json"));
  await handler(new Request(`${URL_BASE}?hub.mode=subscribe&hub.verify_token=x&hub.challenge=1`));
  const serialized = JSON.stringify(logs);
  for (const forbidden of ["5562911110001", "confirmo", APP_SECRET, VERIFY_TOKEN, "não é json"]) {
    assert.ok(!serialized.includes(forbidden), `log contém ${forbidden}`);
  }
});

test("método não suportado -> 405", async () => {
  const { handler } = setup(fakePort().port);
  assert.equal((await handler(new Request(URL_BASE, { method: "PUT" }))).status, 405);
});
