import { test } from "node:test";
import assert from "node:assert/strict";
import {
  decideMessagesForAppointment,
  hasAppointmentAlreadyOccurred,
  isStaleRevision,
  type AppointmentForScheduling,
  type SchedulerDecision,
} from "./decision.ts";
import { zonedTimeToUtc } from "./timezone.ts";

const TZ = "America/Sao_Paulo";
const FISIO = "fisio-1";

const eligiblePatient = {
  id: "patient-1",
  fisioterapeutaId: FISIO,
  phoneE164: "+5562999999999",
};
const activeConsent = {
  channel: "whatsapp",
  purpose: "appointment_reminder",
  contactValue: "+5562999999999",
  revokedAt: null,
};

function appt(overrides: Partial<AppointmentForScheduling>): AppointmentForScheduling {
  return {
    id: "appt-1",
    fisioterapeutaId: FISIO,
    date: "2026-10-10",
    time: "14:00:00",
    status: "scheduled",
    patientId: eligiblePatient.id,
    scheduleRevision: 0,
    scheduleRevisionAt: "2026-10-09T18:00:00-03:00",
    ...overrides,
  };
}

function localIso(y: number, m: number, d: number, h: number, mi: number): string {
  return zonedTimeToUtc(y, m, d, h, mi, 0, TZ).toISOString();
}

function byType(decisions: SchedulerDecision[], type: string): SchedulerDecision {
  const found = decisions.find((d) => d.messageType === type);
  assert.ok(found, `decision for ${type} not found`);
  return found!;
}

function decide(appointment: AppointmentForScheduling, overrides: { timeZone?: string; now?: Date } = {}) {
  return decideMessagesForAppointment({
    appointment,
    patient: eligiblePatient,
    consent: activeConsent,
    timeZone: overrides.timeZone ?? TZ,
    now: overrides.now ?? new Date("2026-10-01T00:00:00Z"),
  });
}

// ---------------------------------------------------------------------
// 1-5. Tipo de mensagem "imediata" por revision — nunca o tipo errado.
// ---------------------------------------------------------------------

test("1: revision 0 gera confirmation + possível 12h", () => {
  const decisions = decide(appt({ scheduleRevision: 0 }));
  assert.ok(decisions.some((d) => d.messageType === "appointment_confirmation"));
  assert.ok(decisions.some((d) => d.messageType === "appointment_12h"));
});

test("2: revision 1 gera rescheduled + possível 12h", () => {
  const decisions = decide(appt({ scheduleRevision: 1 }));
  assert.ok(decisions.some((d) => d.messageType === "appointment_rescheduled"));
  assert.ok(decisions.some((d) => d.messageType === "appointment_12h"));
});

test("3: revision 2 gera rescheduled + possível 12h", () => {
  const decisions = decide(appt({ scheduleRevision: 2 }));
  assert.ok(decisions.some((d) => d.messageType === "appointment_rescheduled"));
  assert.ok(decisions.some((d) => d.messageType === "appointment_12h"));
});

test("4: revision 0 nunca gera rescheduled", () => {
  const decisions = decide(appt({ scheduleRevision: 0 }));
  assert.ok(!decisions.some((d) => d.messageType === "appointment_rescheduled"));
});

test("5: revision >= 1 nunca gera confirmation", () => {
  for (const rev of [1, 2, 5]) {
    const decisions = decide(appt({ scheduleRevision: rev }));
    assert.ok(!decisions.some((d) => d.messageType === "appointment_confirmation"));
  }
});

// ---------------------------------------------------------------------
// 6. scheduleRevisionAt é a ÚNICA referência temporal usada para
// antecedência — não existe mais branch especial para revision 0.
// ---------------------------------------------------------------------

test("6: scheduleRevisionAt é a única referência temporal, para qualquer revision", () => {
  const revAt = localIso(2026, 10, 9, 18, 0); // 20h antes de 14:00 do dia 10
  const rev0 = decide(appt({ scheduleRevision: 0, scheduleRevisionAt: revAt }));
  const rev3 = decide(appt({ scheduleRevision: 3, scheduleRevisionAt: revAt }));
  // Mesmo scheduleRevisionAt -> mesmo scheduledFor em qualquer revision,
  // provando que não existe fonte temporal alternativa (ex.: created_at)
  // sendo usada por baixo dos panos.
  assert.equal(byType(rev0, "appointment_confirmation").scheduledFor, byType(rev3, "appointment_rescheduled").scheduledFor);
  assert.equal(byType(rev0, "appointment_12h").scheduledFor, byType(rev3, "appointment_12h").scheduledFor);
});

// ---------------------------------------------------------------------
// 7-9. Regra das 12h.
// ---------------------------------------------------------------------

test("7: criado/remarcado 20h antes -> imediata + reminder", () => {
  const decisions = decide(appt({ scheduleRevisionAt: localIso(2026, 10, 9, 18, 0) }));
  assert.equal(byType(decisions, "appointment_confirmation").eligible, true);
  assert.equal(byType(decisions, "appointment_12h").eligible, true);
});

test("8: exatamente 12h antes -> só imediata", () => {
  const decisions = decide(appt({ scheduleRevisionAt: localIso(2026, 10, 10, 2, 0) }));
  assert.equal(byType(decisions, "appointment_confirmation").eligible, true);
  const reminder = byType(decisions, "appointment_12h");
  assert.equal(reminder.eligible, false);
  assert.equal(reminder.reason, "less_than_or_equal_12h_notice");
});

test("9: 11h59 antes -> só imediata", () => {
  const decisions = decide(appt({ scheduleRevisionAt: localIso(2026, 10, 10, 2, 1) }));
  assert.equal(byType(decisions, "appointment_confirmation").eligible, true);
  const reminder = byType(decisions, "appointment_12h");
  assert.equal(reminder.eligible, false);
  assert.equal(reminder.reason, "less_than_or_equal_12h_notice");
});

// ---------------------------------------------------------------------
// 10-12. Regra das 2h (prioridade da mensagem imediata).
// ---------------------------------------------------------------------

test("10: imediata 20:30 e reminder nominal 21:00 -> reminder suprimido (<2h)", () => {
  const a = appt({
    date: "2026-10-10",
    time: "09:00:00", // 12h antes = 21:00 do dia 9
    scheduleRevisionAt: localIso(2026, 10, 9, 20, 30),
  });
  const decisions = decide(a);
  assert.equal(byType(decisions, "appointment_confirmation").eligible, true);
  const reminder = byType(decisions, "appointment_12h");
  assert.equal(reminder.eligible, false);
  assert.equal(reminder.reason, "too_close_to_immediate_message");
});

test("11: diferença exatamente 2h -> os dois elegíveis", () => {
  const a = appt({
    date: "2026-10-10",
    time: "09:00:00", // 12h antes = 21:00 do dia 9
    scheduleRevisionAt: localIso(2026, 10, 9, 19, 0), // 2h antes do nominal do 12h (21:00)
  });
  const decisions = decide(a);
  assert.equal(byType(decisions, "appointment_confirmation").eligible, true);
  assert.equal(byType(decisions, "appointment_12h").eligible, true);
});

test("12: revision >= 1 -- rescheduled também tem prioridade sobre reminder <2h", () => {
  const a = appt({
    scheduleRevision: 2,
    date: "2026-10-10",
    time: "09:00:00",
    scheduleRevisionAt: localIso(2026, 10, 9, 20, 30),
  });
  const decisions = decide(a);
  assert.equal(byType(decisions, "appointment_rescheduled").eligible, true);
  const reminder = byType(decisions, "appointment_12h");
  assert.equal(reminder.eligible, false);
  assert.equal(reminder.reason, "too_close_to_immediate_message");
});

// ---------------------------------------------------------------------
// 13-15. Silêncio.
// ---------------------------------------------------------------------

test("13: imediata durante silêncio -> vai para 07:00", () => {
  const a = appt({
    date: "2026-10-15",
    time: "14:00:00",
    scheduleRevisionAt: localIso(2026, 10, 9, 23, 0),
  });
  const decisions = decide(a);
  const confirmation = byType(decisions, "appointment_confirmation");
  assert.equal(confirmation.eligible, true);
  assert.equal(confirmation.scheduledFor, localIso(2026, 10, 10, 7, 0));
});

test("14: reminder nominal 04:00 -> vai para 07:00", () => {
  const a = appt({
    date: "2026-10-10",
    time: "16:00:00", // 12h antes = 04:00 do mesmo dia
    scheduleRevisionAt: localIso(2026, 10, 9, 10, 0),
  });
  const decisions = decide(a);
  const reminder = byType(decisions, "appointment_12h");
  assert.equal(reminder.eligible, true);
  assert.equal(reminder.scheduledFor, localIso(2026, 10, 10, 7, 0));
});

test("15: reminder nominal 22:00 -> vai para 07:00 do dia da consulta", () => {
  const a = appt({
    date: "2026-10-10",
    time: "10:00:00", // 12h antes = 22:00 do dia 9
    scheduleRevisionAt: localIso(2026, 10, 9, 8, 0),
  });
  const decisions = decide(a);
  const reminder = byType(decisions, "appointment_12h");
  assert.equal(reminder.eligible, true);
  assert.equal(reminder.scheduledFor, localIso(2026, 10, 10, 7, 0));
});

// ---------------------------------------------------------------------
// 16-17. Consulta já ocorrida.
// ---------------------------------------------------------------------

test("16: envio efetivo cairia depois do horário da consulta -> inelegível", () => {
  const a = appt({
    date: "2026-10-10",
    time: "06:00:00", // consulta antes das 07:00
    scheduleRevisionAt: localIso(2026, 10, 9, 23, 30), // silêncio -> efetivo seria 07:00 do dia 10
  });
  const decisions = decide(a, { now: new Date("2026-10-01T00:00:00Z") });
  const confirmation = byType(decisions, "appointment_confirmation");
  assert.equal(confirmation.eligible, false);
  assert.equal(confirmation.reason, "appointment_already_occurred");
});

test("17: consulta já ocorrida (now >= appointmentStart) -> as duas inelegíveis", () => {
  const a = appt({ date: "2026-10-10", time: "14:00:00" });
  const decisions = decide(a, { now: new Date("2026-10-10T17:00:00Z") }); // 14:00 -03:00 = 17:00Z
  for (const d of decisions) {
    assert.equal(d.eligible, false);
    assert.equal(d.reason, "appointment_already_occurred");
  }
});

// ---------------------------------------------------------------------
// 18-22. Bloqueios globais.
// ---------------------------------------------------------------------

test("18: appointment cancelled -> as duas inelegíveis", () => {
  const decisions = decide(appt({ status: "cancelled" }));
  for (const d of decisions) {
    assert.equal(d.eligible, false);
    assert.equal(d.reason, "appointment_cancelled");
  }
});

test("19: patient_id null -> as duas inelegíveis", () => {
  const decisions = decideMessagesForAppointment({
    appointment: appt({ patientId: null }),
    patient: null,
    consent: null,
    timeZone: TZ,
    now: new Date("2026-10-01T00:00:00Z"),
  });
  for (const d of decisions) {
    assert.equal(d.eligible, false);
    assert.equal(d.reason, "missing_patient");
  }
});

test("20: phone_e164 inválido (null) -> as duas inelegíveis", () => {
  const decisions = decideMessagesForAppointment({
    appointment: appt({}),
    patient: { ...eligiblePatient, phoneE164: null },
    consent: activeConsent,
    timeZone: TZ,
    now: new Date("2026-10-01T00:00:00Z"),
  });
  for (const d of decisions) {
    assert.equal(d.eligible, false);
    assert.equal(d.reason, "invalid_phone");
  }
});

test("21: sem consentimento -> as duas inelegíveis", () => {
  const decisions = decideMessagesForAppointment({
    appointment: appt({}),
    patient: eligiblePatient,
    consent: null,
    timeZone: TZ,
    now: new Date("2026-10-01T00:00:00Z"),
  });
  for (const d of decisions) {
    assert.equal(d.eligible, false);
    assert.equal(d.reason, "missing_consent");
  }
});

test("22: consent mismatch (telefone diferente) -> as duas inelegíveis", () => {
  const decisions = decideMessagesForAppointment({
    appointment: appt({}),
    patient: eligiblePatient,
    consent: { ...activeConsent, contactValue: "+5562988888888" },
    timeZone: TZ,
    now: new Date("2026-10-01T00:00:00Z"),
  });
  for (const d of decisions) {
    assert.equal(d.eligible, false);
    assert.equal(d.reason, "consent_phone_mismatch");
  }
});

// ---------------------------------------------------------------------
// 23. Consentimento válido: segue o cálculo temporal normal.
// ---------------------------------------------------------------------

test("23: consentimento válido -> segue o cálculo temporal normal (elegível)", () => {
  const decisions = decide(appt({ scheduleRevisionAt: localIso(2026, 10, 9, 10, 0) })); // >12h antes, fora do silêncio
  assert.equal(byType(decisions, "appointment_confirmation").eligible, true);
});

// ---------------------------------------------------------------------
// 24. Stale revision: detectado pela função SEPARADA (não por
// decideMessagesForAppointment, que só calcula a revision atual).
// ---------------------------------------------------------------------

test("24: stale revision é detectado por isStaleRevision, separado da decisão da revision atual", () => {
  assert.equal(isStaleRevision(0, 1), true);
  assert.equal(isStaleRevision(1, 1), false);
  // A -> B -> A: revision 0 e 2 têm o mesmo valor de horário, mas isso é
  // irrelevante -- só o número da revisão importa.
  assert.equal(isStaleRevision(0, 2), true);
  assert.equal(isStaleRevision(2, 2), false);
});

// ---------------------------------------------------------------------
// Timezone (ver também timezone.test.ts para os testes 25-32 de
// silêncio/DST/virada de dia-mês-ano, que são testados na unidade
// menor: as funções de timezone.ts, não decideMessagesForAppointment).
// ---------------------------------------------------------------------

test("extra: America/Sao_Paulo calcula o horário absoluto corretamente", () => {
  const decisions = decide(appt({ date: "2026-10-10", time: "14:00:00" }), { timeZone: "America/Sao_Paulo" });
  assert.notEqual(byType(decisions, "appointment_confirmation").reason, "appointment_already_occurred");
});

test("extra: não assume offset fixo -03 -- America/New_York com DST dá resultado diferente em janeiro e julho", () => {
  const winter = appt({ date: "2026-01-15", time: "14:00:00", scheduleRevisionAt: "2026-01-14T14:00:00-05:00" });
  const summer = appt({ date: "2026-07-15", time: "14:00:00", scheduleRevisionAt: "2026-07-14T14:00:00-04:00" });
  const winterDecisions = decideMessagesForAppointment({
    appointment: winter,
    patient: eligiblePatient,
    consent: activeConsent,
    timeZone: "America/New_York",
    now: new Date("2026-01-01T00:00:00Z"),
  });
  const summerDecisions = decideMessagesForAppointment({
    appointment: summer,
    patient: eligiblePatient,
    consent: activeConsent,
    timeZone: "America/New_York",
    now: new Date("2026-07-01T00:00:00Z"),
  });
  assert.equal(byType(winterDecisions, "appointment_confirmation").eligible, true);
  assert.equal(byType(summerDecisions, "appointment_confirmation").eligible, true);
});

// ---------------------------------------------------------------------
// Falha explícita (programação), não "reason" de negócio: schema do
// banco garante scheduleRevisionAt NOT NULL -- chegar vazio/nulo aqui
// é bug de quem montou o input, nunca um caso real. Ver seção 15 do
// pedido: decideMessagesForAppointment lança, não finge normalidade.
// ---------------------------------------------------------------------

test("extra: scheduleRevisionAt ausente lança erro de programação (nunca finge ser um reason de negócio)", () => {
  const a = appt({ scheduleRevisionAt: "" as unknown as string });
  assert.throws(
    () =>
      decideMessagesForAppointment({
        appointment: a,
        patient: eligiblePatient,
        consent: activeConsent,
        timeZone: TZ,
        now: new Date("2026-10-01T00:00:00Z"),
      }),
    TypeError,
  );
});

test("extra: hasAppointmentAlreadyOccurred", () => {
  const start = zonedTimeToUtc(2026, 10, 10, 14, 0, 0, TZ);
  assert.equal(hasAppointmentAlreadyOccurred(start, new Date("2026-10-10T16:59:59Z")), false);
  assert.equal(hasAppointmentAlreadyOccurred(start, new Date("2026-10-10T17:00:00Z")), true);
});
