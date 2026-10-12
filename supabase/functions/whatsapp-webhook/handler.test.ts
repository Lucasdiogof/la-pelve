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

// ---------------------------------------------------------------------------
// account_update (revogação/restrição da WABA)
// ---------------------------------------------------------------------------

import type { AccountEvent } from "../_shared/account/parse_account_update.ts";
import type { AccountEventPort } from "../_shared/account/types.ts";

function accountSetup(result: number | null | (() => number | null) = 1) {
  const applied: AccountEvent[] = [];
  const accountPort: AccountEventPort = {
    async applyAccountEvent(event) {
      applied.push(event);
      return typeof result === "function" ? result() : result;
    },
  };
  const logs: Array<{ event: string; data: Record<string, unknown> }> = [];
  const handler = createWebhookHandler({
    verifyToken: VERIFY_TOKEN,
    appSecret: APP_SECRET,
    getPort: () => fakePort().port,
    getAccountPort: () => accountPort,
    log: (event, data) => logs.push({ event, data }),
  });
  return { handler, applied, logs };
}

const accountBody = (event: string, wabaId = "980198427658004") => ({
  object: "whatsapp_business_account",
  entry: [{ id: "1", time: 1, changes: [{ field: "account_update", value: { event, waba_info: { waba_id: wabaId } } }] }],
});

test("account_update com assinatura válida aplica a revogação da WABA", async () => {
  const { handler, applied, logs } = accountSetup();
  const res = await handler(await signedPost(accountBody("PARTNER_REMOVED")));
  assert.equal(res.status, 200);
  assert.deepEqual(applied, [{ wabaId: "980198427658004", event: "PARTNER_REMOVED", detail: "" }]);
  assert.ok(logs.some((l) => l.event === "account_update_processed"));
  assert.ok(!JSON.stringify(logs).includes("980198427658004"), "sem id de conta em log");
});

test("account_update sem assinatura válida NÃO altera nada", async () => {
  const { handler, applied } = accountSetup();
  const res = await handler(await signedPost(accountBody("PARTNER_REMOVED"), "outro-segredo"));
  assert.equal(res.status, 401);
  assert.deepEqual(applied, []);
});

test("falha ao aplicar account_update devolve 500 (a Meta reenvia) e reenvio é idempotente", async () => {
  let fail = true;
  const { handler, applied } = accountSetup(() => (fail ? null : 0));
  assert.equal((await handler(await signedPost(accountBody("ACCOUNT_DELETED")))).status, 500);
  fail = false;
  assert.equal((await handler(await signedPost(accountBody("ACCOUNT_DELETED")))).status, 200);
  assert.equal(applied.length, 2);
});

test("webhook de mensagens continua funcionando sem porta de conta", async () => {
  const { port } = fakePort();
  const { handler } = setup(port);
  assert.equal((await handler(await signedPost(accountBody("PARTNER_REMOVED")))).status, 200);
});

// --------------------------------------------------------------------------
// Status de entrega (statuses[]) e status de templates (0033)
// --------------------------------------------------------------------------

import type { DeliveryStatusPort, StatusApplyResult } from "../_shared/delivery/status_port.ts";
import type { DeliveryStatus } from "../_shared/delivery/parse_statuses.ts";
import type { TemplateStatusPort } from "../_shared/templates/template_port.ts";
import type { TemplateStatusEvent } from "../_shared/templates/parse_template_status.ts";

const PNID = "106540352242922";
const RANK: Record<string, number> = { sent: 1, delivered: 2, read: 3 };

/** Porta falsa com estado: monotônica como a RPC (nunca rebaixa). */
function fakeStatusPort(failWith: StatusApplyResult | null | "throw" = "updated") {
  const applied: DeliveryStatus[] = [];
  const current = new Map<string, string>();
  const port: DeliveryStatusPort = {
    async applyStatus(s) {
      if (failWith === "throw") throw new Error("boom");
      if (failWith === null) return null;
      applied.push(s);
      const before = current.get(s.wamid);
      if (before === undefined) return "not_found";
      if (s.status === "failed") {
        if (before === "read" || before === "failed") return "unchanged";
        current.set(s.wamid, "failed");
        return "updated";
      }
      if ((RANK[s.status] ?? 0) <= (RANK[before] ?? 0)) return "unchanged";
      current.set(s.wamid, s.status);
      return "updated";
    },
  };
  return { port, applied, current };
}

function fakeTemplatePort(result: number | null = 1) {
  const applied: TemplateStatusEvent[] = [];
  const port: TemplateStatusPort = {
    async applyTemplateStatus(e) {
      applied.push(e);
      return result;
    },
  };
  return { port, applied };
}

function statusSetup(
  statusPort: DeliveryStatusPort,
  templatePort: TemplateStatusPort = fakeTemplatePort().port,
  replyPort: ConfirmationReplyPort = fakePort().port,
) {
  const logs: Array<{ event: string; data: Record<string, unknown> }> = [];
  const handler = createWebhookHandler({
    verifyToken: VERIFY_TOKEN,
    appSecret: APP_SECRET,
    getPort: () => replyPort,
    getStatusPort: () => statusPort,
    getTemplatePort: () => templatePort,
    templates: { names: ["appointment_confirmation", "appointment_12h"], language: "pt_BR" },
    log: (event, data) => logs.push({ event, data }),
  });
  return { handler, logs };
}

const statusBody = (statuses: Array<Record<string, unknown>>) => ({
  object: "whatsapp_business_account",
  entry: [
    {
      id: "102290129340398",
      changes: [
        {
          field: "messages",
          value: {
            messaging_product: "whatsapp",
            metadata: { display_phone_number: "556230000000", phone_number_id: PNID },
            statuses: statuses.map((s) => ({ timestamp: TS, recipient_id: "5562911110001", ...s })),
          },
        },
      ],
    },
  ],
});

const templateBody = (event: string, name = "appointment_12h", language = "pt_BR") => ({
  object: "whatsapp_business_account",
  entry: [
    {
      id: "102290129340398",
      time: Number(TS),
      changes: [
        {
          field: "message_template_status_update",
          value: { event, message_template_id: 1, message_template_name: name, message_template_language: language, reason: "NONE" },
        },
      ],
    },
  ],
});

test("status: assinatura inválida não aplica nada", async () => {
  const s = fakeStatusPort();
  const { handler } = statusSetup(s.port);
  const res = await handler(await signedPost(statusBody([{ id: "wamid.X", status: "read" }]), "outro-segredo"));
  assert.equal(res.status, 401);
  assert.deepEqual(s.applied, []);
});

test("status: sent -> delivered -> read avança; read duplicado e sent atrasado não rebaixam", async () => {
  const s = fakeStatusPort();
  s.current.set("wamid.X", "sent");
  const { handler, logs } = statusSetup(s.port);
  for (const status of ["delivered", "read", "read", "sent", "delivered"]) {
    assert.equal((await handler(await signedPost(statusBody([{ id: "wamid.X", status }])))).status, 200);
  }
  assert.equal(s.current.get("wamid.X"), "read");
  assert.equal(s.applied.length, 5);
  const processed = logs.filter((l) => l.event === "delivery_status_processed");
  assert.deepEqual(processed.map((l) => l.data.updated ?? 0), [1, 1, 0, 0, 0]);
});

test("status: failed não rebaixa read e nunca vira resposta/reenvio", async () => {
  const s = fakeStatusPort();
  s.current.set("wamid.Y", "read");
  const reply = fakePort();
  const { handler } = statusSetup(s.port, fakeTemplatePort().port, reply.port);
  const res = await handler(await signedPost(statusBody([{ id: "wamid.Y", status: "failed", errors: [{ code: 131026 }] }])));
  assert.equal(res.status, 200);
  assert.equal(s.current.get("wamid.Y"), "read");
  assert.deepEqual(reply.calls, [], "status não é resposta da paciente");
});

test("status: wamid desconhecido (outra mensagem/conta) é ignorado com 200", async () => {
  const s = fakeStatusPort();
  const { handler, logs } = statusSetup(s.port);
  const res = await handler(await signedPost(statusBody([{ id: "wamid.de.outro", status: "delivered" }])));
  assert.equal(res.status, 200);
  assert.equal(logs.find((l) => l.event === "delivery_status_processed")?.data.not_found, 1);
});

test("status: falha de persistência ou porta indisponível -> 500 (a Meta reenvia)", async () => {
  for (const mode of [null, "throw"] as const) {
    const { handler } = statusSetup(fakeStatusPort(mode).port);
    const res = await handler(await signedPost(statusBody([{ id: "wamid.Z", status: "delivered" }])));
    assert.equal(res.status, 500);
  }
});

test("status e resposta da paciente no mesmo payload: os dois são processados", async () => {
  const s = fakeStatusPort();
  s.current.set("wamid.out", "sent");
  const reply = fakePort();
  const { handler } = statusSetup(s.port, fakeTemplatePort().port, reply.port);
  const body = textReply("wamid.in.1");
  const value = body.entry[0].changes[0].value as Record<string, unknown>;
  value.metadata = { display_phone_number: "556230000000", phone_number_id: PNID };
  value.statuses = [{ id: "wamid.out", status: "read", timestamp: TS, recipient_id: "5562911110001" }];
  const res = await handler(await signedPost(body));
  assert.equal(res.status, 200);
  assert.equal(s.current.get("wamid.out"), "read");
  assert.equal(reply.calls.length, 1);
});

test("logs de status não têm wamid, telefone nem número do profissional", async () => {
  const s = fakeStatusPort();
  s.current.set("wamid.SEGREDO", "sent");
  const { handler, logs } = statusSetup(s.port);
  await handler(await signedPost(statusBody([{ id: "wamid.SEGREDO", status: "failed", errors: [{ code: 131026, title: "t" }] }])));
  const text = JSON.stringify(logs);
  assert.ok(!text.includes("SEGREDO") && !text.includes("5562911110001") && !text.includes(PNID));
});

test("template: só os templates da prontidão (nome + idioma) são aplicados", async () => {
  const t = fakeTemplatePort();
  const { handler, logs } = statusSetup(fakeStatusPort().port, t.port);
  for (const body of [
    templateBody("PAUSED"),
    templateBody("REJECTED", "promo_outubro"),
    templateBody("REJECTED", "appointment_12h", "en_US"),
    templateBody("APPROVED", "appointment_confirmation"),
  ]) {
    assert.equal((await handler(await signedPost(body))).status, 200);
  }
  assert.deepEqual(t.applied.map((e) => `${e.name}:${e.event}`), ["appointment_12h:PAUSED", "appointment_confirmation:APPROVED"]);
  assert.ok(logs.some((l) => l.event === "template_status_processed" && l.data.relevant === 0));
});

test("template: assinatura inválida não aplica; falha de persistência -> 500", async () => {
  const t = fakeTemplatePort();
  const { handler } = statusSetup(fakeStatusPort().port, t.port);
  assert.equal((await handler(await signedPost(templateBody("PAUSED"), "outro-segredo"))).status, 401);
  assert.deepEqual(t.applied, []);
  const broken = statusSetup(fakeStatusPort().port, fakeTemplatePort(null).port);
  assert.equal((await broken.handler(await signedPost(templateBody("PAUSED")))).status, 500);
});

test("sem portas de status/template configuradas, o webhook de confirmação segue igual", async () => {
  const { port, calls } = fakePort();
  const { handler } = setup(port);
  assert.equal((await handler(await signedPost(statusBody([{ id: "wamid.X", status: "read" }])))).status, 200);
  assert.equal((await handler(await signedPost(templateBody("PAUSED")))).status, 200);
  assert.deepEqual(calls, []);
});

// --------------------------------------------------------------------------
// Reavaliação depois de aprovação de template (0034)
// --------------------------------------------------------------------------

function reevalSetup(templateResult: number | null = 1, withDefer = false) {
  const logs: Array<{ event: string; data: Record<string, unknown> }> = [];
  const reevaluated: string[] = [];
  const deferred: Array<Promise<unknown>> = [];
  const handler = createWebhookHandler({
    verifyToken: VERIFY_TOKEN,
    appSecret: APP_SECRET,
    getPort: () => fakePort().port,
    getStatusPort: () => fakeStatusPort().port,
    getTemplatePort: () => fakeTemplatePort(templateResult).port,
    templates: { names: ["appointment_confirmation", "appointment_12h"], language: "pt_BR" },
    reevaluate: async (wabaId) => {
      reevaluated.push(wabaId);
      return { candidates: 1, promoted: 1, notReady: 0, stale: 0, errors: 0 };
    },
    defer: withDefer ? (task) => deferred.push(task) : undefined,
    log: (event, data) => logs.push({ event, data }),
  });
  return { handler, logs, reevaluated, deferred };
}

test("reavaliação: APPROVED/REINSTATED/UNARCHIVED de template da prontidão disparam a checagem completa", async () => {
  for (const event of ["APPROVED", "REINSTATED", "UNARCHIVED"]) {
    const r = reevalSetup();
    assert.equal((await r.handler(await signedPost(templateBody(event)))).status, 200);
    assert.deepEqual(r.reevaluated, ["102290129340398"], event);
    assert.ok(r.logs.some((l) => l.event === "template_reevaluation" && l.data.promoted === 1));
  }
});

test("reavaliação: eventos negativos, FLAGGED e templates de fora NÃO disparam", async () => {
  for (const body of [templateBody("PAUSED"), templateBody("FLAGGED"), templateBody("APPROVED", "promo_outubro")]) {
    const r = reevalSetup();
    await r.handler(await signedPost(body));
    assert.deepEqual(r.reevaluated, []);
  }
});

test("reavaliação: sem assinatura válida ou com falha ao gravar o evento, nada é reavaliado", async () => {
  const r = reevalSetup();
  assert.equal((await r.handler(await signedPost(templateBody("APPROVED"), "outro-segredo"))).status, 401);
  const broken = reevalSetup(null);
  assert.equal((await broken.handler(await signedPost(templateBody("APPROVED")))).status, 500);
  assert.deepEqual([...r.reevaluated, ...broken.reevaluated], []);
});

test("reavaliação: roda depois da resposta quando há defer (não segura o webhook da Meta)", async () => {
  const r = reevalSetup(1, true);
  const res = await r.handler(await signedPost(templateBody("APPROVED")));
  assert.equal(res.status, 200);
  assert.equal(r.deferred.length, 1);
  await Promise.all(r.deferred);
  assert.deepEqual(r.reevaluated, ["102290129340398"]);
});
