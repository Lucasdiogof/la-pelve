// Tipos de I/O desta camada: as linhas "crus" como vêm do banco (via
// PostgREST/Supabase client) e o contrato (DataPort) que a orquestração usa
// para buscar dados em lote. Nenhum tipo aqui carrega lógica — só forma.

export interface AppointmentRow {
  id: string;
  fisioterapeuta_id: string;
  date: string; // 'YYYY-MM-DD'
  time: string; // 'HH:MM:SS'
  status: string;
  patient_id: string | null;
  schedule_revision: number;
  schedule_revision_at: string; // timestamptz NOT NULL desde a 0021/0022
}

export interface PatientRow {
  id: string;
  fisioterapeuta_id: string;
  phone_e164: string | null;
  deleted_at: string | null;
}

export interface ConsentRow {
  id: string;
  patient_id: string;
  fisioterapeuta_id: string;
  channel: string;
  purpose: string;
  contact_value: string;
  granted_at: string;
  revoked_at: string | null;
}

export interface ProfileRow {
  id: string;
  timezone: string;
}

export interface ConnectionRow {
  fisioterapeuta_id: string;
  status: string;
  phone_number_id: string | null;
}

/**
 * Janela de busca para os appointments candidatos do dry-run. `to` é
 * inclusive. `fisioterapeutaId` filtra para 1 profissional quando presente;
 * ausente, varre todos (uso administrativo).
 */
export interface DryRunWindow {
  fromDate: string; // 'YYYY-MM-DD'
  toDate: string; // 'YYYY-MM-DD'
  fisioterapeutaId: string | null;
}

/**
 * Porta de dados: tudo que a orquestração precisa ler, em lote (nunca 1
 * query por appointment). A implementação real (supabase_data_port.ts) usa
 * o SupabaseClient com service_role; os testes usam um fake em memória —
 * nenhum dos dois é importado pelo outro.
 */
export interface SchedulerDataPort {
  listCandidateAppointments(window: DryRunWindow): Promise<AppointmentRow[]>;
  listPatientsByIds(patientIds: string[]): Promise<PatientRow[]>;
  listActiveReminderConsentsByPatientIds(patientIds: string[]): Promise<ConsentRow[]>;
  listProfilesByIds(fisioterapeutaIds: string[]): Promise<ProfileRow[]>;
  listConnectionsByFisioIds(fisioterapeutaIds: string[]): Promise<ConnectionRow[]>;
}
