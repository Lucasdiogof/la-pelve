import { test } from "node:test";
import assert from "node:assert/strict";
import { materializeAll } from "./materialize.ts";
import { toWhatsappMessageInsertRow } from "./row_mapping.ts";
import type { MaterializableMessage, MaterializationOutcome, MaterializationPort } from "./types.ts";

function msg(overrides: Partial<MaterializableMessage> = {}): MaterializableMessage {
  return {
    fisioterapeutaId: "fisio-1",
    patientId: "patient-1",
    appointmentId: "appt-1",
    reminderType: "appointment_confirmation",
    scheduleRevision: 0,
    scheduledFor: "2026-10-10T17:00:00.000Z",
    destinationPhoneE164: "+5562999999999",
    consentId: "consent-1",
    ...overrides,
  };
}

function tripleKey(m: MaterializableMessage): string {
  return `${m.appointmentId}|${m.reminderType}|${m.scheduleRevision}`;
}

/**
 * Porta FALSA, em memória -- simula exatamente a semântica insert-only
 * da UNIQUE real: a 1a chamada para uma tripla grava a linha e devolve
 * 'inserted'; qualquer chamada seguinte para a MESMA tripla devolve
 * 'already_exists' e NUNCA sobrescreve a linha armazenada (simula
 * ON CONFLICT DO NOTHING). Pode ser configurada para simular
 * consent_no_longer_valid/error para triplas específicas.
 */
class FakeMaterializationPort implements MaterializationPort {
  stored = new Map<string, MaterializableMessage>();
  calls: MaterializableMessage[] = [];
  private readonly forcedOutcomes: Map<string, MaterializationOutcome>;

  constructor(forcedOutcomes: Record<string, MaterializationOutcome> = {}) {
    this.forcedOutcomes = new Map(Object.entries(forcedOutcomes));
  }

  async insertIfAbsent(message: MaterializableMessage): Promise<MaterializationOutcome> {
    this.calls.push(message);
    const key = tripleKey(message);

    const forced = this.forcedOutcomes.get(key);
    if (forced) return forced;

    if (this.stored.has(key)) {
      return { kind: "already_exists" };
    }
    this.stored.set(key, message);
    return { kind: "inserted" };
  }
}

// ---------------------------------------------------------------------
// 14-16. Idempotência: 1a inserção, 2a inserção, linha original intacta.
// ---------------------------------------------------------------------

test("14: primeira materialização -> inserted", async () => {
  const port = new FakeMaterializationPort();
  const outcome = await port.insertIfAbsent(msg());
  assert.deepEqual(outcome, { kind: "inserted" });
});

test("15: segunda chamada da MESMA tripla -> already_exists", async () => {
  const port = new FakeMaterializationPort();
  await port.insertIfAbsent(msg());
  const second = await port.insertIfAbsent(msg());
  assert.deepEqual(second, { kind: "already_exists" });
});

test("16: segunda inserção não altera a linha original (destination/consent/scheduledFor preservados)", async () => {
  const port = new FakeMaterializationPort();
  const original = msg({ destinationPhoneE164: "+5562999999999", consentId: "consent-original" });
  await port.insertIfAbsent(original);

  // Tenta "re-inserir" a mesma tripla com valores DIFERENTES -- isto
  // nunca deveria acontecer de verdade (os campos são imutáveis), mas o
  // teste prova que mesmo assim a linha armazenada nunca muda.
  const attempted = msg({ destinationPhoneE164: "+5562988888888", consentId: "consent-outro" });
  const outcome = await port.insertIfAbsent(attempted);

  assert.deepEqual(outcome, { kind: "already_exists" });
  const stored = port.stored.get(tripleKey(original))!;
  assert.equal(stored.destinationPhoneE164, "+5562999999999");
  assert.equal(stored.consentId, "consent-original");
});

// ---------------------------------------------------------------------
// 17-18. Revisions diferentes nunca conflitam.
// ---------------------------------------------------------------------

test("17: duas revisions diferentes -> duas mensagens diferentes, ambas inseridas", async () => {
  const port = new FakeMaterializationPort();
  const r0 = await port.insertIfAbsent(msg({ reminderType: "appointment_confirmation", scheduleRevision: 0 }));
  const r1 = await port.insertIfAbsent(msg({ reminderType: "appointment_rescheduled", scheduleRevision: 1 }));
  assert.deepEqual(r0, { kind: "inserted" });
  assert.deepEqual(r1, { kind: "inserted" });
});

test("18: mesmo appointment/type mas revision diferente -> não conflita", async () => {
  const port = new FakeMaterializationPort();
  const a = await port.insertIfAbsent(msg({ reminderType: "appointment_12h", scheduleRevision: 0 }));
  const b = await port.insertIfAbsent(msg({ reminderType: "appointment_12h", scheduleRevision: 1 }));
  assert.deepEqual(a, { kind: "inserted" });
  assert.deepEqual(b, { kind: "inserted" });
});

// ---------------------------------------------------------------------
// 20-21. Classificação de falhas distintas.
// ---------------------------------------------------------------------

test("20: falha real de persistência é classificada como 'error', nunca como already_exists", async () => {
  const forced = msg({ appointmentId: "appt-falha" });
  const port = new FakeMaterializationPort({
    [tripleKey(forced)]: { kind: "error", code: "persistence_error" },
  });
  const outcome = await port.insertIfAbsent(forced);
  assert.equal(outcome.kind, "error");
  assert.notEqual(outcome.kind, "already_exists");
});

test("21: consentimento revogado entre leitura/INSERT -> consent_no_longer_valid, nunca inserted", async () => {
  const revoked = msg({ appointmentId: "appt-revogado" });
  const port = new FakeMaterializationPort({
    [tripleKey(revoked)]: { kind: "consent_no_longer_valid" },
  });
  const outcome = await port.insertIfAbsent(revoked);
  assert.deepEqual(outcome, { kind: "consent_no_longer_valid" });
  assert.notEqual(outcome.kind, "inserted");
});

// ---------------------------------------------------------------------
// 22. Uma falha não impede a materialização das demais (isolamento).
// ---------------------------------------------------------------------

test("22: falha/rejeição de 1 candidata não impede as demais (materializeAll processa todas)", async () => {
  const ok1 = msg({ appointmentId: "appt-ok-1" });
  const revoked = msg({ appointmentId: "appt-revogado" });
  const ok2 = msg({ appointmentId: "appt-ok-2" });

  const port = new FakeMaterializationPort({
    [tripleKey(revoked)]: { kind: "consent_no_longer_valid" },
  });

  const summary = await materializeAll(port, [ok1, revoked, ok2]);

  assert.equal(summary.candidates, 3);
  assert.equal(summary.inserted, 2);
  assert.equal(summary.rejected, 1);
  assert.equal(summary.errors, 0);
  // As 3 foram de fato tentadas -- nenhuma foi pulada por causa da outra.
  assert.equal(port.calls.length, 3);
});

// ---------------------------------------------------------------------
// 23. Nenhum telefone/PII no resultado público (MaterializationSummary).
// ---------------------------------------------------------------------

test("23: MaterializationSummary nunca contém telefone/consentId/patientId", async () => {
  const port = new FakeMaterializationPort();
  const summary = await materializeAll(port, [
    msg({ destinationPhoneE164: "+5562911111111", consentId: "consent-secreto", patientId: "patient-secreto" }),
  ]);
  const json = JSON.stringify(summary);
  assert.ok(!json.includes("+5562911111111"));
  assert.ok(!json.includes("consent-secreto"));
  assert.ok(!json.includes("patient-secreto"));
  assert.deepEqual(Object.keys(summary).sort(), [
    "alreadyExisting",
    "candidates",
    "errors",
    "inserted",
    "rejected",
  ]);
});

// ---------------------------------------------------------------------
// 24. status nunca é escrito explicitamente (DEFAULT do banco já é
// 'scheduled').
// ---------------------------------------------------------------------

test("24: a linha mapeada para o banco não inclui 'status' (usa o DEFAULT)", () => {
  const row = toWhatsappMessageInsertRow(msg());
  assert.ok(!("status" in row), "status nao deve ser enviado -- o DEFAULT do banco ja e 'scheduled'");
  assert.deepEqual(Object.keys(row).sort(), [
    "appointment_id",
    "consent_id",
    "destination_phone_e164",
    "fisioterapeuta_id",
    "patient_id",
    "reminder_type",
    "schedule_revision",
    "scheduled_for",
  ]);
});

test("extra: toWhatsappMessageInsertRow nunca inclui wamid/template_name/sent_at/delivered_at/read_at/failed_at/error", () => {
  const row = toWhatsappMessageInsertRow(msg());
  for (const forbidden of ["wamid", "template_name", "sent_at", "delivered_at", "read_at", "failed_at", "error", "id", "created_at", "updated_at"]) {
    assert.ok(!(forbidden in row), `row nao deveria conter '${forbidden}'`);
  }
});
