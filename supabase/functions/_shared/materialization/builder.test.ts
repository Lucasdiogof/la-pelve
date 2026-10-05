import { test } from "node:test";
import assert from "node:assert/strict";
import { buildMaterializableMessage } from "./builder.ts";
import type { SchedulerDecision } from "../scheduler/decision.ts";

const FISIO = "fisio-1";
const PATIENT = { id: "patient-1", phoneE164: "+5562999999999" };
const CONSENT = { id: "consent-1", contactValue: "+5562999999999" };

function decision(overrides: Partial<SchedulerDecision> = {}): SchedulerDecision {
  return {
    eligible: true,
    messageType: "appointment_confirmation",
    appointmentId: "appt-1",
    scheduleRevision: 0,
    scheduledFor: "2026-10-10T17:00:00.000Z",
    reason: null,
    ...overrides,
  };
}

// ---------------------------------------------------------------------
// 1-3. Decisions elegíveis de cada tipo -> MaterializableMessage correto.
// ---------------------------------------------------------------------

test("1: eligible confirmation -> MaterializableMessage correto", () => {
  const msg = buildMaterializableMessage({
    decision: decision({ messageType: "appointment_confirmation", scheduleRevision: 0 }),
    fisioterapeutaId: FISIO,
    patient: PATIENT,
    consent: CONSENT,
  });
  assert.deepEqual(msg, {
    fisioterapeutaId: FISIO,
    patientId: "patient-1",
    appointmentId: "appt-1",
    reminderType: "appointment_confirmation",
    scheduleRevision: 0,
    scheduledFor: "2026-10-10T17:00:00.000Z",
    destinationPhoneE164: "+5562999999999",
    consentId: "consent-1",
  });
});

test("2: eligible appointment_12h -> correto", () => {
  const msg = buildMaterializableMessage({
    decision: decision({ messageType: "appointment_12h", scheduleRevision: 0 }),
    fisioterapeutaId: FISIO,
    patient: PATIENT,
    consent: CONSENT,
  });
  assert.equal(msg.reminderType, "appointment_12h");
});

test("3: eligible rescheduled -> correto", () => {
  const msg = buildMaterializableMessage({
    decision: decision({ messageType: "appointment_rescheduled", scheduleRevision: 2 }),
    fisioterapeutaId: FISIO,
    patient: PATIENT,
    consent: CONSENT,
  });
  assert.equal(msg.reminderType, "appointment_rescheduled");
  assert.equal(msg.scheduleRevision, 2);
});

// ---------------------------------------------------------------------
// 4-10. Defesa em profundidade: contexto inconsistente -> lança.
// ---------------------------------------------------------------------

test("4: decision inelegível -> builder rejeita (lança)", () => {
  assert.throws(
    () =>
      buildMaterializableMessage({
        decision: decision({ eligible: false, reason: "missing_consent" }),
        fisioterapeutaId: FISIO,
        patient: PATIENT,
        consent: CONSENT,
      }),
    TypeError,
  );
});

test("5: scheduledFor null numa decision marcada elegível -> rejeita", () => {
  // Construído manualmente para simular o estado "impossível" -- a
  // lógica pura real nunca produz isto, mas o builder não deve confiar
  // ciegamente no contrato de quem chama.
  const brokenDecision = { ...decision(), scheduledFor: null } as unknown as SchedulerDecision;
  assert.throws(
    () =>
      buildMaterializableMessage({
        decision: brokenDecision,
        fisioterapeutaId: FISIO,
        patient: PATIENT,
        consent: CONSENT,
      }),
    TypeError,
  );
});

test("6: patient ausente -> rejeita", () => {
  assert.throws(
    () =>
      buildMaterializableMessage({
        decision: decision(),
        fisioterapeutaId: FISIO,
        patient: null,
        consent: CONSENT,
      }),
    TypeError,
  );
});

test("7: consent ausente -> rejeita", () => {
  assert.throws(
    () =>
      buildMaterializableMessage({
        decision: decision(),
        fisioterapeutaId: FISIO,
        patient: PATIENT,
        consent: null,
      }),
    TypeError,
  );
});

test("8: consentId ausente -> rejeita", () => {
  assert.throws(
    () =>
      buildMaterializableMessage({
        decision: decision(),
        fisioterapeutaId: FISIO,
        patient: PATIENT,
        consent: { id: "", contactValue: "+5562999999999" },
      }),
    TypeError,
  );
});

test("9: phone ausente -> rejeita", () => {
  assert.throws(
    () =>
      buildMaterializableMessage({
        decision: decision(),
        fisioterapeutaId: FISIO,
        patient: { id: "patient-1", phoneE164: null },
        consent: CONSENT,
      }),
    TypeError,
  );
});

test("10: consent.contactValue != patient.phoneE164 -> rejeita", () => {
  assert.throws(
    () =>
      buildMaterializableMessage({
        decision: decision(),
        fisioterapeutaId: FISIO,
        patient: PATIENT,
        consent: { id: "consent-1", contactValue: "+5562988888888" },
      }),
    TypeError,
  );
});

// ---------------------------------------------------------------------
// 11-13. Origem e preservação exata dos campos.
// ---------------------------------------------------------------------

test("11: destinationPhoneE164 vem de consent.contactValue (não de patient.phoneE164 diretamente)", () => {
  // patient.phoneE164 e consent.contactValue são obrigatoriamente iguais
  // (regra validada acima) -- este teste confirma que o CAMPO DE ORIGEM
  // no código é consent.contactValue, não patient.phoneE164, lendo a
  // implementação através de um caso onde eles diferem (deve rejeitar,
  // já coberto no teste 10) e onde são iguais (deve usar exatamente o
  // valor do consent).
  const msg = buildMaterializableMessage({
    decision: decision(),
    fisioterapeutaId: FISIO,
    patient: PATIENT,
    consent: CONSENT,
  });
  assert.equal(msg.destinationPhoneE164, CONSENT.contactValue);
});

test("12: scheduleRevision preservada exatamente", () => {
  const msg = buildMaterializableMessage({
    decision: decision({ scheduleRevision: 7 }),
    fisioterapeutaId: FISIO,
    patient: PATIENT,
    consent: CONSENT,
  });
  assert.equal(msg.scheduleRevision, 7);
});

test("13: scheduledFor preservado exatamente (mesma string, sem reformatar)", () => {
  const iso = "2026-12-25T03:07:11.123Z";
  const msg = buildMaterializableMessage({
    decision: decision({ scheduledFor: iso }),
    fisioterapeutaId: FISIO,
    patient: PATIENT,
    consent: CONSENT,
  });
  assert.equal(msg.scheduledFor, iso);
});

// ---------------------------------------------------------------------
// 19. connectionReady nunca existe neste objeto (estrutural).
// ---------------------------------------------------------------------

test("19 (estrutural): MaterializableMessage não tem connectionReady nem nenhum campo de conexão", () => {
  const msg = buildMaterializableMessage({
    decision: decision(),
    fisioterapeutaId: FISIO,
    patient: PATIENT,
    consent: CONSENT,
  });
  const keys = Object.keys(msg).sort();
  assert.deepEqual(keys, [
    "appointmentId",
    "consentId",
    "destinationPhoneE164",
    "fisioterapeutaId",
    "patientId",
    "reminderType",
    "scheduleRevision",
    "scheduledFor",
  ]);
});
