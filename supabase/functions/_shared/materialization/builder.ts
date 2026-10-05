// Builder PURO: combina uma SchedulerDecision elegível + contexto já
// carregado pela orquestração (patient, consent, fisioterapeutaId) num
// MaterializableMessage. Nenhum I/O. Nunca lê patients.phone_e164 de
// novo -- destinationPhoneE164 vem exclusivamente de consent.contactValue.

import type { SchedulerDecision } from "../scheduler/decision.ts";
import type { MaterializableMessage } from "./types.ts";

export interface PatientContextForMaterialization {
  id: string;
  phoneE164: string | null;
}

export interface ConsentContextForMaterialization {
  id: string;
  contactValue: string;
}

export interface BuildMaterializableMessageInput {
  decision: SchedulerDecision;
  /** appointments.fisioterapeuta_id -- não vem da decision (que não carrega isso de propósito). */
  fisioterapeutaId: string;
  patient: PatientContextForMaterialization | null;
  /** O consentimento ATIVO já selecionado pela orquestração (ver pickActiveConsent em whatsapp-scheduler-dry-run). */
  consent: ConsentContextForMaterialization | null;
}

/**
 * Lança (nunca devolve null/reason) quando o contexto é internamente
 * inconsistente -- isto representa um BUG de quem montou o input, não um
 * cenário de negócio. A lógica pura do scheduler já decidiu elegibilidade
 * antes disto rodar; se decision.eligible for false aqui, ou faltar
 * dado que deveria necessariamente existir para uma decision elegível,
 * algo na camada de orquestração está quebrado. Nenhuma mensagem de erro
 * inclui patientId/telefone/consentId -- só os identificadores já
 * públicos (appointmentId/messageType), suficientes para diagnóstico.
 */
export function buildMaterializableMessage(
  input: BuildMaterializableMessageInput,
): MaterializableMessage {
  const { decision, fisioterapeutaId, patient, consent } = input;

  if (!decision.eligible) {
    throw new TypeError(
      `buildMaterializableMessage: decision nao elegivel (reason=${decision.reason}) para ` +
        `appointment=${decision.appointmentId} messageType=${decision.messageType} -- bug de quem ` +
        `chamou o builder, nunca materialize uma decision inelegivel.`,
    );
  }
  if (!decision.scheduledFor) {
    throw new TypeError(
      `buildMaterializableMessage: scheduledFor ausente numa decision elegivel (appointment=` +
        `${decision.appointmentId} messageType=${decision.messageType}) -- estado impossivel pelo ` +
        `contrato de SchedulerDecision.`,
    );
  }
  if (!fisioterapeutaId) {
    throw new TypeError("buildMaterializableMessage: fisioterapeutaId ausente.");
  }
  if (!patient || !patient.id) {
    throw new TypeError("buildMaterializableMessage: patient ausente ou sem id.");
  }
  if (!consent || !consent.id) {
    throw new TypeError("buildMaterializableMessage: consent ausente ou sem id.");
  }
  if (!patient.phoneE164) {
    throw new TypeError("buildMaterializableMessage: patient.phoneE164 ausente.");
  }
  if (consent.contactValue !== patient.phoneE164) {
    throw new TypeError(
      "buildMaterializableMessage: consent.contactValue difere de patient.phoneE164 -- " +
        "estado inconsistente, nao materializa (valores omitidos de proposito).",
    );
  }

  return {
    fisioterapeutaId,
    patientId: patient.id,
    appointmentId: decision.appointmentId,
    reminderType: decision.messageType,
    scheduleRevision: decision.scheduleRevision,
    scheduledFor: decision.scheduledFor,
    destinationPhoneE164: consent.contactValue,
    consentId: consent.id,
  };
}
