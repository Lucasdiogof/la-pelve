// Porta de status de template: RPC public.apply_whatsapp_template_status
// (migration 0033), só service_role. Registra o evento nas conexões da WABA
// e tira de 'connected' quando o template deixa de ser utilizável; NUNCA
// promove. NUNCA lança; log só com o evento.

import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type { TemplateStatusEvent } from "./parse_template_status.ts";

export interface TemplateStatusPort {
  /** Conexões alteradas, ou null em falha de persistência (a Meta reenvia). */
  applyTemplateStatus(event: TemplateStatusEvent): Promise<number | null>;
}

export function createSupabaseTemplateStatusPort(client: SupabaseClient): TemplateStatusPort {
  return {
    async applyTemplateStatus(event) {
      try {
        const { data, error } = await client.rpc("apply_whatsapp_template_status", {
          p_waba_id: event.wabaId,
          p_template_name: event.name,
          p_language: event.language,
          p_event: event.event,
          p_occurred_at: event.occurredAt,
        });
        if (error || typeof data !== "number") {
          console.error(JSON.stringify({ event: "whatsapp_template_status_failed", type: event.event }));
          return null;
        }
        return data;
      } catch {
        console.error(JSON.stringify({ event: "whatsapp_template_status_failed", type: event.event }));
        return null;
      }
    },
  };
}
