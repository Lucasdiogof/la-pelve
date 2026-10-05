// Orquestração do dry-run: busca os dados em lote via SchedulerDataPort,
// monta o SchedulingInput de cada appointment e chama a lógica pura já
// existente (decideMessagesForAppointment). NÃO grava nada — nenhuma
// chamada de insert/update/delete em lugar nenhum deste arquivo.
//
// Erros de QUERY (a porta de dados falhou) se propagam (throw) -- uma
// falha de leitura nunca deve parecer "não há appointments". Um problema
// de DADOS de uma linha específica (ex.: timezone inválida) não derruba o
// relatório inteiro: essa linha entra no relatório como `error`, não como
// uma decisão "inelegível" normal, e não é contada como sucesso.

import {
  decideMessagesForAppointment,
  type SchedulerDecision,
} from "../_shared/scheduler/decision.ts";
import {
  computeConnectionDiagnostics,
  isValidIanaTimeZone,
  pickActiveConsent,
  toAppointmentForScheduling,
  toConsentForEligibility,
  toPatientForEligibility,
} from "./transform.ts";
import type {
  AppointmentRow,
  ConnectionRow,
  ConsentRow,
  DryRunWindow,
  PatientRow,
  ProfileRow,
  SchedulerDataPort,
} from "./types.ts";

export interface DryRunAppointmentOk {
  appointmentId: string;
  fisioterapeutaId: string;
  scheduleRevision: number;
  connectionStatus: string;
  connectionReady: boolean;
  decisions: SchedulerDecision[];
}

export interface DryRunAppointmentError {
  appointmentId: string;
  fisioterapeutaId: string;
  scheduleRevision: number;
  error: string;
}

export type DryRunAppointmentResult = DryRunAppointmentOk | DryRunAppointmentError;

export function isDryRunAppointmentError(
  result: DryRunAppointmentResult,
): result is DryRunAppointmentError {
  return "error" in result;
}

export interface DryRunReport {
  generatedAt: string;
  mode: "dry-run";
  persisted: false;
  totals: {
    appointments: number;
    eligibleMessages: number;
    ineligibleMessages: number;
    errors: number;
  };
  appointments: DryRunAppointmentResult[];
}

function unique<T>(values: T[]): T[] {
  return [...new Set(values)];
}

function indexById<T extends { id: string }>(rows: T[]): Map<string, T> {
  const map = new Map<string, T>();
  for (const row of rows) map.set(row.id, row);
  return map;
}

function groupBy<T, K>(rows: T[], keyOf: (row: T) => K): Map<K, T[]> {
  const map = new Map<K, T[]>();
  for (const row of rows) {
    const key = keyOf(row);
    const list = map.get(key);
    if (list) list.push(row);
    else map.set(key, [row]);
  }
  return map;
}

/**
 * Executa o dry-run para a janela dada. `now` é capturado UMA vez pelo
 * chamador (nunca lido internamente) e usado para todas as decisões desta
 * execução — nunca `new Date()` dentro deste arquivo.
 */
export async function runDryRun(
  port: SchedulerDataPort,
  window: DryRunWindow,
  now: Date,
): Promise<DryRunReport> {
  const appointments: AppointmentRow[] = await port.listCandidateAppointments(window);

  const patientIds = unique(
    appointments.map((a) => a.patient_id).filter((id): id is string => id !== null),
  );
  const fisioterapeutaIds = unique(appointments.map((a) => a.fisioterapeuta_id));

  // Exatamente 1 chamada em lote por tipo de dado, não importa quantos
  // appointments existam na janela -- evita N+1.
  const [patients, consents, profiles, connections]: [
    PatientRow[],
    ConsentRow[],
    ProfileRow[],
    ConnectionRow[],
  ] = await Promise.all([
    patientIds.length > 0 ? port.listPatientsByIds(patientIds) : Promise.resolve([]),
    patientIds.length > 0
      ? port.listActiveReminderConsentsByPatientIds(patientIds)
      : Promise.resolve([]),
    fisioterapeutaIds.length > 0 ? port.listProfilesByIds(fisioterapeutaIds) : Promise.resolve([]),
    fisioterapeutaIds.length > 0
      ? port.listConnectionsByFisioIds(fisioterapeutaIds)
      : Promise.resolve([]),
  ]);

  const patientsById = indexById(patients);
  const consentsByPatientId = groupBy(consents, (c) => c.patient_id);
  const profilesById = indexById(profiles);
  const connectionByFisioId = new Map(connections.map((c) => [c.fisioterapeuta_id, c]));

  const results: DryRunAppointmentResult[] = [];
  let eligibleMessages = 0;
  let ineligibleMessages = 0;
  let errors = 0;

  for (const row of appointments) {
    try {
      const profile = profilesById.get(row.fisioterapeuta_id);
      if (!profile) {
        throw new Error(
          `profile ausente para fisioterapeuta_id=${row.fisioterapeuta_id} (dado inconsistente: toda appointment deveria ter um profile correspondente)`,
        );
      }
      if (!isValidIanaTimeZone(profile.timezone)) {
        throw new Error(
          `profiles.timezone inválida ("${profile.timezone}") para fisioterapeuta_id=${row.fisioterapeuta_id} -- erro de dados, não adivinhado`,
        );
      }

      const patientRow = row.patient_id ? patientsById.get(row.patient_id) : undefined;
      const consentRows = row.patient_id ? consentsByPatientId.get(row.patient_id) ?? [] : [];

      // pickActiveConsent lança se consentRows tiver >1 linha (violação do
      // índice único patient_consents_one_active_key -- estado impossível
      // pelo schema atual); o catch deste bloco converte isso no `error`
      // desta linha do relatório, igual a qualquer outro dado inconsistente.
      const decisions = decideMessagesForAppointment({
        appointment: toAppointmentForScheduling(row),
        patient: toPatientForEligibility(patientRow),
        consent: toConsentForEligibility(pickActiveConsent(consentRows)),
        timeZone: profile.timezone,
        now,
      });

      const { connectionStatus, connectionReady } = computeConnectionDiagnostics(
        connectionByFisioId.get(row.fisioterapeuta_id),
      );

      for (const d of decisions) {
        if (d.eligible) eligibleMessages++;
        else ineligibleMessages++;
      }

      results.push({
        appointmentId: row.id,
        fisioterapeutaId: row.fisioterapeuta_id,
        scheduleRevision: row.schedule_revision,
        connectionStatus,
        connectionReady,
        decisions,
      });
    } catch (err) {
      errors++;
      results.push({
        appointmentId: row.id,
        fisioterapeutaId: row.fisioterapeuta_id,
        scheduleRevision: row.schedule_revision,
        error: err instanceof Error ? err.message : String(err),
      });
    }
  }

  return {
    generatedAt: now.toISOString(),
    mode: "dry-run",
    persisted: false,
    totals: {
      appointments: appointments.length,
      eligibleMessages,
      ineligibleMessages,
      errors,
    },
    appointments: results,
  };
}
