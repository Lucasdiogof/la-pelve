// Implementação REAL de ConfirmationReplyPort: uma única chamada à RPC
// public.process_whatsapp_confirmation_reply (migration 0025), que faz a
// correlação, a mudança de status e a deduplicação numa transação. Usa o
// client service_role criado no index.ts do webhook (nunca no app).
//
// O tipo do client é só `import type` (apagado pelo strip de tipos do
// Node), então os testes usam um client falso sem carregar supabase-js.
//
// NÃO EXECUTADO contra produção nesta etapa. NÃO deployado.

// deno-lint-ignore no-explicit-any
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type {
  ConfirmationReplyOutcome,
  ConfirmationReplyPort,
  ConfirmationReplyResult,
} from "./types.ts";

export const CONFIRMATION_REPLY_RPC = "process_whatsapp_confirmation_reply";

const KNOWN_RESULTS: ReadonlySet<string> = new Set<ConfirmationReplyResult>([
  "confirmed",
  "already_confirmed",
  "duplicate",
  "no_pending_request",
  "ambiguous",
  "request_expired",
  "request_stale",
  "consent_revoked",
  "appointment_status_incompatible",
]);

const PERSISTENCE_ERROR: ConfirmationReplyOutcome = { kind: "error", code: "persistence_error" };

/** Log interno sanitizado: só o wamid recebido e o contexto, nunca erro bruto/telefone. */
function logFailure(wamid: string, context: string) {
  console.error(JSON.stringify({ event: "whatsapp_confirmation_reply_failed", context, wamid }));
}

export function createSupabaseConfirmationReplyPort(client: SupabaseClient): ConfirmationReplyPort {
  return {
    async processConfirmationReply(input) {
      try {
        const { data, error } = await client.rpc(CONFIRMATION_REPLY_RPC, {
          p_wamid: input.wamid,
          p_phone_number_id: input.phoneNumberId,
          p_from_e164_candidates: input.fromE164Candidates,
          p_received_at: input.receivedAt,
          p_message_type: input.messageType,
          p_context_wamid: input.contextWamid,
        });
        if (error) {
          logFailure(input.wamid, "rpc_failed");
          return PERSISTENCE_ERROR;
        }
        const outcome = (data as { outcome?: unknown } | null)?.outcome;
        if (typeof outcome !== "string" || !KNOWN_RESULTS.has(outcome)) {
          logFailure(input.wamid, "unexpected_rpc_response");
          return PERSISTENCE_ERROR;
        }
        return { kind: "processed", result: outcome as ConfirmationReplyResult };
      } catch {
        logFailure(input.wamid, "unexpected_exception");
        return PERSISTENCE_ERROR;
      }
    },
  };
}
