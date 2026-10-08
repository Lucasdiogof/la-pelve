// Materialização real com leitura FALSA (SchedulerDataPort em memória) e
// porta de escrita que registra. A idempotência no banco (UNIQUE) é provada
// no E2E contra Postgres.

import { test } from "node:test";
import assert from "node:assert/strict";
import { materializeDueMessages } from "./run_materialization.ts";
import type { MaterializableMessage, MaterializationPort } from "../materialization/types.ts";
import type {
  AppointmentRow,
  ConnectionRow,
  ConsentRow,
  PatientRow,
  SchedulerDataPort,
} from "../../whatsapp-scheduler-dry-run/types.ts";

const FISIO = "fisio-1";
const PHONE = "+5562911110001";

interface World {
  appointments: AppointmentRow[];
  patients?: PatientRow[];
  consents?: ConsentRow[];
  connections?: ConnectionRow[];
}

function dataPort(world: World): SchedulerDataPort {
  return {
    listCandidateAppointments: async () => world.appointments,
    listPatientsByIds: async () => world.patients ?? [{ id: "pat-1", fisioterapeuta_id: FISIO, phone_e164: PHONE, deleted_at: null }],
    listActiveReminderConsentsByPatientIds: async () =>
      world.consents ?? [{
        id: "consent-1",
        patient_id: "pat-1",
        fisioterapeuta_id: FISIO,
        channel: "whatsapp",
        purpose: "appointment_reminder",
        contact_value: PHONE,
        granted_at: "2026-10-01T00:00:00Z",
        revoked_at: null,
      }],
    listProfilesByIds: async () => [{ id: FISIO, timezone: "America/Sao_Paulo" }],
    listConnectionsByFisioIds: async () =>
      world.connections ?? [{ fisioterapeuta_id: FISIO, status: "connected", phone_number_id: "123456789012345" }],
  };
}

function recordingPort() {
  const inserted: MaterializableMessage[] = [];
  const port: MaterializationPort = {
    async insertIfAbsent(message) {
      inserted.push(message);
      return { kind: "inserted" };
    },
  };
  return { port, inserted };
}

/** Consulta em SP: 30/10 08:00 (11:00Z), criada em `createdAt`. */
function appointment(createdAt: string, overrides: Partial<AppointmentRow> = {}): AppointmentRow {
  return {
    id: "appt-1",
    fisioterapeuta_id: FISIO,
    date: "2026-10-30",
    time: "08:00:00",
    status: "scheduled",
    patient_id: "pat-1",
    schedule_revision: 0,
    schedule_revision_at: createdAt,
    ...overrides,
  };
}

test("consulta recém-criada: materializa o aviso de agendamento agora; a solicitação de 12h ainda não", async () => {
  const { port, inserted } = recordingPort();
  const now = new Date("2026-10-27T14:00:00Z");
  const summary = await materializeDueMessages(dataPort({ appointments: [appointment("2026-10-27T13:59:00Z")] }), port, now);
  assert.deepEqual(inserted.map((m) => m.reminderType), ["appointment_confirmation"]);
  assert.equal(inserted[0].destinationPhoneE164, PHONE);
  assert.equal(inserted[0].consentId, "consent-1");
  assert.equal(summary.inserted, 1);
});

test("solicitação de confirmação de 12h nasce no momento certo (12h antes, dentro do lookahead)", async () => {
  const appt = appointment("2026-10-27T13:00:00Z");
  // 12h antes de 30/10 11:00Z = 29/10 23:00Z (20:00 SP, fora do silêncio).
  const early = recordingPort();
  await materializeDueMessages(dataPort({ appointments: [appt] }), early.port, new Date("2026-10-29T21:30:00Z"));
  assert.ok(!early.inserted.some((m) => m.reminderType === "appointment_12h"), "1h30 antes: ainda não");
  const due = recordingPort();
  await materializeDueMessages(dataPort({ appointments: [appt] }), due.port, new Date("2026-10-29T22:30:00Z"));
  const reminder = due.inserted.find((m) => m.reminderType === "appointment_12h");
  assert.equal(reminder?.scheduledFor, "2026-10-29T23:00:00.000Z");
});

test("sem consentimento ativo: nada é materializado", async () => {
  const { port, inserted } = recordingPort();
  await materializeDueMessages(
    dataPort({ appointments: [appointment("2026-10-27T13:59:00Z")], consents: [] }),
    port,
    new Date("2026-10-27T14:00:00Z"),
  );
  assert.equal(inserted.length, 0);
});

test("consentimento de outro telefone: nada é materializado", async () => {
  const { port, inserted } = recordingPort();
  await materializeDueMessages(
    dataPort({
      appointments: [appointment("2026-10-27T13:59:00Z")],
      patients: [{ id: "pat-1", fisioterapeuta_id: FISIO, phone_e164: "+5562999990000", deleted_at: null }],
    }),
    port,
    new Date("2026-10-27T14:00:00Z"),
  );
  assert.equal(inserted.length, 0);
});

test("profissional sem conexão pronta: nada entra na fila", async () => {
  for (const connections of [[], [{ fisioterapeuta_id: FISIO, status: "pending", phone_number_id: null }]]) {
    const { port, inserted } = recordingPort();
    const summary = await materializeDueMessages(
      dataPort({ appointments: [appointment("2026-10-27T13:59:00Z")], connections }),
      port,
      new Date("2026-10-27T14:00:00Z"),
    );
    assert.equal(inserted.length, 0);
    assert.equal(summary.skippedNoConnection, 1);
  }
});

test("consulta cancelada: nada é materializado", async () => {
  const { port, inserted } = recordingPort();
  await materializeDueMessages(
    dataPort({ appointments: [appointment("2026-10-27T13:59:00Z", { status: "cancelled" })] }),
    port,
    new Date("2026-10-27T14:00:00Z"),
  );
  assert.equal(inserted.length, 0);
});

test("consulta remarcada: aviso de remarcação da revisão nova", async () => {
  const { port, inserted } = recordingPort();
  await materializeDueMessages(
    dataPort({ appointments: [appointment("2026-10-27T15:00:00Z", { schedule_revision: 1 })] }),
    port,
    new Date("2026-10-27T15:01:00Z"),
  );
  assert.deepEqual(inserted.map((m) => [m.reminderType, m.scheduleRevision]), [["appointment_rescheduled", 1]]);
});

test("aviso vencido há mais de 24h não é materializado (ex.: conectou o WhatsApp depois)", async () => {
  const { port, inserted } = recordingPort();
  await materializeDueMessages(
    dataPort({ appointments: [appointment("2026-10-20T13:00:00Z")] }),
    port,
    new Date("2026-10-27T14:00:00Z"),
  );
  assert.equal(inserted.length, 0);
});

test("dado inconsistente num agendamento não impede os demais", async () => {
  const { port, inserted } = recordingPort();
  const two = [
    appointment("2026-10-27T13:59:00Z"),
    appointment("2026-10-27T13:59:00Z", { id: "appt-2", patient_id: "pat-2" }),
  ];
  const consents: ConsentRow[] = [
    { id: "c1", patient_id: "pat-2", fisioterapeuta_id: FISIO, channel: "whatsapp", purpose: "appointment_reminder", contact_value: PHONE, granted_at: "x", revoked_at: null },
    { id: "c2", patient_id: "pat-2", fisioterapeuta_id: FISIO, channel: "whatsapp", purpose: "appointment_reminder", contact_value: PHONE, granted_at: "x", revoked_at: null },
    { id: "c3", patient_id: "pat-1", fisioterapeuta_id: FISIO, channel: "whatsapp", purpose: "appointment_reminder", contact_value: PHONE, granted_at: "x", revoked_at: null },
  ];
  const originalError = console.error;
  console.error = () => {};
  try {
    const summary = await materializeDueMessages(
      dataPort({ appointments: two, consents }),
      port,
      new Date("2026-10-27T14:00:00Z"),
    );
    assert.equal(summary.appointmentErrors, 1);
  } finally {
    console.error = originalError;
  }
  assert.deepEqual(inserted.map((m) => m.appointmentId), ["appt-1"]);
});
