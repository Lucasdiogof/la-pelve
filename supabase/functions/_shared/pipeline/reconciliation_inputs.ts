// Leitura dos dados da RECONCILIAÇÃO (o que faltava para rodar
// reconcileAll de verdade): mensagens ainda 'scheduled' + a consulta e o
// consentimento de cada uma. A decisão continua em
// _shared/reconciliation/decide.ts, sem alteração.

// deno-lint-ignore no-explicit-any
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type { MessageStatus, ReconciliationInput } from "../reconciliation/types.ts";

export interface ScheduledMessageRow {
  id: string;
  status: MessageStatus;
  schedule_revision: number;
  appointment_id: string;
  consent_id: string;
}

export interface ReconciliationDataPort {
  listScheduledMessages(): Promise<ScheduledMessageRow[]>;
  listAppointmentsByIds(ids: string[]): Promise<Array<{ id: string; status: string; schedule_revision: number }>>;
  listConsentsByIds(ids: string[]): Promise<Array<{ id: string; revoked_at: string | null }>>;
}

/** Puro: junta as 3 leituras. Linha ausente vira null (decide.ts trata como erro de integridade). */
export async function loadReconciliationInputs(port: ReconciliationDataPort): Promise<ReconciliationInput[]> {
  const messages = await port.listScheduledMessages();
  if (messages.length === 0) return [];
  const [appointments, consents] = await Promise.all([
    port.listAppointmentsByIds([...new Set(messages.map((m) => m.appointment_id))]),
    port.listConsentsByIds([...new Set(messages.map((m) => m.consent_id))]),
  ]);
  const appointmentsById = new Map(appointments.map((a) => [a.id, a]));
  const consentsById = new Map(consents.map((c) => [c.id, c]));

  return messages.map((m) => {
    const a = appointmentsById.get(m.appointment_id);
    const c = consentsById.get(m.consent_id);
    return {
      message: {
        id: m.id,
        status: m.status,
        scheduleRevision: m.schedule_revision,
        appointmentId: m.appointment_id,
        consentId: m.consent_id,
      },
      appointment: a ? { id: a.id, status: a.status, scheduleRevision: a.schedule_revision } : null,
      consent: c ? { id: c.id, revokedAt: c.revoked_at } : null,
    };
  });
}

const PAGE = 500;

export function createSupabaseReconciliationDataPort(client: SupabaseClient): ReconciliationDataPort {
  return {
    async listScheduledMessages() {
      const { data, error } = await client
        .from("whatsapp_messages")
        .select("id, status, schedule_revision, appointment_id, consent_id")
        .eq("status", "scheduled")
        .order("scheduled_for")
        .limit(PAGE);
      if (error) throw new Error("listScheduledMessages failed");
      return (data ?? []) as ScheduledMessageRow[];
    },
    async listAppointmentsByIds(ids) {
      const { data, error } = await client.from("appointments").select("id, status, schedule_revision").in("id", ids);
      if (error) throw new Error("listAppointmentsByIds failed");
      return data ?? [];
    },
    async listConsentsByIds(ids) {
      const { data, error } = await client.from("patient_consents").select("id, revoked_at").in("id", ids);
      if (error) throw new Error("listConsentsByIds failed");
      return data ?? [];
    },
  };
}
