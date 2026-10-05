// Testes da orquestração em lote (reconcileAll) -- primeiro com portas
// simples, depois de ponta a ponta com o ADAPTER real sobre o banco falso.
// Nenhum teste toca produção.
//
// Regra sob teste: só action='cancel' chama a porta. 'blocked'
// (appointment_cancelled, reversível) e 'keep' não fazem NENHUM I/O.

import { mock, test } from "node:test";
import assert from "node:assert/strict";
import { reconcileAll } from "./reconcile.ts";
import { createSupabaseReconciliationPort } from "./supabase_reconciliation_port.ts";
import { FAKE_PHONE, fakeMessagesDb, makeRow } from "./fake_messages_db.testutil.ts";
import type { CancelOutcome, MessageStatus, ReconciliationInput, ReconciliationPort } from "./types.ts";

const REVOKED = "2026-10-05T00:00:00.000Z";

function base(id: string, status: MessageStatus = "scheduled"): ReconciliationInput {
  return {
    message: {
      id,
      status,
      scheduleRevision: 0,
      appointmentId: `appt-${id}`,
      consentId: `consent-${id}`,
    },
    appointment: { id: `appt-${id}`, status: "scheduled", scheduleRevision: 0 },
    consent: { id: `consent-${id}`, revokedAt: null },
  };
}

/** scheduled válida -> keep */
const keepInput = (id: string) => base(id);

/** consulta cancelled, revisão atual, consentimento ativo -> blocked (sem I/O) */
function blockedInput(id: string): ReconciliationInput {
  return { ...base(id), appointment: { id: `appt-${id}`, status: "cancelled", scheduleRevision: 0 } };
}

/** revisão da consulta avançou -> cancel stale_schedule_revision */
function staleInput(id: string): ReconciliationInput {
  return { ...base(id), appointment: { id: `appt-${id}`, status: "scheduled", scheduleRevision: 1 } };
}

/** consentimento revogado -> cancel consent_revoked */
function revokedInput(id: string): ReconciliationInput {
  return { ...base(id), consent: { id: `consent-${id}`, revokedAt: REVOKED } };
}

/** Porta falsa programável por messageId, que registra as chamadas. */
function scriptedPort(outcomes: Record<string, CancelOutcome | "throw"> = {}) {
  const called: string[] = [];
  const port: ReconciliationPort = {
    cancelIfScheduled(messageId) {
      called.push(messageId);
      const o = outcomes[messageId] ?? { kind: "cancelled" };
      if (o === "throw") return Promise.reject(new Error(`boom ${FAKE_PHONE}`));
      return Promise.resolve(o);
    },
  };
  return { port, called };
}

const EMPTY_CANCELLED = { stale_schedule_revision: 0, consent_revoked: 0 };
const EMPTY_BLOCKED = { appointment_cancelled: 0 };

test("lote vazio -> summary zerado, nenhuma chamada à porta", async () => {
  const { port, called } = scriptedPort();
  assert.deepEqual(await reconcileAll(port, []), {
    candidates: 0,
    unchanged: 0,
    blocked: 0,
    cancelled: 0,
    alreadyNotScheduled: 0,
    notFound: 0,
    errors: 0,
    cancelledByReason: EMPTY_CANCELLED,
    blockedByReason: EMPTY_BLOCKED,
  });
  assert.deepEqual(called, []);
});

// ---------------------------------------------------------------------
// 16-23: quem chama (ou não) a porta
// ---------------------------------------------------------------------

test("16: blocked (appointment_cancelled) NÃO chama cancelIfScheduled", async () => {
  const { port, called } = scriptedPort();
  const summary = await reconcileAll(port, [blockedInput("b1"), blockedInput("b2")]);
  assert.deepEqual(called, []);
  assert.equal(summary.blocked, 2);
  assert.equal(summary.cancelled, 0);
  assert.equal(summary.errors, 0);
});

test("17: keep NÃO chama cancelIfScheduled (válida e status fora do escopo)", async () => {
  const { port, called } = scriptedPort();
  const inputs = [
    keepInput("k1"),
    base("p1", "processing"),
    base("f1", "failed"),
    base("s1", "sent"),
    base("d1", "delivered"),
    base("r1", "read"),
    base("c1", "cancelled"),
  ];
  const summary = await reconcileAll(port, inputs);
  assert.deepEqual(called, []);
  assert.equal(summary.unchanged, 7);
});

test("18: stale chama exatamente 1 cancelIfScheduled", async () => {
  const { port, called } = scriptedPort();
  const summary = await reconcileAll(port, [staleInput("s1")]);
  assert.deepEqual(called, ["s1"]);
  assert.equal(summary.cancelled, 1);
  assert.deepEqual(summary.cancelledByReason, { stale_schedule_revision: 1, consent_revoked: 0 });
});

test("19: revoked chama exatamente 1 cancelIfScheduled", async () => {
  const { port, called } = scriptedPort();
  const summary = await reconcileAll(port, [revokedInput("r1")]);
  assert.deepEqual(called, ["r1"]);
  assert.equal(summary.cancelled, 1);
  assert.deepEqual(summary.cancelledByReason, { stale_schedule_revision: 0, consent_revoked: 1 });
});

test("20: mistura (1 blocked, 1 stale, 1 revoked, 1 keep) -> summary correto e SÓ 2 chamadas à porta", async () => {
  const { port, called } = scriptedPort();
  const summary = await reconcileAll(port, [
    blockedInput("blk"),
    staleInput("stl"),
    revokedInput("rev"),
    keepInput("keep"),
  ]);
  assert.deepEqual(called, ["stl", "rev"], "só as 2 permanentes chamam a porta");
  assert.deepEqual(summary, {
    candidates: 4,
    unchanged: 1,
    blocked: 1,
    cancelled: 2,
    alreadyNotScheduled: 0,
    notFound: 0,
    errors: 0,
    cancelledByReason: { stale_schedule_revision: 1, consent_revoked: 1 },
    blockedByReason: { appointment_cancelled: 1 },
  });
});

test("21: falha de cancelamento de uma candidata não interrompe as demais (erro e exceção da porta)", async () => {
  const { port, called } = scriptedPort({
    s2: { kind: "error", code: "persistence_error" },
    s3: "throw",
  });
  const summary = await reconcileAll(port, ["s1", "s2", "s3", "s4"].map((id) => staleInput(id)));
  assert.deepEqual(called, ["s1", "s2", "s3", "s4"]);
  assert.equal(summary.cancelled, 2);
  assert.equal(summary.errors, 2);
  assert.deepEqual(summary.cancelledByReason, { stale_schedule_revision: 2, consent_revoked: 0 });
});

test("22: blocked NÃO aparece em cancelledByReason (nem em cancelled)", async () => {
  const { port } = scriptedPort();
  const summary = await reconcileAll(port, [blockedInput("b1"), blockedInput("b2"), staleInput("s1")]);
  assert.deepEqual(Object.keys(summary.cancelledByReason).sort(), ["consent_revoked", "stale_schedule_revision"]);
  assert.ok(!("appointment_cancelled" in summary.cancelledByReason));
  assert.equal(summary.cancelled, 1, "só a stale conta como cancelled");
  assert.equal(summary.blocked, 2);
});

test("23: appointment_cancelled aparece SOMENTE em blockedByReason", async () => {
  const { port } = scriptedPort();
  const summary = await reconcileAll(port, [blockedInput("b1"), blockedInput("b2"), revokedInput("r1")]);
  assert.deepEqual(summary.blockedByReason, { appointment_cancelled: 2 });
  assert.deepEqual(Object.keys(summary.blockedByReason), ["appointment_cancelled"]);
  assert.deepEqual(summary.cancelledByReason, { stale_schedule_revision: 0, consent_revoked: 1 });
});

test("consulta cancelled + stale / + revogado -> CANCELA (porta chamada) em vez de ficar blocked", async () => {
  const { port, called } = scriptedPort();
  const cancelledAndStale: ReconciliationInput = {
    ...staleInput("a"),
    appointment: { id: "appt-a", status: "cancelled", scheduleRevision: 3 },
  };
  const cancelledAndRevoked: ReconciliationInput = {
    ...revokedInput("b"),
    appointment: { id: "appt-b", status: "cancelled", scheduleRevision: 0 },
  };
  const summary = await reconcileAll(port, [cancelledAndStale, cancelledAndRevoked]);
  assert.deepEqual(called, ["a", "b"]);
  assert.equal(summary.blocked, 0);
  assert.deepEqual(summary.cancelledByReason, { stale_schedule_revision: 1, consent_revoked: 1 });
});

test("cada resultado da porta cai no contador certo", async () => {
  const { port } = scriptedPort({
    a: { kind: "cancelled" },
    b: { kind: "already_not_scheduled" },
    c: { kind: "not_found" },
    d: { kind: "error", code: "persistence_error" },
  });
  const summary = await reconcileAll(port, ["a", "b", "c", "d"].map((id) => staleInput(id)));
  assert.equal(summary.cancelled, 1);
  assert.equal(summary.alreadyNotScheduled, 1);
  assert.equal(summary.notFound, 1);
  assert.equal(summary.errors, 1);
  assert.equal(summary.cancelledByReason.stale_schedule_revision, 1, "só o 'cancelled' entra no por-motivo");
});

test("input com integridade quebrada conta como erro, não aborta o lote e não chama a porta", async () => {
  const { port, called } = scriptedPort();
  const broken: ReconciliationInput = { ...staleInput("x"), consent: null };
  const logSpy = mock.method(console, "error", () => {});
  let summary;
  try {
    summary = await reconcileAll(port, [staleInput("a"), broken, staleInput("b")]);
  } finally {
    const logs = logSpy.mock.calls.map((c) => c.arguments.join(" "));
    logSpy.mock.restore();
    assert.equal(logs.length, 1);
    assert.ok(logs[0].includes("whatsapp_message_reconciliation_input_invalid"));
    assert.ok(logs[0].includes("consent_missing"));
    assert.ok(logs[0].includes('"messageId":"x"'));
  }
  assert.deepEqual(called, ["a", "b"]);
  assert.equal(summary.cancelled, 2);
  assert.equal(summary.errors, 1);
});

test("invariante: candidates = unchanged + blocked + cancelled + alreadyNotScheduled + notFound + errors", async () => {
  const { port } = scriptedPort({
    s2: { kind: "already_not_scheduled" },
    s3: { kind: "not_found" },
    s4: { kind: "error", code: "persistence_error" },
  });
  const logSpy = mock.method(console, "error", () => {});
  let summary;
  try {
    summary = await reconcileAll(port, [
      staleInput("s1"),
      staleInput("s2"),
      staleInput("s3"),
      staleInput("s4"),
      revokedInput("r1"),
      blockedInput("b1"),
      keepInput("k1"),
      base("p1", "processing"),
      { ...staleInput("bad"), appointment: null },
    ]);
  } finally {
    logSpy.mock.restore();
  }
  const total = summary.unchanged + summary.blocked + summary.cancelled + summary.alreadyNotScheduled +
    summary.notFound + summary.errors;
  assert.equal(summary.candidates, 9);
  assert.equal(total, summary.candidates);
});

test("processamento é sequencial, na ordem de entrada (e blocked/keep no meio não alteram a ordem das chamadas)", async () => {
  const order: string[] = [];
  const port: ReconciliationPort = {
    async cancelIfScheduled(id) {
      order.push(`start:${id}`);
      await new Promise((r) => setTimeout(r, id === "a" ? 15 : 1));
      order.push(`end:${id}`);
      return { kind: "cancelled" };
    },
  };
  await reconcileAll(port, [staleInput("a"), blockedInput("x"), staleInput("b"), keepInput("y"), revokedInput("c")]);
  assert.deepEqual(order, ["start:a", "end:a", "start:b", "end:b", "start:c", "end:c"]);
});

// ---------------------------------------------------------------------
// De ponta a ponta: reconcileAll + adapter real + banco falso
// ---------------------------------------------------------------------

test("três mensagens com motivo permanente -> 3 cancelled no banco", async () => {
  const db = fakeMessagesDb([makeRow("m1"), makeRow("m2"), makeRow("m3")]);
  const summary = await reconcileAll(
    createSupabaseReconciliationPort(db.client),
    [staleInput("m1"), revokedInput("m2"), staleInput("m3")],
  );
  assert.equal(summary.cancelled, 3);
  assert.equal(summary.errors, 0);
  assert.deepEqual(db.rows.map((r) => r.status), ["cancelled", "cancelled", "cancelled"]);
});

test("blocked: a linha continua 'scheduled', sem nenhum UPDATE sequer tentado", async () => {
  const db = fakeMessagesDb([makeRow("m1")]);
  const summary = await reconcileAll(createSupabaseReconciliationPort(db.client), [blockedInput("m1")]);
  assert.equal(summary.blocked, 1);
  assert.equal(summary.cancelled, 0);
  assert.equal(db.calls.update, 0);
  assert.equal(db.calls.select, 0);
  assert.equal(db.byId("m1")?.status, "scheduled", "intencional: o dispatch futuro revalida a consulta");
  assert.deepEqual(db.changedFields, []);
});

test("mistura no banco: blocked e keep ficam scheduled; stale e revoked viram cancelled (2 UPDATEs)", async () => {
  const db = fakeMessagesDb([makeRow("blk"), makeRow("stl"), makeRow("rev"), makeRow("keep")]);
  const summary = await reconcileAll(createSupabaseReconciliationPort(db.client), [
    blockedInput("blk"),
    staleInput("stl"),
    revokedInput("rev"),
    keepInput("keep"),
  ]);
  assert.equal(db.calls.update, 2);
  assert.deepEqual(db.rows.map((r) => `${r.id}:${r.status}`), [
    "blk:scheduled",
    "stl:cancelled",
    "rev:cancelled",
    "keep:scheduled",
  ]);
  assert.equal(summary.blocked, 1);
  assert.equal(summary.cancelled, 2);
  assert.equal(summary.unchanged, 1);
});

test("falha do banco na do meio -> as outras continuam (m2 fica scheduled)", async () => {
  const db = fakeMessagesDb([makeRow("m1"), makeRow("m2"), makeRow("m3")], {
    updateFailOnCall: { call: 2, mode: "error" },
  });
  const logSpy = mock.method(console, "error", () => {});
  let summary;
  try {
    summary = await reconcileAll(
      createSupabaseReconciliationPort(db.client),
      ["m1", "m2", "m3"].map((id) => staleInput(id)),
    );
  } finally {
    logSpy.mock.restore();
  }
  assert.equal(summary.cancelled, 2);
  assert.equal(summary.errors, 1);
  assert.deepEqual(db.rows.map((r) => r.status), ["cancelled", "scheduled", "cancelled"]);
});

test("exceção de rede na do meio -> as outras continuam", async () => {
  const db = fakeMessagesDb([makeRow("m1"), makeRow("m2"), makeRow("m3")], {
    updateFailOnCall: { call: 2, mode: "throw" },
  });
  const logSpy = mock.method(console, "error", () => {});
  let summary;
  try {
    summary = await reconcileAll(
      createSupabaseReconciliationPort(db.client),
      ["m1", "m2", "m3"].map((id) => revokedInput(id)),
    );
  } finally {
    logSpy.mock.restore();
  }
  assert.equal(summary.cancelled, 2);
  assert.equal(summary.errors, 1);
});

test("uma virou processing no meio (corrida com o dispatch) -> alreadyNotScheduled, processing intacta, lote continua", async () => {
  const db = fakeMessagesDb([makeRow("m1"), makeRow("m2"), makeRow("m3")], {
    beforeUpdate: (call, rows) => {
      if (call === 2) rows[1].status = "processing";
    },
  });
  const summary = await reconcileAll(
    createSupabaseReconciliationPort(db.client),
    ["m1", "m2", "m3"].map((id) => staleInput(id)),
  );
  assert.equal(summary.cancelled, 2);
  assert.equal(summary.alreadyNotScheduled, 1);
  assert.equal(summary.errors, 0);
  assert.deepEqual(db.rows.map((r) => r.status), ["cancelled", "processing", "cancelled"]);
});

test("mensagem sumida do banco no meio -> notFound, lote continua", async () => {
  const db = fakeMessagesDb([makeRow("m1"), makeRow("m3")]); // m2 não existe
  const summary = await reconcileAll(
    createSupabaseReconciliationPort(db.client),
    ["m1", "m2", "m3"].map((id) => staleInput(id)),
  );
  assert.equal(summary.cancelled, 2);
  assert.equal(summary.notFound, 1);
});

test("mensagens fora de scheduled (processing/failed/sent/...) nunca viram UPDATE nem mudam, mesmo com tudo inválido", async () => {
  const statuses = ["processing", "failed", "sent", "delivered", "read", "cancelled"] as const;
  const db = fakeMessagesDb(statuses.map((s, i) => makeRow(`m${i}`, s)));
  const inputs = statuses.map((s, i) => ({
    ...staleInput(`m${i}`),
    message: { ...staleInput(`m${i}`).message, status: s },
    consent: { id: `consent-m${i}`, revokedAt: REVOKED },
  }));
  const summary = await reconcileAll(createSupabaseReconciliationPort(db.client), inputs);
  assert.equal(summary.unchanged, statuses.length);
  assert.equal(summary.cancelled, 0);
  assert.equal(db.calls.update, 0, "nenhum UPDATE sequer tentado");
  assert.deepEqual(db.rows.map((r) => r.status), [...statuses]);
});

test("o summary não contém PII (telefone, ids de linha, consentId, patientId) mesmo com falhas", async () => {
  const db = fakeMessagesDb([makeRow("m1"), makeRow("m2"), makeRow("m3", "sent")], {
    updateFailOnCall: { call: 2, mode: "error" },
  });
  const logSpy = mock.method(console, "error", () => {});
  let summary;
  let logs: string[] = [];
  try {
    summary = await reconcileAll(
      createSupabaseReconciliationPort(db.client),
      [staleInput("m1"), staleInput("m2"), blockedInput("m3")],
    );
  } finally {
    logs = logSpy.mock.calls.map((c) => c.arguments.join(" "));
    logSpy.mock.restore();
  }
  const serialized = JSON.stringify(summary);
  for (const secret of [FAKE_PHONE, "consent-m", "patient-1", "appt-m", "m1", "m2", "m3", "57014"]) {
    assert.ok(!serialized.includes(secret), `summary vazou ${secret}`);
  }
  const everything = serialized + logs.join("\n");
  for (const secret of [FAKE_PHONE, "consent-m", "patient-1", "57014"]) {
    assert.ok(!everything.includes(secret), `vazou ${secret}`);
  }
  assert.deepEqual(Object.keys(summary!).sort(), [
    "alreadyNotScheduled",
    "blocked",
    "blockedByReason",
    "cancelled",
    "cancelledByReason",
    "candidates",
    "errors",
    "notFound",
    "unchanged",
  ]);
});
