// Dispatcher com store EM MEMÓRIA (imita as RPCs da 0026) + FakeWhatsappProvider.
// A garantia real de concorrência (SKIP LOCKED) é testada contra Postgres no
// E2E (supabase/tests/e2e/); aqui, a orquestração.

import { test } from "node:test";
import assert from "node:assert/strict";
import { dispatchPendingWhatsappMessages } from "./dispatch.ts";
import { createFakeWhatsappProvider } from "./fake_provider.testutil.ts";
import type { CompletionInput, DispatchStore, PrepareResult, PreparedSend, TemplateConfig } from "./types.ts";
import type { MessageType } from "../scheduler/decision.ts";

const TOKEN = "tok_teste_dispatch_0123456789";
const NOW = new Date("2026-10-29T23:00:00Z");
const templates: TemplateConfig = {
  languageCode: "pt_BR",
  names: { appointment_12h: "la_pelve_confirmacao", appointment_confirmation: "la_pelve_agendamento" },
};

interface Row {
  id: string;
  type: MessageType;
  status: string;
  lease: string | null;
  prepare: PrepareResult["kind"];
  attempts: number;
  completions: CompletionInput[];
}

function memoryStore(rows: Row[], options: { failCompleteTimes?: number } = {}) {
  let failCompleteTimes = options.failCompleteTimes ?? 0;
  const claimedTypes: MessageType[][] = [];
  const store: DispatchStore = {
    async claim({ reminderTypes }) {
      claimedTypes.push(reminderTypes);
      return rows
        .filter((r) => r.status === "scheduled" && reminderTypes.includes(r.type))
        .map((r) => {
          r.status = "processing";
          r.lease = `lease-${r.id}`;
          return { messageId: r.id, leaseToken: r.lease, reminderType: r.type };
        });
    },
    async prepare(id, lease) {
      const r = rows.find((x) => x.id === id)!;
      if (r.lease !== lease) return { kind: "lease_lost" };
      if (r.prepare === "cancelled") {
        r.status = "cancelled";
        return { kind: "cancelled", code: "consent_revoked" };
      }
      if (r.prepare === "deferred") {
        r.status = "scheduled";
        return { kind: "deferred", code: "connection_inactive" };
      }
      if (r.prepare === "lease_lost") return { kind: "lease_lost" };
      r.attempts++;
      const send: PreparedSend = {
        reminderType: r.type,
        attemptCount: r.attempts,
        destinationPhoneE164: "+5562911110001",
        patientFirstName: "Camila",
        appointmentDate: "2026-10-30",
        appointmentTime: "08:00",
        timeZone: "America/Sao_Paulo",
        phoneNumberId: "123456789012345",
        accessToken: TOKEN,
      };
      return { kind: "ready", send };
    },
    async complete(id, lease, completion) {
      if (failCompleteTimes > 0) {
        failCompleteTimes--;
        throw new Error("rede");
      }
      const r = rows.find((x) => x.id === id)!;
      if (r.lease !== lease) return "lease_lost";
      r.completions.push(completion);
      r.status = completion.result === "retry" ? "scheduled" : completion.result;
      r.lease = null;
      return "ok";
    },
  };
  return { store, claimedTypes };
}

function row(id: string, overrides: Partial<Row> = {}): Row {
  return { id, type: "appointment_12h", status: "scheduled", lease: null, prepare: "ready", attempts: 0, completions: [], ...overrides };
}

test("envia uma mensagem da fila: wamid gravado e status sent", async () => {
  const rows = [row("m1")];
  const { store } = memoryStore(rows);
  const provider = createFakeWhatsappProvider(() => ({ kind: "sent", wamid: "wamid.ok-1" }));
  const summary = await dispatchPendingWhatsappMessages({ store, provider, templates, now: () => NOW, log: () => {} });
  assert.equal(provider.sent.length, 1);
  assert.equal(provider.sent[0].accessToken, TOKEN);
  assert.equal(provider.sent[0].phoneNumberId, "123456789012345");
  assert.equal(provider.sent[0].message.template.name, "la_pelve_confirmacao");
  assert.deepEqual(rows[0].completions, [{ result: "sent", wamid: "wamid.ok-1", templateName: "la_pelve_confirmacao" }]);
  assert.equal(rows[0].status, "sent");
  assert.equal(summary.sent, 1);
});

test("falha HTTP temporária -> retry; definitiva -> failed; resultado desconhecido -> failed sem retry", async () => {
  const rows = [row("m1"), row("m2"), row("m3")];
  const { store } = memoryStore(rows);
  const results = [
    { kind: "retryable", code: "provider_unavailable", httpStatus: 503 },
    { kind: "rejected", code: "request_rejected", httpStatus: 400, providerCode: 132001 },
    { kind: "unknown", code: "timeout" },
  ] as const;
  const provider = createFakeWhatsappProvider((_r, i) => results[i]);
  const summary = await dispatchPendingWhatsappMessages({ store, provider, templates, now: () => NOW, log: () => {} });
  assert.equal(rows[0].completions[0].result, "retry");
  assert.equal(rows[0].status, "scheduled");
  assert.equal(rows[1].completions[0].result, "failed");
  assert.deepEqual(rows[2].completions[0], {
    result: "failed",
    templateName: "la_pelve_confirmacao",
    error: { code: "send_outcome_unknown" },
  });
  assert.deepEqual(
    { retried: summary.retried, failed: summary.failed, unknownOutcome: summary.unknownOutcome },
    { retried: 1, failed: 1, unknownOutcome: 1 },
  );
});

test("cancelada/adiada/lease perdida no prepare: não chama a Meta", async () => {
  const rows = [row("c", { prepare: "cancelled" }), row("d", { prepare: "deferred" }), row("l", { prepare: "lease_lost" })];
  const { store } = memoryStore(rows);
  const provider = createFakeWhatsappProvider();
  const summary = await dispatchPendingWhatsappMessages({ store, provider, templates, now: () => NOW, log: () => {} });
  assert.equal(provider.sent.length, 0);
  assert.deepEqual(
    { cancelled: summary.cancelled, deferred: summary.deferred, leaseLost: summary.leaseLost },
    { cancelled: 1, deferred: 1, leaseLost: 1 },
  );
});

test("só reserva os tipos com template configurado", async () => {
  const rows = [row("r", { type: "appointment_rescheduled" })];
  const { store, claimedTypes } = memoryStore(rows);
  const provider = createFakeWhatsappProvider();
  await dispatchPendingWhatsappMessages({ store, provider, templates, now: () => NOW, log: () => {} });
  assert.deepEqual(claimedTypes[0].sort(), ["appointment_12h", "appointment_confirmation"]);
  assert.equal(rows[0].status, "scheduled");
  assert.equal(provider.sent.length, 0);
});

test("nenhum template configurado: nem reserva", async () => {
  const { store, claimedTypes } = memoryStore([row("m")]);
  await dispatchPendingWhatsappMessages({
    store,
    provider: createFakeWhatsappProvider(),
    templates: { languageCode: "pt_BR", names: {} },
    now: () => NOW,
    log: () => {},
  });
  assert.equal(claimedTypes.length, 0);
});

test("gravar o resultado falha 1 vez: tenta de novo e grava o wamid", async () => {
  const rows = [row("m1")];
  const { store } = memoryStore(rows, { failCompleteTimes: 1 });
  const summary = await dispatchPendingWhatsappMessages({
    store,
    provider: createFakeWhatsappProvider(),
    templates,
    now: () => NOW,
    log: () => {},
  });
  assert.equal(rows[0].status, "sent");
  assert.equal(summary.sent, 1);
});

test("falha de banco no claim/prepare não lança", async () => {
  const failing: DispatchStore = {
    claim: async () => {
      throw new Error("db down");
    },
    prepare: async () => ({ kind: "lease_lost" }),
    complete: async () => "ok",
  };
  const summary = await dispatchPendingWhatsappMessages({
    store: failing,
    provider: createFakeWhatsappProvider(),
    templates,
    now: () => NOW,
    log: () => {},
  });
  assert.equal(summary.errors, 1);
});

test("token nunca aparece em log nem no resumo", async () => {
  const logs: unknown[] = [];
  const rows = [row("m1"), row("m2")];
  const { store } = memoryStore(rows, { failCompleteTimes: 2 });
  const summary = await dispatchPendingWhatsappMessages({
    store,
    provider: createFakeWhatsappProvider(),
    templates,
    now: () => NOW,
    log: (event, data) => logs.push({ event, data }),
  });
  assert.ok(logs.length > 0);
  assert.ok(!JSON.stringify(logs).includes(TOKEN));
  assert.ok(!JSON.stringify(summary).includes(TOKEN));
  assert.ok(!JSON.stringify(rows.flatMap((r) => r.completions)).includes(TOKEN));
});
