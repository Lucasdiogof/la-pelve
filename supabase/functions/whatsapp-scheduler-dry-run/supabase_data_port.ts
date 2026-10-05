// Implementação REAL de SchedulerDataPort usando o SupabaseClient
// (service_role, só no backend -- ver index.ts). Único arquivo desta pasta
// que fala com o Postgres; por isso não tem teste unitário (é um adapter
// fino, I/O puro) -- a lógica de decisão testável fica em transform.ts e
// orchestrate.ts. Deno-only (import de supabase-js por especificador
// jsr:), por isso nunca é importado pelos testes (que rodam em Node).

// deno-lint-ignore no-explicit-any
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type {
  AppointmentRow,
  ConnectionRow,
  ConsentRow,
  DryRunWindow,
  PatientRow,
  ProfileRow,
  SchedulerDataPort,
} from "./types.ts";

const APPOINTMENT_COLUMNS =
  "id, fisioterapeuta_id, date, time, status, patient_id, schedule_revision, schedule_revision_at";
const PATIENT_COLUMNS = "id, fisioterapeuta_id, phone_e164, deleted_at";
const CONSENT_COLUMNS = "id, patient_id, fisioterapeuta_id, channel, purpose, contact_value, granted_at, revoked_at";
const PROFILE_COLUMNS = "id, timezone";
const CONNECTION_COLUMNS = "fisioterapeuta_id, status, phone_number_id";

export function createSupabaseSchedulerDataPort(client: SupabaseClient): SchedulerDataPort {
  return {
    async listCandidateAppointments(window: DryRunWindow): Promise<AppointmentRow[]> {
      // SEM filtro de status aqui, de propósito: isto é um diagnóstico
      // ("quais mensagens seriam elegíveis e quais seriam bloqueadas, e por
      // quê?"), então um appointment cancelled também é um candidato --
      // precisa chegar à lógica pura para produzir reason=appointment_cancelled
      // no relatório, não desaparecer silenciosamente na query.
      let query = client
        .from("appointments")
        .select(APPOINTMENT_COLUMNS)
        .gte("date", window.fromDate)
        .lte("date", window.toDate);
      if (window.fisioterapeutaId !== null) {
        query = query.eq("fisioterapeuta_id", window.fisioterapeutaId);
      }
      const { data, error } = await query;
      if (error) throw new Error(`listCandidateAppointments: ${error.message}`);
      return (data ?? []) as AppointmentRow[];
    },

    async listPatientsByIds(patientIds: string[]): Promise<PatientRow[]> {
      const { data, error } = await client
        .from("patients")
        .select(PATIENT_COLUMNS)
        .in("id", patientIds)
        .is("deleted_at", null); // soft-deleted nunca entra no lote (ver transform.ts)
      if (error) throw new Error(`listPatientsByIds: ${error.message}`);
      return (data ?? []) as PatientRow[];
    },

    async listActiveReminderConsentsByPatientIds(patientIds: string[]): Promise<ConsentRow[]> {
      const { data, error } = await client
        .from("patient_consents")
        .select(CONSENT_COLUMNS)
        .in("patient_id", patientIds)
        .eq("channel", "whatsapp")
        .eq("purpose", "appointment_reminder")
        .is("revoked_at", null);
      if (error) throw new Error(`listActiveReminderConsentsByPatientIds: ${error.message}`);
      return (data ?? []) as ConsentRow[];
    },

    async listProfilesByIds(fisioterapeutaIds: string[]): Promise<ProfileRow[]> {
      const { data, error } = await client
        .from("profiles")
        .select(PROFILE_COLUMNS)
        .in("id", fisioterapeutaIds);
      if (error) throw new Error(`listProfilesByIds: ${error.message}`);
      return (data ?? []) as ProfileRow[];
    },

    async listConnectionsByFisioIds(fisioterapeutaIds: string[]): Promise<ConnectionRow[]> {
      const { data, error } = await client
        .from("whatsapp_connections")
        .select(CONNECTION_COLUMNS)
        .in("fisioterapeuta_id", fisioterapeutaIds);
      if (error) throw new Error(`listConnectionsByFisioIds: ${error.message}`);
      return (data ?? []) as ConnectionRow[];
    },
  };
}

/**
 * Cria o client com service_role (lido SÓ de Deno.env, nunca hardcoded,
 * nunca devolvido/logado). Necessário porque toda tabela aqui tem RLS por
 * fisioterapeuta_id = auth.uid() — um JWT de profissional nunca veria os
 * dados de outro, mas este diagnóstico administrativo precisa olhar vários
 * profissionais de uma vez. Ver index.ts para a autenticação própria desta
 * function (não é um JWT de usuário final).
 */
export function createServiceRoleClient(): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceRoleKey) {
    throw new Error("SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY ausentes do ambiente da function");
  }
  return createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
}
