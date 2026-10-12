// Porta de status de entrega: RPC public.apply_whatsapp_message_status
// (migration 0033), só service_role. Toda a regra (identidade do número,
// monotonicidade, failed sem reenvio, idempotência) está na transação do
// banco. NUNCA lança; log só com o tipo de status, nunca wamid/telefone.

import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type { DeliveryStatus } from "./parse_statuses.ts";

export type StatusApplyResult = "updated" | "unchanged" | "not_found" | "invalid";

export interface DeliveryStatusPort {
  /** null = falha de persistência (a Meta reenvia o webhook). */
  applyStatus(status: DeliveryStatus): Promise<StatusApplyResult | null>;
}

const RESULTS = new Set<string>(["updated", "unchanged", "not_found", "invalid"]);

export function createSupabaseDeliveryStatusPort(client: SupabaseClient): DeliveryStatusPort {
  return {
    async applyStatus(status) {
      try {
        const { data, error } = await client.rpc("apply_whatsapp_message_status", {
          p_phone_number_id: status.phoneNumberId,
          p_wamid: status.wamid,
          p_status: status.status,
          p_occurred_at: status.occurredAt,
          p_error_code: status.errorCode,
        });
        if (error || typeof data !== "string" || !RESULTS.has(data)) {
          console.error(JSON.stringify({ event: "whatsapp_status_apply_failed", status: status.status }));
          return null;
        }
        return data as StatusApplyResult;
      } catch {
        console.error(JSON.stringify({ event: "whatsapp_status_apply_failed", status: status.status }));
        return null;
      }
    },
  };
}
