// Lógica PURA da reconciliação: dado o estado atual de uma mensagem, da
// consulta e do consentimento, devolve a AÇÃO (cancel / blocked / keep) e o
// porquê. Sem I/O, sem relógio, sem ler telefone.
//
// ---------------------------------------------------------------------
// POR QUE SÓ CONDIÇÕES MONOTÔNICAS CANCELAM (e por que não precisa de RPC)
// ---------------------------------------------------------------------
// whatsapp_messages.status='cancelled' é irreversível: a UNIQUE
// (appointment_id, reminder_type, schedule_revision) impede recriar a
// linha e o pre-check da materialização devolve already_exists para ela.
// Logo, só se cancela por condições que, uma vez verdadeiras, NUNCA voltam a
// ser falsas:
//   - stale_schedule_revision: appointments.schedule_revision só avança
//     (trigger: +1 em mudança de date/time; o cliente não define). A
//     mensagem guarda a revisão de quando nasceu e nunca muda.
//   - consent_revoked: o trigger patient_consents_only_revoke impede
//     revoked_at de voltar a NULL; um novo consentimento é OUTRA linha, e a
//     mensagem referencia o consentimento específico.
// Por isso uma leitura antiga dessas condições nunca pode "voltar a ser
// válida" antes do UPDATE: a corrida que exigiria uma RPC transacional não
// existe para elas. A única corrida real é com o dispatch (scheduled ->
// processing), coberta pelo WHERE status='scheduled' do UPDATE.
//
// appointments.status='cancelled', ao contrário, é REVERSÍVEL no produto
// (o seletor de status permite sair de cancelled; nenhum trigger/check
// impede). Por isso NÃO gera UPDATE: vira action='blocked' e a linha segue
// scheduled. Cancelar a mensagem por isso perderia o lembrete se a consulta
// fosse reativada.
//
// ---------------------------------------------------------------------
// PENDÊNCIAS REGISTRADAS (NÃO resolvidas nesta camada)
// ---------------------------------------------------------------------
// 1) DISPATCH: antes de scheduled -> processing, o dispatch futuro deve
//    verificar de forma segura: appointment ainda não está cancelled;
//    revisão ainda é a atual; consentimento ainda ativo; paciente não
//    soft-deleted; conexão WhatsApp pronta. A atomicidade dessa
//    reivindicação será desenhada na etapa de dispatch.
// 2) SOFT DELETE: patients.deleted_at hoje NÃO revoga o consentimento (nem
//    trigger no banco, nem código no app). O dispatch precisa bloquear
//    paciente soft-deleted, OU o fluxo Flutter de exclusão deve revogar o
//    consentimento/cancelar as mensagens. Fora do escopo desta camada
//    (não existe reason patient_deleted).
// 3) FLUTTER (bug separado): o formulário de edição de agendamento envia
//    `status` junto com os demais campos (snapshot velho) e pode sobrescrever
//    uma alteração concorrente feita em outro dispositivo. Correção Flutter
//    separada; não misturar com a reconciliação.
// ---------------------------------------------------------------------

import { isStaleRevision } from "../scheduler/decision.ts";
import type { ReconciliationDecision, ReconciliationInput } from "./types.ts";

export type IntegrityErrorCode =
  | "appointment_missing"
  | "consent_missing"
  | "appointment_mismatch"
  | "consent_mismatch";

/**
 * Input que viola a integridade esperada (FK/montagem do input): erro de
 * programação ou de dados, NUNCA um motivo normal de cancelamento. A
 * mensagem carrega só o código e o id da mensagem -- nada de PII.
 */
export class ReconciliationIntegrityError extends Error {
  readonly code: IntegrityErrorCode;
  readonly messageId: string;

  constructor(code: IntegrityErrorCode, messageId: string) {
    super(`reconciliation integrity error: ${code} (message ${messageId})`);
    this.name = "ReconciliationIntegrityError";
    this.code = code;
    this.messageId = messageId;
  }
}

/**
 * Só status 'scheduled' é reconciliável. Qualquer outro status volta
 * keep/not_cancellable_status ANTES de qualquer outra checagem: uma mensagem
 * processing/failed/sent/delivered/read/cancelled nunca é alterada aqui,
 * mesmo com consulta cancelada, revisão velha ou consentimento revogado --
 * e nem exige que appointment/consent estejam presentes no input.
 *
 * Para status 'scheduled', na ORDEM (determinística):
 *   1. integridade do input (appointment/consent ausentes ou com id que não
 *      bate com a referência da mensagem lançam ReconciliationIntegrityError,
 *      mesmo que outra condição já bastasse -- input quebrado deve aparecer,
 *      não ser mascarado);
 *   2. stale_schedule_revision  -> cancel  (permanente)
 *   3. consent_revoked          -> cancel  (permanente)
 *   4. appointment_cancelled    -> blocked (temporário, sem UPDATE)
 *   5. caso contrário           -> keep (reason null)
 * As condições permanentes vêm ANTES da temporária: uma consulta
 * temporariamente cancelada não pode manter viva uma mensagem que já é
 * permanentemente inválida.
 */
export function decideReconciliation(input: ReconciliationInput): ReconciliationDecision {
  const { message, appointment, consent } = input;

  if (message.status !== "scheduled") {
    return { action: "keep", reason: "not_cancellable_status" };
  }

  if (appointment === null) throw new ReconciliationIntegrityError("appointment_missing", message.id);
  if (consent === null) throw new ReconciliationIntegrityError("consent_missing", message.id);
  if (appointment.id !== message.appointmentId) {
    throw new ReconciliationIntegrityError("appointment_mismatch", message.id);
  }
  if (consent.id !== message.consentId) {
    throw new ReconciliationIntegrityError("consent_mismatch", message.id);
  }

  if (isStaleRevision(message.scheduleRevision, appointment.scheduleRevision)) {
    return { action: "cancel", reason: "stale_schedule_revision" };
  }
  if (consent.revokedAt !== null) {
    return { action: "cancel", reason: "consent_revoked" };
  }
  if (appointment.status === "cancelled") {
    return { action: "blocked", reason: "appointment_cancelled" };
  }

  return { action: "keep", reason: null };
}
