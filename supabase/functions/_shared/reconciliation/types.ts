// Tipos da camada de RECONCILIAÇÃO de whatsapp_messages: responde "esta
// mensagem scheduled ainda continua válida?" e, se não, pede o cancelamento
// PERMANENTE -- mas só quando a invalidez também é permanente.
// Nenhum I/O aqui -- só forma. Separada de _shared/scheduler/ (regras de
// elegibilidade) e de _shared/materialization/ (criação das linhas).
//
// Esta camada NÃO decide destino: não consulta patients.phone_e164 nem
// compara o snapshot destination_phone_e164 com o telefone atual. A pergunta
// é só "o consentimento ESPECÍFICO que autorizou esta mensagem continua
// ativo?" -- se o paciente trocou de telefone pelo fluxo normal do app, o
// consentimento antigo já foi revogado e cai em consent_revoked.

/** Os 7 status de whatsapp_messages (whatsapp_messages_status_valid). */
export type MessageStatus =
  | "scheduled"
  | "processing"
  | "sent"
  | "delivered"
  | "read"
  | "failed"
  | "cancelled";

/**
 * Entrada mínima de UMA reconciliação. Propositalmente SEM telefone, nome de
 * paciente, contact_value ou qualquer dado clínico: a decisão não precisa
 * deles, então não há como vazarem desta camada.
 *
 * `appointment` e `consent` são `| null` porque quem monta o input (camada
 * de leitura, futura) pode não achar a linha. Por integridade (FKs) isso não
 * deveria acontecer; se acontecer, decideReconciliation lança
 * ReconciliationIntegrityError em vez de inventar um motivo.
 */
export interface ReconciliationInput {
  message: {
    id: string;
    status: MessageStatus;
    scheduleRevision: number;
    appointmentId: string;
    consentId: string;
  };
  appointment: {
    id: string;
    /**
     * Valor cru de appointments.status. Os 6 valores reais do app:
     * scheduled, confirmed, fulfilled, cancelled, noShow, rescheduled.
     * Só 'cancelled' tem efeito aqui (e só como bloqueio temporário).
     */
    status: string;
    scheduleRevision: number;
  } | null;
  consent: {
    id: string;
    /** null = ativo; qualquer valor = revogado. */
    revokedAt: string | null;
  } | null;
}

/**
 * Motivos de cancelamento PERMANENTE (whatsapp_messages.status='cancelled',
 * irreversível: a UNIQUE da tripla impede recriar a linha). Só entram aqui
 * condições MONOTÔNICAS -- que, uma vez verdadeiras, nunca voltam a ser
 * falsas no modelo atual:
 *  - stale_schedule_revision: appointments.schedule_revision só avança
 *    (o trigger incrementa em mudança de date/time; o cliente não define).
 *  - consent_revoked: o trigger patient_consents_only_revoke impede que
 *    revoked_at volte a NULL (nem service role consegue).
 */
export type CancelReason = "stale_schedule_revision" | "consent_revoked";

/**
 * Motivos de BLOQUEIO TEMPORÁRIO: a mensagem não deve seguir agora, mas a
 * condição é REVERSÍVEL, então a linha NÃO é alterada.
 *  - appointment_cancelled: appointments.status='cancelled' pode voltar para
 *    scheduled/confirmed/... (o seletor de status do app permite qualquer
 *    transição). Cancelar a whatsapp_message por isso seria irreversível e
 *    perderia o lembrete se a consulta fosse reativada.
 */
export type BlockReason = "appointment_cancelled";

/**
 * Resultado puro da decisão -- três ações explícitas:
 *  - cancel:  alteração PERMANENTE (UPDATE status='cancelled' via porta).
 *  - blocked: condição temporária; NENHUM I/O, a linha continua scheduled.
 *             O dispatch futuro precisa revalidar a condição antes de enviar.
 *  - keep:    nenhuma ação. reason=null (scheduled e válida) ou
 *             'not_cancellable_status' (status != scheduled: fora do escopo
 *             da reconciliação automática; só para observabilidade).
 */
export type ReconciliationDecision =
  | { action: "cancel"; reason: CancelReason }
  | { action: "blocked"; reason: BlockReason }
  | { action: "keep"; reason: "not_cancellable_status" | null };

/**
 * Resultado de pedir o cancelamento de 1 mensagem.
 * `error.code` é um código INTERNO genérico, nunca o texto bruto do
 * PostgREST/Postgres (mesma regra de MaterializationOutcome).
 */
export type CancelOutcome =
  | { kind: "cancelled" }
  | { kind: "already_not_scheduled" }
  | { kind: "not_found" }
  | { kind: "error"; code: "persistence_error" };

/**
 * Porta de persistência, EXCLUSIVA do cancelamento permanente.
 * cancelIfScheduled NUNCA lança, e o UPDATE por trás dela é CONDICIONAL
 * (WHERE id = ? AND status = 'scheduled'): nunca cancela uma mensagem que já
 * saiu de scheduled entre a leitura e a escrita. Altera SOMENTE status.
 * Só é chamada para decision.action === 'cancel'; não existe operação de
 * block/unblock no banco.
 */
export interface ReconciliationPort {
  cancelIfScheduled(messageId: string): Promise<CancelOutcome>;
}

/**
 * Agregado público -- só contagens e motivos; nunca ids de linha, telefone ou nomes.
 * Invariante: candidates = unchanged + blocked + cancelled + alreadyNotScheduled
 *                          + notFound + errors.
 */
export interface ReconciliationSummary {
  candidates: number;
  /** action='keep': ainda válida, ou status fora do escopo. Nenhum I/O. */
  unchanged: number;
  /** action='blocked': condição temporária. Nenhum I/O, linha intacta; NÃO conta como cancelled. */
  blocked: number;
  /** action='cancel' e a porta confirmou o UPDATE. */
  cancelled: number;
  /** action='cancel', mas a mensagem já não estava scheduled (ex.: virou processing). */
  alreadyNotScheduled: number;
  notFound: number;
  /** Falha de persistência, exceção ou input com integridade quebrada. */
  errors: number;
  /** Subconjunto de `cancelled`, por motivo (só os permanentes). */
  cancelledByReason: Record<CancelReason, number>;
  /** Subconjunto de `blocked`, por motivo (hoje só appointment_cancelled). */
  blockedByReason: Record<BlockReason, number>;
}
