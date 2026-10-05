import { test } from "node:test";
import assert from "node:assert/strict";
import { isDryRunAppointmentError, runDryRun, type DryRunReport } from "./orchestrate.ts";
import type {
  AppointmentRow,
  ConnectionRow,
  ConsentRow,
  DryRunWindow,
  PatientRow,
  ProfileRow,
  SchedulerDataPort,
} from "./types.ts";

const WINDOW: DryRunWindow = { fromDate: "2026-10-01", toDate: "2026-10-31", fisioterapeutaId: null };
const NOW = new Date("2026-10-01T00:00:00Z");

/**
 * Porta de dados FALSA, em memória -- nunca toca banco, nunca expõe
 * insert/update/delete (a interface SchedulerDataPort só tem os 5 métodos
 * de leitura). Registra quantas vezes cada método é chamado, para provar
 * que não há N+1 (item 17).
 */
interface FakeData {
  appointments: AppointmentRow[];
  patients: PatientRow[];
  consents: ConsentRow[];
  profiles: ProfileRow[];
  connections: ConnectionRow[];
}

class FakeDataPort implements SchedulerDataPort {
  calls = { appointments: 0, patients: 0, consents: 0, profiles: 0, connections: 0 };
  private readonly data: FakeData;

  constructor(data: FakeData) {
    this.data = data;
  }

  async listCandidateAppointments(_window: DryRunWindow): Promise<AppointmentRow[]> {
    this.calls.appointments++;
    return this.data.appointments;
  }
  async listPatientsByIds(ids: string[]): Promise<PatientRow[]> {
    this.calls.patients++;
    return this.data.patients.filter((p) => ids.includes(p.id));
  }
  async listActiveReminderConsentsByPatientIds(ids: string[]): Promise<ConsentRow[]> {
    this.calls.consents++;
    return this.data.consents.filter((c) => ids.includes(c.patient_id));
  }
  async listProfilesByIds(ids: string[]): Promise<ProfileRow[]> {
    this.calls.profiles++;
    return this.data.profiles.filter((p) => ids.includes(p.id));
  }
  async listConnectionsByFisioIds(ids: string[]): Promise<ConnectionRow[]> {
    this.calls.connections++;
    return this.data.connections.filter((c) => ids.includes(c.fisioterapeuta_id));
  }
}

const eligibleProfile: ProfileRow = { id: "fisio-1", timezone: "America/Sao_Paulo" };
const eligiblePatient: PatientRow = {
  id: "patient-1",
  fisioterapeuta_id: "fisio-1",
  phone_e164: "+5562999999999",
  deleted_at: null,
};
const activeConsent: ConsentRow = {
  id: "consent-1",
  patient_id: "patient-1",
  fisioterapeuta_id: "fisio-1",
  channel: "whatsapp",
  purpose: "appointment_reminder",
  contact_value: "+5562999999999",
  granted_at: "2026-01-01T00:00:00Z",
  revoked_at: null,
};

function appt(overrides: Partial<AppointmentRow> = {}): AppointmentRow {
  return {
    id: "appt-1",
    fisioterapeuta_id: "fisio-1",
    date: "2026-10-10",
    time: "14:00:00",
    status: "scheduled",
    patient_id: "patient-1",
    schedule_revision: 0,
    schedule_revision_at: "2026-10-09T10:00:00-03:00", // >12h antes, fora do silêncio
    ...overrides,
  };
}

function okResult(report: DryRunReport, index = 0) {
  const r = report.appointments[index];
  assert.ok(!isDryRunAppointmentError(r), `esperava sucesso, veio error: ${JSON.stringify(r)}`);
  return r as Exclude<typeof r, { error: string }>;
}

// ---------------------------------------------------------------------
// 1. appointment cancelled NÃO é removido pelo DataPort/orquestração --
// chega à lógica pura e produz appointment_cancelled no relatório, em vez
// de simplesmente desaparecer da execução.
// ---------------------------------------------------------------------

test("1: appointment cancelled chega ao scheduler e aparece bloqueado com appointment_cancelled", async () => {
  const port = new FakeDataPort({
    appointments: [appt({ status: "cancelled" })],
    patients: [eligiblePatient],
    consents: [activeConsent],
    profiles: [eligibleProfile],
    connections: [],
  });
  const report = await runDryRun(port, WINDOW, NOW);
  assert.equal(report.totals.appointments, 1, "o cancelled continua sendo um candidato, não é filtrado antes");
  const r = okResult(report);
  for (const d of r.decisions) {
    assert.equal(d.eligible, false);
    assert.equal(d.reason, "appointment_cancelled");
  }
});

// ---------------------------------------------------------------------
// 2, 6, 7, 8. Elegibilidade do paciente, de ponta a ponta pela orquestração.
// ---------------------------------------------------------------------

test("2: patient_id null -> appointment_confirmation e appointment_12h inelegíveis (missing_patient)", async () => {
  const port = new FakeDataPort({
    appointments: [appt({ patient_id: null })],
    patients: [],
    consents: [],
    profiles: [eligibleProfile],
    connections: [],
  });
  const report = await runDryRun(port, WINDOW, NOW);
  const r = okResult(report);
  for (const d of r.decisions) {
    assert.equal(d.eligible, false);
    assert.equal(d.reason, "missing_patient");
  }
});

test("6: phone_e164 null -> invalid_phone", async () => {
  const port = new FakeDataPort({
    appointments: [appt()],
    patients: [{ ...eligiblePatient, phone_e164: null }],
    consents: [activeConsent],
    profiles: [eligibleProfile],
    connections: [],
  });
  const report = await runDryRun(port, WINDOW, NOW);
  const r = okResult(report);
  for (const d of r.decisions) assert.equal(d.reason, "invalid_phone");
});

test("7: sem consentimento ativo -> missing_consent", async () => {
  const port = new FakeDataPort({
    appointments: [appt()],
    patients: [eligiblePatient],
    consents: [],
    profiles: [eligibleProfile],
    connections: [],
  });
  const report = await runDryRun(port, WINDOW, NOW);
  const r = okResult(report);
  for (const d of r.decisions) assert.equal(d.reason, "missing_consent");
});

test("8: consentimento revogado, se vazar da query, ainda é rejeitado pela lógica pura (defesa em profundidade)", async () => {
  const port = new FakeDataPort({
    appointments: [appt()],
    patients: [eligiblePatient],
    consents: [{ ...activeConsent, revoked_at: "2026-01-02T00:00:00Z" }],
    profiles: [eligibleProfile],
    connections: [],
  });
  const report = await runDryRun(port, WINDOW, NOW);
  const r = okResult(report);
  for (const d of r.decisions) assert.equal(d.reason, "missing_consent");
});

test("9: consentimento de outro channel, se vazar da query, ainda é rejeitado pela lógica pura", async () => {
  const port = new FakeDataPort({
    appointments: [appt()],
    patients: [eligiblePatient],
    consents: [{ ...activeConsent, channel: "sms" }],
    profiles: [eligibleProfile],
    connections: [],
  });
  const report = await runDryRun(port, WINDOW, NOW);
  const r = okResult(report);
  for (const d of r.decisions) assert.equal(d.reason, "missing_consent");
});

test("10: consentimento de outro purpose, se vazar da query, ainda é rejeitado pela lógica pura", async () => {
  const port = new FakeDataPort({
    appointments: [appt()],
    patients: [eligiblePatient],
    consents: [{ ...activeConsent, purpose: "marketing" }],
    profiles: [eligibleProfile],
    connections: [],
  });
  const report = await runDryRun(port, WINDOW, NOW);
  const r = okResult(report);
  for (const d of r.decisions) assert.equal(d.reason, "missing_consent");
});

test("11: contact_value diferente -> consent_phone_mismatch", async () => {
  const port = new FakeDataPort({
    appointments: [appt()],
    patients: [eligiblePatient],
    consents: [{ ...activeConsent, contact_value: "+5562988888888" }],
    profiles: [eligibleProfile],
    connections: [],
  });
  const report = await runDryRun(port, WINDOW, NOW);
  const r = okResult(report);
  for (const d of r.decisions) assert.equal(d.reason, "consent_phone_mismatch");
});

test(">1 consentimento ativo simultâneo (estado impossível) -> linha reportada como error, nunca como decisão normal", async () => {
  const port = new FakeDataPort({
    appointments: [appt()],
    patients: [eligiblePatient],
    consents: [activeConsent, { ...activeConsent, id: "consent-2", granted_at: "2026-02-01T00:00:00Z" }],
    profiles: [eligibleProfile],
    connections: [],
  });
  const report = await runDryRun(port, WINDOW, NOW);
  const r = report.appointments[0];
  assert.ok(isDryRunAppointmentError(r));
  const errorMessage = (r as { error: string }).error;
  assert.equal(errorMessage, "integridade violada: múltiplos consentimentos ativos simultâneos");
  assert.equal(report.totals.errors, 1);
  assert.equal(report.totals.eligibleMessages, 0);
  assert.equal(report.totals.ineligibleMessages, 0);
});

test("9: erro de múltiplos consentimentos ativos não contém patient_id/telefone/contact_value no relatório inteiro", async () => {
  const port = new FakeDataPort({
    appointments: [appt({ patient_id: "patient-bem-secreto" })],
    patients: [{ ...eligiblePatient, id: "patient-bem-secreto" }],
    consents: [
      { ...activeConsent, patient_id: "patient-bem-secreto" },
      { ...activeConsent, id: "consent-2", patient_id: "patient-bem-secreto", granted_at: "2026-02-01T00:00:00Z" },
    ],
    profiles: [eligibleProfile],
    connections: [],
  });
  const report = await runDryRun(port, WINDOW, NOW);
  const json = JSON.stringify(report);
  assert.ok(!json.includes("patient-bem-secreto"));
  assert.ok(!json.includes("+5562999999999"));
});

// ---------------------------------------------------------------------
// 12. profile/timezone correto chega intacto na decisão.
// ---------------------------------------------------------------------

test("12: profile/timezone correto -> elegível com cálculo temporal normal", async () => {
  const port = new FakeDataPort({
    appointments: [appt()],
    patients: [eligiblePatient],
    consents: [activeConsent],
    profiles: [eligibleProfile],
    connections: [],
  });
  const report = await runDryRun(port, WINDOW, NOW);
  const r = okResult(report);
  assert.equal(r.decisions.find((d) => d.messageType === "appointment_confirmation")!.eligible, true);
});

test("timezone inválida em profiles -> erro de dados reportado por linha, não adivinhado, não derruba o relatório", async () => {
  const port = new FakeDataPort({
    appointments: [appt()],
    patients: [eligiblePatient],
    consents: [activeConsent],
    profiles: [{ id: "fisio-1", timezone: "Nao/Existe" }],
    connections: [],
  });
  const report = await runDryRun(port, WINDOW, NOW);
  const r = report.appointments[0];
  assert.ok(isDryRunAppointmentError(r));
  assert.match((r as { error: string }).error, /timezone/i);
  assert.equal(report.totals.errors, 1);
});

// ---------------------------------------------------------------------
// 13, 14, 15. connectionReady é só diagnóstico (já cobertos em
// transform.test.ts na unidade; aqui confirmamos que chega no relatório
// e nunca influencia `decisions`).
// ---------------------------------------------------------------------

test("13/14/15: connectionStatus/connectionReady aparecem no relatório e não mudam as decisions", async () => {
  const withConnection = new FakeDataPort({
    appointments: [appt()],
    patients: [eligiblePatient],
    consents: [activeConsent],
    profiles: [eligibleProfile],
    connections: [{ fisioterapeuta_id: "fisio-1", status: "connected", phone_number_id: "123" }],
  });
  const withoutConnection = new FakeDataPort({
    appointments: [appt()],
    patients: [eligiblePatient],
    consents: [activeConsent],
    profiles: [eligibleProfile],
    connections: [],
  });
  const reportWith = okResult(await runDryRun(withConnection, WINDOW, NOW));
  const reportWithout = okResult(await runDryRun(withoutConnection, WINDOW, NOW));
  assert.equal(reportWith.connectionReady, true);
  assert.equal(reportWithout.connectionReady, false);
  // Mesmas decisions nos dois casos -- connection nunca entra na decisão.
  assert.deepEqual(reportWith.decisions, reportWithout.decisions);
});

// ---------------------------------------------------------------------
// 16. now único para toda a execução.
// ---------------------------------------------------------------------

test("16: now é capturado uma vez e usado para todas as decisões (generatedAt == now injetado)", async () => {
  const port = new FakeDataPort({
    appointments: [appt({ id: "a1" }), appt({ id: "a2" })],
    patients: [eligiblePatient],
    consents: [activeConsent],
    profiles: [eligibleProfile],
    connections: [],
  });
  const report = await runDryRun(port, WINDOW, NOW);
  assert.equal(report.generatedAt, NOW.toISOString());
});

// ---------------------------------------------------------------------
// 17. Lote: N appointments do mesmo profissional -> 1 chamada por tipo
// de dado (nunca N chamadas).
// ---------------------------------------------------------------------

test("17: dois appointments do mesmo profissional reutilizam dados carregados em lote (sem N+1)", async () => {
  const port = new FakeDataPort({
    appointments: [appt({ id: "a1" }), appt({ id: "a2" })],
    patients: [eligiblePatient],
    consents: [activeConsent],
    profiles: [eligibleProfile],
    connections: [],
  });
  await runDryRun(port, WINDOW, NOW);
  assert.equal(port.calls.appointments, 1);
  assert.equal(port.calls.patients, 1);
  assert.equal(port.calls.consents, 1);
  assert.equal(port.calls.profiles, 1);
  assert.equal(port.calls.connections, 1);
});

// ---------------------------------------------------------------------
// 18, 19. Nenhum dado clínico/pessoal sensível no retorno.
// ---------------------------------------------------------------------

test("18 e 19: o relatório inteiro não contém patient_name, telefone nem contact_value", async () => {
  const port = new FakeDataPort({
    appointments: [appt()],
    patients: [eligiblePatient],
    consents: [activeConsent],
    profiles: [eligibleProfile],
    connections: [{ fisioterapeuta_id: "fisio-1", status: "connected", phone_number_id: "123" }],
  });
  const report = await runDryRun(port, WINDOW, NOW);
  const json = JSON.stringify(report);
  assert.ok(!json.includes("+5562999999999"), "não deve conter o telefone");
  assert.ok(!json.includes("patient_name"), "não deve conter patient_name");
  assert.ok(!("patientId" in (report.appointments[0] as object)), "nem precisa de patientId por padrão");
});

// ---------------------------------------------------------------------
// 20. Dry-run é somente leitura: a interface da porta só expõe métodos
// de leitura (garantido em tempo de compilação pelo tipo SchedulerDataPort,
// confirmado aqui em runtime).
// ---------------------------------------------------------------------

test("20: FakeDataPort só expõe os 5 métodos de leitura -- nenhum insert/update/delete", () => {
  const port = new FakeDataPort({ appointments: [], patients: [], consents: [], profiles: [], connections: [] });
  const methodNames = Object.getOwnPropertyNames(Object.getPrototypeOf(port)).filter((m) => m !== "constructor");
  assert.deepEqual(
    [...methodNames].sort(),
    [
      "listActiveReminderConsentsByPatientIds",
      "listCandidateAppointments",
      "listConnectionsByFisioIds",
      "listPatientsByIds",
      "listProfilesByIds",
    ].sort(),
  );
});

// ---------------------------------------------------------------------
// 21. Falha de consulta nunca é interpretada como "sem dados".
// ---------------------------------------------------------------------

test("21: falha na consulta de appointments propaga o erro (nunca devolve relatório vazio silenciosamente)", async () => {
  const port: SchedulerDataPort = {
    listCandidateAppointments: () => Promise.reject(new Error("conexão com o banco falhou")),
    listPatientsByIds: () => Promise.resolve([]),
    listActiveReminderConsentsByPatientIds: () => Promise.resolve([]),
    listProfilesByIds: () => Promise.resolve([]),
    listConnectionsByFisioIds: () => Promise.resolve([]),
  };
  await assert.rejects(() => runDryRun(port, WINDOW, NOW), /conexão com o banco falhou/);
});

test("21b: falha na consulta de profiles também propaga (não finge 0 appointments)", async () => {
  const port: SchedulerDataPort = {
    listCandidateAppointments: () => Promise.resolve([appt()]),
    listPatientsByIds: () => Promise.resolve([eligiblePatient]),
    listActiveReminderConsentsByPatientIds: () => Promise.resolve([activeConsent]),
    listProfilesByIds: () => Promise.reject(new Error("timeout lendo profiles")),
    listConnectionsByFisioIds: () => Promise.resolve([]),
  };
  await assert.rejects(() => runDryRun(port, WINDOW, NOW), /timeout lendo profiles/);
});

// ---------------------------------------------------------------------
// 22. Erro parcial (1 linha com dado inválido) não produz resposta
// falsamente bem-sucedida: a linha boa continua elegível, a quebrada
// aparece como `error`, e totals.errors reflete isso -- nunca escondido
// dentro de ineligibleMessages.
// ---------------------------------------------------------------------

test("22: 1 appointment com profile ausente (erro) + 1 appointment normal -> ambos refletidos corretamente", async () => {
  const port = new FakeDataPort({
    appointments: [
      appt({ id: "a-ok", fisioterapeuta_id: "fisio-1" }),
      appt({ id: "a-quebrado", fisioterapeuta_id: "fisio-2" }), // sem profile correspondente
    ],
    patients: [eligiblePatient],
    consents: [activeConsent],
    profiles: [eligibleProfile], // só fisio-1
    connections: [],
  });
  const report = await runDryRun(port, WINDOW, NOW);
  assert.equal(report.totals.appointments, 2);
  assert.equal(report.totals.errors, 1);

  const ok = report.appointments.find((a) => a.appointmentId === "a-ok")!;
  const broken = report.appointments.find((a) => a.appointmentId === "a-quebrado")!;
  assert.ok(!isDryRunAppointmentError(ok));
  assert.ok(isDryRunAppointmentError(broken));
  assert.match((broken as { error: string }).error, /profile ausente/i);
});

// ---------------------------------------------------------------------
// Confirma explicitamente persisted=false e mode="dry-run" sempre.
// ---------------------------------------------------------------------

test("relatório sempre declara persisted=false e mode='dry-run'", async () => {
  const port = new FakeDataPort({ appointments: [], patients: [], consents: [], profiles: [], connections: [] });
  const report = await runDryRun(port, WINDOW, NOW);
  assert.equal(report.persisted, false);
  assert.equal(report.mode, "dry-run");
});
