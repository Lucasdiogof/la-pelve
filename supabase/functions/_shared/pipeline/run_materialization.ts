// Materialização REAL (não dry-run): decisões do scheduler -> linhas de
// whatsapp_messages, de forma idempotente. Reaproveita sem alterar:
//   - leitura: SchedulerDataPort (whatsapp-scheduler-dry-run, só SELECT);
//   - regra: decideMessagesForAppointment (_shared/scheduler);
//   - montagem/escrita: buildMaterializableMessage + materializeAll
//     (_shared/materialization, INSERT idempotente pela UNIQUE
//     appointment_id+reminder_type+schedule_revision).
//
// Filtros desta etapa (o que entra na fila AGORA):
//   - só profissionais com conexão pronta (connected + phone_number_id):
//     sem conexão, a linha ficaria na fila sem nunca poder sair;
//   - só decisões devidas até agora + LOOKAHEAD (a solicitação de 12h nasce
//     perto da hora de sair, e não semanas antes);
//   - nunca decisões vencidas há mais de MAX_LATENESS (ex.: profissional que
//     conectou o WhatsApp hoje não dispara avisos de agendamentos antigos).

import { materializeAll } from "../materialization/materialize.ts";
import { buildMaterializableMessage } from "../materialization/builder.ts";
import type { MaterializableMessage, MaterializationPort, MaterializationSummary } from "../materialization/types.ts";
import { decideMessagesForAppointment } from "../scheduler/decision.ts";
import {
  computeConnectionDiagnostics,
  isValidIanaTimeZone,
  pickActiveConsent,
  toAppointmentForScheduling,
  toConsentForEligibility,
  toPatientForEligibility,
} from "../../whatsapp-scheduler-dry-run/transform.ts";
import type { ConsentRow, SchedulerDataPort } from "../../whatsapp-scheduler-dry-run/types.ts";

export const MATERIALIZATION_LOOKAHEAD_MS = 60 * 60 * 1000;
export const MATERIALIZATION_MAX_LATENESS_MS = 24 * 60 * 60 * 1000;
/** Agendamentos considerados: de ontem (fusos) até 1 ano à frente. */
const WINDOW_PAST_DAYS = 1;
const WINDOW_FUTURE_DAYS = 366;

export interface MaterializationRunSummary extends MaterializationSummary {
  appointments: number;
  skippedNoConnection: number;
  /** Agendamento com dado inconsistente (perfil/fuso/consentimento/contexto): não materializa. */
  appointmentErrors: number;
}

function isoDate(date: Date, offsetDays: number): string {
  return new Date(date.getTime() + offsetDays * 86_400_000).toISOString().slice(0, 10);
}

export async function materializeDueMessages(
  data: SchedulerDataPort,
  port: MaterializationPort,
  now: Date,
): Promise<MaterializationRunSummary> {
  const appointments = await data.listCandidateAppointments({
    fromDate: isoDate(now, -WINDOW_PAST_DAYS),
    toDate: isoDate(now, WINDOW_FUTURE_DAYS),
    fisioterapeutaId: null,
  });

  const fisioIds = [...new Set(appointments.map((a) => a.fisioterapeuta_id))];
  const patientIds = [...new Set(appointments.map((a) => a.patient_id).filter((id): id is string => id !== null))];
  const [patients, consents, profiles, connections] = await Promise.all([
    patientIds.length ? data.listPatientsByIds(patientIds) : Promise.resolve([]),
    patientIds.length ? data.listActiveReminderConsentsByPatientIds(patientIds) : Promise.resolve([]),
    fisioIds.length ? data.listProfilesByIds(fisioIds) : Promise.resolve([]),
    fisioIds.length ? data.listConnectionsByFisioIds(fisioIds) : Promise.resolve([]),
  ]);

  const patientsById = new Map(patients.map((p) => [p.id, p]));
  const consentsByPatient = new Map<string, ConsentRow[]>();
  for (const c of consents) consentsByPatient.set(c.patient_id, [...(consentsByPatient.get(c.patient_id) ?? []), c]);
  const profilesById = new Map(profiles.map((p) => [p.id, p]));
  const connectionsByFisio = new Map(connections.map((c) => [c.fisioterapeuta_id, c]));

  let skippedNoConnection = 0;
  let appointmentErrors = 0;
  const toMaterialize: MaterializableMessage[] = [];

  for (const row of appointments) {
    if (!computeConnectionDiagnostics(connectionsByFisio.get(row.fisioterapeuta_id)).connectionReady) {
      skippedNoConnection++;
      continue;
    }
    try {
      const profile = profilesById.get(row.fisioterapeuta_id);
      if (!profile || !isValidIanaTimeZone(profile.timezone)) throw new Error("profile_or_timezone");
      const patientRow = row.patient_id ? patientsById.get(row.patient_id) : undefined;
      const consentRow = pickActiveConsent(row.patient_id ? consentsByPatient.get(row.patient_id) ?? [] : []);

      const decisions = decideMessagesForAppointment({
        appointment: toAppointmentForScheduling(row),
        patient: toPatientForEligibility(patientRow),
        consent: toConsentForEligibility(consentRow),
        timeZone: profile.timezone,
        now,
      });

      for (const decision of decisions) {
        if (!decision.eligible) continue;
        const dueAt = Date.parse(decision.scheduledFor!);
        if (dueAt > now.getTime() + MATERIALIZATION_LOOKAHEAD_MS) continue;
        if (dueAt < now.getTime() - MATERIALIZATION_MAX_LATENESS_MS) continue;
        toMaterialize.push(
          buildMaterializableMessage({
            decision,
            fisioterapeutaId: row.fisioterapeuta_id,
            patient: patientRow ? { id: patientRow.id, phoneE164: patientRow.phone_e164 } : null,
            consent: consentRow ? { id: consentRow.id, contactValue: consentRow.contact_value } : null,
          }),
        );
      }
    } catch {
      // Sem detalhes no log: a mensagem do erro pode carregar ids/fuso.
      console.error(JSON.stringify({ event: "whatsapp_materialization_appointment_error", appointmentId: row.id }));
      appointmentErrors++;
    }
  }

  const summary = await materializeAll(port, toMaterialize);
  return { ...summary, appointments: appointments.length, skippedNoConnection, appointmentErrors };
}
