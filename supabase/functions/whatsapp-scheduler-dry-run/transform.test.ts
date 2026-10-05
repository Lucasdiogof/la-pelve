import { test } from "node:test";
import assert from "node:assert/strict";
import {
  computeConnectionDiagnostics,
  isValidIanaTimeZone,
  pickActiveConsent,
  toAppointmentForScheduling,
  toConsentForEligibility,
  toPatientForEligibility,
} from "./transform.ts";
import type { AppointmentRow, ConnectionRow, ConsentRow, PatientRow } from "./types.ts";

const appointmentRow: AppointmentRow = {
  id: "appt-1",
  fisioterapeuta_id: "fisio-1",
  date: "2026-10-10",
  time: "14:00:00",
  status: "scheduled",
  patient_id: "patient-1",
  schedule_revision: 0,
  schedule_revision_at: "2026-10-09T18:00:00-03:00",
};

// ---------------------------------------------------------------------
// 1. appointment completo -> SchedulingInput (campo a campo).
// ---------------------------------------------------------------------
test("1: toAppointmentForScheduling mapeia todos os campos corretamente", () => {
  assert.deepEqual(toAppointmentForScheduling(appointmentRow), {
    id: "appt-1",
    fisioterapeutaId: "fisio-1",
    date: "2026-10-10",
    time: "14:00:00",
    status: "scheduled",
    patientId: "patient-1",
    scheduleRevision: 0,
    scheduleRevisionAt: "2026-10-09T18:00:00-03:00",
  });
});

// ---------------------------------------------------------------------
// 3/5. patient inexistente / soft-deleted: ambos chegam como `undefined`
// no lote carregado (a query já filtra deleted_at IS NULL), então
// toPatientForEligibility(undefined) -> null nos dois casos.
// ---------------------------------------------------------------------
test("3 e 5: patient ausente do lote (inexistente OU soft-deleted) -> null", () => {
  assert.equal(toPatientForEligibility(undefined), null);
});

test("4: patient de outro fisioterapeuta é preservado na transformação (quem decide é a lógica pura)", () => {
  const row: PatientRow = {
    id: "patient-1",
    fisioterapeuta_id: "outro-fisio",
    phone_e164: "+5562999999999",
    deleted_at: null,
  };
  assert.deepEqual(toPatientForEligibility(row), {
    id: "patient-1",
    fisioterapeutaId: "outro-fisio",
    phoneE164: "+5562999999999",
  });
});

// ---------------------------------------------------------------------
// 6. phone_e164 null é preservado (não é a transformação que decide).
// ---------------------------------------------------------------------
test("6: phone_e164 null é preservado pela transformação", () => {
  const row: PatientRow = { id: "p1", fisioterapeuta_id: "f1", phone_e164: null, deleted_at: null };
  assert.equal(toPatientForEligibility(row)!.phoneE164, null);
});

// ---------------------------------------------------------------------
// 7/11. pickActiveConsent: lista vazia -> null; 1 item -> ele mesmo;
// contact_value é preservado tal como veio (consent_phone_mismatch é
// decidido pela lógica pura, não aqui).
// ---------------------------------------------------------------------
test("7: pickActiveConsent([]) -> null (sem consentimento ativo)", () => {
  assert.equal(pickActiveConsent([]), null);
});

test("11: contact_value é preservado tal como veio do banco", () => {
  const row: ConsentRow = {
    id: "c1",
    patient_id: "p1",
    fisioterapeuta_id: "f1",
    channel: "whatsapp",
    purpose: "appointment_reminder",
    contact_value: "+5562988888888",
    granted_at: "2026-01-01T00:00:00Z",
    revoked_at: null,
  };
  assert.equal(toConsentForEligibility(pickActiveConsent([row]))!.contactValue, "+5562988888888");
});

test("pickActiveConsent: >1 linha ativa simultânea -> lança erro de integridade (nunca escolhe uma silenciosamente)", () => {
  // Pelo índice único parcial patient_consents_one_active_key
  // (patient_id, channel, purpose) WHERE revoked_at IS NULL, confirmado
  // válido e ativo em produção, isto é um estado IMPOSSÍVEL -- nunca deve
  // ser tratado como "escolher o mais recente".
  const a: ConsentRow = {
    id: "aaa",
    patient_id: "p1",
    fisioterapeuta_id: "f1",
    channel: "whatsapp",
    purpose: "appointment_reminder",
    contact_value: "+5562999999999",
    granted_at: "2026-01-01T00:00:00Z",
    revoked_at: null,
  };
  const b: ConsentRow = { ...a, id: "bbb", granted_at: "2026-06-01T00:00:00Z" };
  assert.throws(() => pickActiveConsent([a, b]), /integridade violada/);
  assert.throws(() => pickActiveConsent([a, b, { ...a, id: "ccc" }]), /integridade violada/);
});

test("9: erro de integridade é genérico -- nunca inclui patient_id, telefone ou contact_value", () => {
  const a: ConsentRow = {
    id: "aaa",
    patient_id: "patient-secreto-123",
    fisioterapeuta_id: "f1",
    channel: "whatsapp",
    purpose: "appointment_reminder",
    contact_value: "+5562999999999",
    granted_at: "2026-01-01T00:00:00Z",
    revoked_at: null,
  };
  try {
    pickActiveConsent([a, { ...a, id: "bbb" }]);
    assert.fail("esperava throw");
  } catch (err) {
    const message = (err as Error).message;
    assert.equal(message, "integridade violada: múltiplos consentimentos ativos simultâneos");
    assert.ok(!message.includes("patient-secreto-123"));
    assert.ok(!message.includes("+5562999999999"));
  }
});

// ---------------------------------------------------------------------
// 13/14/15. connectionReady.
// ---------------------------------------------------------------------
test("13: connection inexistente -> connectionStatus='none', connectionReady=false", () => {
  assert.deepEqual(computeConnectionDiagnostics(undefined), {
    connectionStatus: "none",
    connectionReady: false,
  });
});

test("14: connection pending -> connectionReady=false", () => {
  const row: ConnectionRow = { fisioterapeuta_id: "f1", status: "pending", phone_number_id: null };
  assert.deepEqual(computeConnectionDiagnostics(row), {
    connectionStatus: "pending",
    connectionReady: false,
  });
});

test("15: connection connected com phone_number_id -> connectionReady=true", () => {
  const row: ConnectionRow = { fisioterapeuta_id: "f1", status: "connected", phone_number_id: "123456" };
  assert.deepEqual(computeConnectionDiagnostics(row), {
    connectionStatus: "connected",
    connectionReady: true,
  });
});

test("connection connected SEM phone_number_id -> connectionReady=false (os dois precisam valer)", () => {
  const row: ConnectionRow = { fisioterapeuta_id: "f1", status: "connected", phone_number_id: null };
  assert.equal(computeConnectionDiagnostics(row).connectionReady, false);
});

// ---------------------------------------------------------------------
// Timezone inválida: erro de dados, nunca adivinhado.
// ---------------------------------------------------------------------
test("isValidIanaTimeZone: timezone válida", () => {
  assert.equal(isValidIanaTimeZone("America/Sao_Paulo"), true);
});

test("isValidIanaTimeZone: timezone inválida -> false (nunca lança, nunca adivinha)", () => {
  assert.equal(isValidIanaTimeZone("Nao/Existe"), false);
  assert.equal(isValidIanaTimeZone(""), false);
});
