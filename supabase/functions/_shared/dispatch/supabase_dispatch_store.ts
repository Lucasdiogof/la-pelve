// Implementação REAL de DispatchStore: as RPCs da migration 0026 via
// supabase-js (service_role, só no backend). Tipo do client é `import type`
// (apagado no Node); testado de verdade contra PostgREST + Postgres local no
// E2E (supabase/tests/e2e/).
//
// NÃO deployado.

// deno-lint-ignore no-explicit-any
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type { MessageType } from "../scheduler/decision.ts";
import type { ClaimedMessage, CompletionInput, DispatchStore, PrepareResult } from "./types.ts";

const MESSAGE_TYPES: ReadonlySet<string> = new Set([
  "appointment_confirmation",
  "appointment_12h",
  "appointment_rescheduled",
]);

/** Falha de RPC sem o texto bruto do PostgREST (pode conter dados da linha). */
class DispatchStoreError extends Error {
  constructor(context: string) {
    super(`dispatch store: ${context}`);
    this.name = "DispatchStoreError";
  }
}

function str(value: unknown): string | null {
  return typeof value === "string" ? value : null;
}

export function parsePrepareResponse(data: unknown): PrepareResult {
  const row = (data ?? {}) as Record<string, unknown>;
  switch (row.result) {
    case "lease_lost":
      return { kind: "lease_lost" };
    case "cancelled":
    case "deferred":
      return { kind: row.result, code: str(row.code) ?? "unknown" };
    case "ready": {
      const reminderType = str(row.reminder_type);
      const fields = {
        destinationPhoneE164: str(row.destination_phone_e164),
        appointmentDate: str(row.appointment_date),
        appointmentTime: str(row.appointment_time),
        timeZone: str(row.time_zone),
        phoneNumberId: str(row.phone_number_id),
        accessToken: str(row.access_token),
      };
      if (
        !reminderType || !MESSAGE_TYPES.has(reminderType) ||
        typeof row.attempt_count !== "number" ||
        Object.values(fields).some((v) => v === null)
      ) {
        throw new DispatchStoreError("unexpected_prepare_response");
      }
      return {
        kind: "ready",
        send: {
          reminderType: reminderType as MessageType,
          attemptCount: row.attempt_count,
          patientFirstName: str(row.patient_first_name) ?? "",
          destinationPhoneE164: fields.destinationPhoneE164!,
          appointmentDate: fields.appointmentDate!,
          appointmentTime: fields.appointmentTime!,
          timeZone: fields.timeZone!,
          phoneNumberId: fields.phoneNumberId!,
          accessToken: fields.accessToken!,
        },
      };
    }
    default:
      throw new DispatchStoreError("unexpected_prepare_response");
  }
}

export function createSupabaseDispatchStore(client: SupabaseClient): DispatchStore {
  return {
    async claim({ limit, leaseSeconds, reminderTypes }) {
      const { data, error } = await client.rpc("claim_whatsapp_messages_for_dispatch", {
        p_limit: limit,
        p_lease_seconds: leaseSeconds,
        p_reminder_types: reminderTypes,
      });
      if (error || !Array.isArray(data)) throw new DispatchStoreError("claim_failed");
      return data.map((row: Record<string, unknown>): ClaimedMessage => {
        const messageId = str(row.message_id);
        const leaseToken = str(row.lease_token);
        const reminderType = str(row.reminder_type);
        if (!messageId || !leaseToken || !reminderType || !MESSAGE_TYPES.has(reminderType)) {
          throw new DispatchStoreError("unexpected_claim_response");
        }
        return { messageId, leaseToken, reminderType: reminderType as MessageType };
      });
    },

    async prepare(messageId, leaseToken) {
      const { data, error } = await client.rpc("prepare_whatsapp_message_send", {
        p_message_id: messageId,
        p_lease_token: leaseToken,
      });
      if (error) throw new DispatchStoreError("prepare_failed");
      return parsePrepareResponse(data);
    },

    async complete(messageId, leaseToken, completion: CompletionInput) {
      const { data, error } = await client.rpc("complete_whatsapp_message_send", {
        p_message_id: messageId,
        p_lease_token: leaseToken,
        p_result: completion.result,
        p_wamid: completion.result === "sent" ? completion.wamid : null,
        p_template_name: completion.result === "retry" ? null : completion.templateName,
        p_error: completion.result === "sent" ? null : completion.error,
        p_retry_delay_seconds: completion.result === "retry" ? completion.retryDelaySeconds : null,
      });
      if (error || (data !== "ok" && data !== "lease_lost")) throw new DispatchStoreError("complete_failed");
      return data;
    },
  };
}
