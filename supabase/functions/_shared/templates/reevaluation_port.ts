// Porta real da reavaliação: RPCs só service_role
//   list_whatsapp_template_reevaluation_candidates (0034),
//   get_whatsapp_connection_access_token (0026),
//   upsert_whatsapp_connection_from_signup (0034: merge do histórico, WA010).
// NUNCA lança; o token não sai daqui nem vai para log.

import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type { ReevaluationCandidate, ReevaluationPort } from "./reevaluate.ts";

export function createSupabaseReevaluationPort(client: SupabaseClient): ReevaluationPort {
  return {
    async candidates(wabaId) {
      try {
        const { data, error } = await client.rpc("list_whatsapp_template_reevaluation_candidates", {
          p_waba_id: wabaId,
        });
        if (error || !Array.isArray(data)) return null;
        return data.map((row: Record<string, unknown>): ReevaluationCandidate => ({
          fisioterapeutaId: String(row.fisioterapeuta_id),
          phoneNumberId: String(row.phone_number_id),
          displayPhoneNumber: typeof row.display_phone_number === "string" ? row.display_phone_number : null,
          setupState:
            typeof row.setup_state === "object" && row.setup_state !== null
              ? (row.setup_state as Record<string, unknown>)
              : {},
        }));
      } catch {
        return null;
      }
    },
    async accessToken(fisioterapeutaId) {
      try {
        const { data, error } = await client.rpc("get_whatsapp_connection_access_token", {
          p_fisioterapeuta_id: fisioterapeutaId,
        });
        return error || typeof data !== "string" ? null : data;
      } catch {
        return null;
      }
    },
    async promote(candidate, input) {
      try {
        const { error } = await client.rpc("upsert_whatsapp_connection_from_signup", {
          p_fisioterapeuta_id: candidate.fisioterapeutaId,
          p_waba_id: input.wabaId,
          p_phone_number_id: candidate.phoneNumberId,
          p_display_phone_number: input.displayPhoneNumber ?? candidate.displayPhoneNumber,
          p_status: "connected",
          p_last_error: null,
          p_setup_state: { ...candidate.setupState, evaluated_at: input.evaluatedAt },
        });
        if (!error) return "connected";
        return error.code === "WA010" ? "stale" : "error";
      } catch {
        return "error";
      }
    },
  };
}
