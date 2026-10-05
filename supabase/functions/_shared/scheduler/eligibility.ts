// Elegibilidade do paciente para receber mensagens de WhatsApp. Pura: só
// recebe os dados já lidos do banco (nunca consulta nada aqui).

export type IneligibleReason =
  | "missing_patient"
  | "invalid_phone"
  | "missing_consent"
  | "consent_phone_mismatch";

export interface PatientForEligibility {
  id: string;
  fisioterapeutaId: string;
  phoneE164: string | null;
}

export interface ConsentForEligibility {
  channel: string;
  purpose: string;
  contactValue: string;
  revokedAt: string | null;
}

export interface EligibilityInput {
  appointmentPatientId: string | null;
  appointmentFisioterapeutaId: string;
  patient: PatientForEligibility | null;
  consent: ConsentForEligibility | null;
}

export type EligibilityResult =
  | { eligible: true }
  | { eligible: false; reason: IneligibleReason };

/**
 * appointment.patient_id precisa existir; o paciente precisa existir e
 * pertencer ao mesmo fisioterapeuta da consulta; patients.phone_e164
 * precisa ser válido; precisa existir patient_consents ATIVO
 * (channel=whatsapp, purpose=appointment_reminder, revoked_at IS NULL)
 * cujo contact_value seja EXATAMENTE igual ao phone_e164 atual.
 */
export function checkPatientEligibility(input: EligibilityInput): EligibilityResult {
  if (input.appointmentPatientId === null) {
    return { eligible: false, reason: "missing_patient" };
  }
  if (
    input.patient === null ||
    input.patient.id !== input.appointmentPatientId ||
    input.patient.fisioterapeutaId !== input.appointmentFisioterapeutaId
  ) {
    return { eligible: false, reason: "missing_patient" };
  }
  if (input.patient.phoneE164 === null) {
    return { eligible: false, reason: "invalid_phone" };
  }
  const consent = input.consent;
  const hasActiveWhatsappConsent =
    consent !== null &&
    consent.channel === "whatsapp" &&
    consent.purpose === "appointment_reminder" &&
    consent.revokedAt === null;
  if (!hasActiveWhatsappConsent) {
    return { eligible: false, reason: "missing_consent" };
  }
  if (consent.contactValue !== input.patient.phoneE164) {
    return { eligible: false, reason: "consent_phone_mismatch" };
  }
  return { eligible: true };
}
