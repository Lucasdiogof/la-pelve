// Tipos da camada de materialização: transformar uma SchedulerDecision
// elegível numa linha de whatsapp_messages, de forma insert-only e
// idempotente. Nenhum I/O aqui -- só forma.

import type { MessageType } from "../scheduler/decision.ts";

/**
 * Objeto interno que representa "isto deveria se tornar uma linha de
 * whatsapp_messages". NÃO é resposta pública: carrega
 * destinationPhoneE164 e consentId, que nunca devem ser serializados em
 * logs ou agregados devolvidos a um caller externo (ver materialize.ts /
 * MaterializationSummary, que só expõe contagens).
 */
export interface MaterializableMessage {
  fisioterapeutaId: string;
  patientId: string;
  appointmentId: string;
  reminderType: MessageType;
  scheduleRevision: number;
  /** ISO 8601 UTC -- vem exatamente de decision.scheduledFor, nunca recalculado aqui. */
  scheduledFor: string;
  /** Snapshot IMUTÁVEL do destino autorizado -- vem de consent.contactValue, nunca de uma releitura de patients.phoneE164. */
  destinationPhoneE164: string;
  /** patient_consents.id que autorizou destinationPhoneE164. */
  consentId: string;
}

/**
 * Resultado de uma tentativa de materializar 1 mensagem.
 *
 * `error.code` é um código INTERNO genérico (ex.: "persistence_error"),
 * nunca o texto bruto de error.message do PostgREST/Postgres -- aquele
 * texto pode (em teoria, por engano de alguma dependência futura) conter
 * detalhes da linha que falhou; por isso nunca é propagado para fora do
 * adapter. Um diagnóstico sanitizado (sem telefone/consentId/patientId)
 * pode ser logado INTERNAMENTE pelo adapter, nunca devolvido aqui.
 */
export type MaterializationOutcome =
  | { kind: "inserted" }
  | { kind: "already_exists" }
  | { kind: "consent_no_longer_valid" }
  | { kind: "error"; code: "persistence_error" };

/**
 * Porta de persistência: a camada de negócio não conhece PostgREST/
 * Supabase. insertIfAbsent NUNCA lança -- qualquer falha vira um
 * MaterializationOutcome classificado, para que materializeAll nunca
 * precise de try/catch e uma falha numa mensagem nunca aborte as demais.
 */
export interface MaterializationPort {
  insertIfAbsent(message: MaterializableMessage): Promise<MaterializationOutcome>;
}

/** Agregado público -- nunca contém telefone/consentId/nomes. */
export interface MaterializationSummary {
  candidates: number;
  inserted: number;
  alreadyExisting: number;
  rejected: number;
  errors: number;
}
