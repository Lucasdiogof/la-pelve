// Mapeamento PURO de MaterializableMessage -> colunas reais de
// whatsapp_messages. Separado do adapter real (que fala com o Supabase)
// para que a forma exata da linha escrita seja testável sem I/O.
//
// Escreve SOMENTE o necessário: deixa id/status/created_at/updated_at
// para o banco gerar (status já nasce 'scheduled' pelo DEFAULT da
// migration 0020 -- mandar status explicitamente aqui seria redundante).
// Nunca inclui wamid/template_name/sent_at/delivered_at/read_at/
// failed_at/error -- são da futura etapa de dispatch.

import type { MaterializableMessage } from "./types.ts";

export interface WhatsappMessageInsertRow {
  fisioterapeuta_id: string;
  patient_id: string;
  appointment_id: string;
  reminder_type: string;
  schedule_revision: number;
  scheduled_for: string;
  destination_phone_e164: string;
  consent_id: string;
}

export function toWhatsappMessageInsertRow(message: MaterializableMessage): WhatsappMessageInsertRow {
  return {
    fisioterapeuta_id: message.fisioterapeutaId,
    patient_id: message.patientId,
    appointment_id: message.appointmentId,
    reminder_type: message.reminderType,
    schedule_revision: message.scheduleRevision,
    scheduled_for: message.scheduledFor,
    destination_phone_e164: message.destinationPhoneE164,
    consent_id: message.consentId,
  };
}

/** Colunas que fazem parte da identidade/alvo de conflito do INSERT idempotente. */
export const UPSERT_CONFLICT_TARGET = "appointment_id,reminder_type,schedule_revision";
