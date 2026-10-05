import { test } from "node:test";
import assert from "node:assert/strict";
import { checkPatientEligibility } from "./eligibility.ts";

const fisio = "fisio-1";
const patient = { id: "patient-1", fisioterapeutaId: fisio, phoneE164: "+5562999999999" };
const activeConsent = {
  channel: "whatsapp",
  purpose: "appointment_reminder",
  contactValue: "+5562999999999",
  revokedAt: null,
};

test("elegível: paciente, telefone e consentimento todos corretos", () => {
  const result = checkPatientEligibility({
    appointmentPatientId: patient.id,
    appointmentFisioterapeutaId: fisio,
    patient,
    consent: activeConsent,
  });
  assert.deepEqual(result, { eligible: true });
});

test("patient_id nulo -> missing_patient", () => {
  const result = checkPatientEligibility({
    appointmentPatientId: null,
    appointmentFisioterapeutaId: fisio,
    patient: null,
    consent: null,
  });
  assert.deepEqual(result, { eligible: false, reason: "missing_patient" });
});

test("paciente não encontrado -> missing_patient", () => {
  const result = checkPatientEligibility({
    appointmentPatientId: "patient-1",
    appointmentFisioterapeutaId: fisio,
    patient: null,
    consent: activeConsent,
  });
  assert.deepEqual(result, { eligible: false, reason: "missing_patient" });
});

test("paciente de outro fisioterapeuta -> missing_patient", () => {
  const result = checkPatientEligibility({
    appointmentPatientId: patient.id,
    appointmentFisioterapeutaId: fisio,
    patient: { ...patient, fisioterapeutaId: "outro-fisio" },
    consent: activeConsent,
  });
  assert.deepEqual(result, { eligible: false, reason: "missing_patient" });
});

test("phone_e164 nulo -> invalid_phone", () => {
  const result = checkPatientEligibility({
    appointmentPatientId: patient.id,
    appointmentFisioterapeutaId: fisio,
    patient: { ...patient, phoneE164: null },
    consent: activeConsent,
  });
  assert.deepEqual(result, { eligible: false, reason: "invalid_phone" });
});

test("sem consentimento -> missing_consent", () => {
  const result = checkPatientEligibility({
    appointmentPatientId: patient.id,
    appointmentFisioterapeutaId: fisio,
    patient,
    consent: null,
  });
  assert.deepEqual(result, { eligible: false, reason: "missing_consent" });
});

test("consentimento revogado -> missing_consent", () => {
  const result = checkPatientEligibility({
    appointmentPatientId: patient.id,
    appointmentFisioterapeutaId: fisio,
    patient,
    consent: { ...activeConsent, revokedAt: "2026-01-01T00:00:00Z" },
  });
  assert.deepEqual(result, { eligible: false, reason: "missing_consent" });
});

test("consentimento de outro canal/finalidade -> missing_consent", () => {
  const result = checkPatientEligibility({
    appointmentPatientId: patient.id,
    appointmentFisioterapeutaId: fisio,
    patient,
    consent: { ...activeConsent, purpose: "marketing" },
  });
  assert.deepEqual(result, { eligible: false, reason: "missing_consent" });
});

test("consentimento ativo para número diferente do atual -> consent_phone_mismatch", () => {
  const result = checkPatientEligibility({
    appointmentPatientId: patient.id,
    appointmentFisioterapeutaId: fisio,
    patient,
    consent: { ...activeConsent, contactValue: "+5562988888888" },
  });
  assert.deepEqual(result, { eligible: false, reason: "consent_phone_mismatch" });
});
