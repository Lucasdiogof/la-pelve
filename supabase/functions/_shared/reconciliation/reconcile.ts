// Orquestra a reconciliação de várias mensagens: decide (lógica pura) e,
// só quando a ação é 'cancel', chama a ReconciliationPort.
//
//   cancel  -> cancelIfScheduled(): UPDATE condicional, permanente
//   blocked -> nenhum I/O (condição temporária; a linha segue scheduled)
//   keep    -> nenhum I/O
//
// Individual, sequencial e isolada -- mesma estratégia de materializeAll:
// uma mensagem por vez (sem Promise.all), e nenhuma falha de uma interrompe
// as demais. Nunca lança.

import { decideReconciliation, ReconciliationIntegrityError } from "./decide.ts";
import type {
  CancelOutcome,
  ReconciliationDecision,
  ReconciliationInput,
  ReconciliationPort,
  ReconciliationSummary,
} from "./types.ts";

/** Log interno sanitizado: só ids técnicos e o código -- nunca telefone/nome/erro bruto. */
function logIntegrityFailure(input: ReconciliationInput, code: string) {
  console.error(
    JSON.stringify({
      event: "whatsapp_message_reconciliation_input_invalid",
      code,
      messageId: input.message.id,
      appointmentId: input.message.appointmentId,
    }),
  );
}

export async function reconcileAll(
  port: ReconciliationPort,
  inputs: ReconciliationInput[],
): Promise<ReconciliationSummary> {
  const summary: ReconciliationSummary = {
    candidates: inputs.length,
    unchanged: 0,
    blocked: 0,
    cancelled: 0,
    alreadyNotScheduled: 0,
    notFound: 0,
    errors: 0,
    cancelledByReason: {
      stale_schedule_revision: 0,
      consent_revoked: 0,
    },
    blockedByReason: {
      appointment_cancelled: 0,
    },
  };

  for (const input of inputs) {
    let decision: ReconciliationDecision;
    try {
      decision = decideReconciliation(input);
    } catch (e) {
      logIntegrityFailure(input, e instanceof ReconciliationIntegrityError ? e.code : "unexpected_exception");
      summary.errors++;
      continue;
    }

    if (decision.action === "keep") {
      summary.unchanged++;
      continue;
    }

    if (decision.action === "blocked") {
      summary.blocked++;
      summary.blockedByReason[decision.reason]++;
      continue;
    }

    let outcome: CancelOutcome;
    try {
      outcome = await port.cancelIfScheduled(input.message.id);
    } catch {
      // O contrato da porta é nunca lançar; defesa para que um adapter
      // futuro com bug nunca derrube o lote.
      summary.errors++;
      continue;
    }

    switch (outcome.kind) {
      case "cancelled":
        summary.cancelled++;
        summary.cancelledByReason[decision.reason]++;
        break;
      case "already_not_scheduled":
        summary.alreadyNotScheduled++;
        break;
      case "not_found":
        summary.notFound++;
        break;
      case "error":
        summary.errors++;
        break;
    }
  }

  return summary;
}
