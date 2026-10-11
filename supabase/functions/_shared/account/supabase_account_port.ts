// Porta real: RPC public.apply_whatsapp_account_event (migration 0030),
// só service_role. Sem log de dado pessoal.

// deno-lint-ignore no-explicit-any
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type { AccountEventPort } from "./types.ts";

export function createSupabaseAccountEventPort(client: SupabaseClient): AccountEventPort {
  return {
    async applyAccountEvent(event) {
      const { data, error } = await client.rpc("apply_whatsapp_account_event", {
        p_waba_id: event.wabaId,
        p_event: event.event,
        p_detail: event.detail,
      });
      if (error || typeof data !== "number") {
        console.error(JSON.stringify({ event: "whatsapp_account_event_failed", type: event.event }));
        return null;
      }
      return data;
    },
  };
}
