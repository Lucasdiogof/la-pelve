// Transformações PURAS: linhas "crus" do banco -> os tipos que a lógica
// pura do scheduler (../\_shared/scheduler) espera. Nenhum I/O aqui —
// facilita testar cada regra de mapeamento isoladamente, sem mockar banco.

import type { AppointmentForScheduling } from "../_shared/scheduler/decision.ts";
import type {
  ConsentForEligibility,
  PatientForEligibility,
} from "../_shared/scheduler/eligibility.ts";
import type { AppointmentRow, ConnectionRow, ConsentRow, PatientRow } from "./types.ts";

export function toAppointmentForScheduling(row: AppointmentRow): AppointmentForScheduling {
  return {
    id: row.id,
    fisioterapeutaId: row.fisioterapeuta_id,
    date: row.date,
    time: row.time,
    status: row.status,
    patientId: row.patient_id,
    scheduleRevision: row.schedule_revision,
    scheduleRevisionAt: row.schedule_revision_at,
  };
}

/**
 * Paciente soft-deleted (patients.deleted_at != null) é tratado como
 * AUSENTE (devolve null) — a camada de carregamento já filtra
 * deleted_at IS NULL na query (listPatientsByIds), então um patient_id que
 * só exista como soft-deleted simplesmente não aparece no lote carregado e
 * cai aqui como "não encontrado". Isto reaproveita o reason já existente
 * na lógica pura (missing_patient) em vez de inventar um reason novo
 * (`patient_deleted`) sem autorização para alterar `_shared/scheduler`
 * nesta etapa. Ver nota na entrega sobre adicionar um reason dedicado no
 * futuro, se for útil distinguir os dois casos no diagnóstico.
 */
export function toPatientForEligibility(row: PatientRow | undefined): PatientForEligibility | null {
  if (!row) return null;
  return {
    id: row.id,
    fisioterapeutaId: row.fisioterapeuta_id,
    phoneE164: row.phone_e164,
  };
}

/**
 * Escolhe o consentimento ATIVO de um paciente entre os já pré-filtrados
 * pela query (channel=whatsapp, purpose=appointment_reminder,
 * revoked_at IS NULL — ver supabase_data_port.ts).
 *
 * Reauditoria confirmou que produção TEM um índice único parcial para
 * exatamente este caso:
 *
 *   CREATE UNIQUE INDEX patient_consents_one_active_key
 *     ON patient_consents (patient_id, channel, purpose)
 *     WHERE revoked_at IS NULL
 *
 * (migration 0018, `indisvalid=true`/`indisready=true` em produção, 0
 * duplicidades hoje). Como a query já filtra por channel+purpose fixos,
 * mais de 1 linha para o mesmo patient_id só pode significar que esse
 * índice foi violado -- um estado IMPOSSÍVEL pelo schema atual, não um
 * cenário de negócio a tratar silenciosamente. Por isso: 0 -> sem
 * consentimento (null); 1 -> o consentimento ativo; >1 -> lança (erro de
 * integridade), nunca escolhe "o mais recente" como se fosse normal --
 * isso mascararia uma violação real de constraint.
 *
 * A mensagem de erro é deliberadamente GENÉRICA: não inclui patient_id,
 * telefone nem contact_value -- quem chama (orchestrate.ts) já sabe
 * appointmentId/fisioterapeutaId para diagnóstico e não precisa
 * serializar o identificador do paciente numa string de erro que pode
 * acabar em log ou em resposta HTTP.
 */
export function pickActiveConsent(rows: ConsentRow[]): ConsentRow | null {
  if (rows.length === 0) return null;
  if (rows.length === 1) return rows[0];
  throw new Error("integridade violada: múltiplos consentimentos ativos simultâneos");
}

export function toConsentForEligibility(row: ConsentRow | null): ConsentForEligibility | null {
  if (!row) return null;
  return {
    channel: row.channel,
    purpose: row.purpose,
    contactValue: row.contact_value,
    revokedAt: row.revoked_at,
  };
}

export interface ConnectionDiagnostics {
  connectionStatus: string;
  connectionReady: boolean;
}

/**
 * Puramente diagnóstico (seção 11 do pedido): NUNCA entra em
 * SchedulerDecision nem em SchedulingInput. 'none' quando o profissional
 * ainda não tem nenhuma linha em whatsapp_connections.
 */
export function computeConnectionDiagnostics(row: ConnectionRow | undefined): ConnectionDiagnostics {
  if (!row) return { connectionStatus: "none", connectionReady: false };
  return {
    connectionStatus: row.status,
    connectionReady: row.status === "connected" && row.phone_number_id !== null,
  };
}

/**
 * profiles.timezone é NOT NULL com DEFAULT, mas nada impede uma string
 * inválida ter sido gravada diretamente (sem CHECK de IANA no banco).
 * Validamos tentando instanciar um Intl.DateTimeFormat com essa timezone;
 * se o runtime rejeitar, é erro de dados/programação -- nunca adivinhamos
 * um fallback (ex.: UTC ou America/Sao_Paulo "só para funcionar").
 */
export function isValidIanaTimeZone(timeZone: string): boolean {
  try {
    new Intl.DateTimeFormat("en-US", { timeZone });
    return true;
  } catch {
    return false;
  }
}
