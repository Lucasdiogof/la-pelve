// Testes da lógica PURA de reconciliação. Sem I/O, sem relógio.
//
// Ações: cancel (permanente: stale_schedule_revision | consent_revoked),
// blocked (temporário: appointment_cancelled, sem UPDATE) e keep.

import { test } from "node:test";
import assert from "node:assert/strict";
import { decideReconciliation, ReconciliationIntegrityError } from "./decide.ts";
import type { MessageStatus, ReconciliationInput } from "./types.ts";

/** Os 6 valores REAIS de appointments.status no app (AppointmentStatus.name). */
const APPOINTMENT_STATUSES = ["scheduled", "confirmed", "fulfilled", "cancelled", "noShow", "rescheduled"] as const;

/** Base: scheduled, consulta normal, revisão atual, consentimento ativo. */
function input(overrides: {
  status?: MessageStatus;
  messageRevision?: number;
  appointmentStatus?: string;
  appointmentRevision?: number;
  revokedAt?: string | null;
  appointment?: ReconciliationInput["appointment"];
  consent?: ReconciliationInput["consent"];
} = {}): ReconciliationInput {
  return {
    message: {
      id: "msg-1",
      status: overrides.status ?? "scheduled",
      scheduleRevision: overrides.messageRevision ?? 2,
      appointmentId: "appt-1",
      consentId: "consent-1",
    },
    appointment: "appointment" in overrides
      ? overrides.appointment!
      : {
        id: "appt-1",
        status: overrides.appointmentStatus ?? "scheduled",
        scheduleRevision: overrides.appointmentRevision ?? 2,
      },
    consent: "consent" in overrides
      ? overrides.consent!
      : { id: "consent-1", revokedAt: overrides.revokedAt ?? null },
  };
}

const REVOKED = "2026-10-05T12:00:00.000Z";
const STALE = { messageRevision: 1, appointmentRevision: 2 } as const;

// ---------------------------------------------------------------------
// Scheduled: keep / cancel permanente / blocked temporário
// ---------------------------------------------------------------------

test("1: scheduled + tudo válido -> keep (reason null)", () => {
  assert.deepEqual(decideReconciliation(input()), { action: "keep", reason: null });
});

test("2: scheduled + consulta cancelled (revisão atual, consentimento ativo) -> BLOCKED appointment_cancelled (sem cancelar a mensagem)", () => {
  assert.deepEqual(decideReconciliation(input({ appointmentStatus: "cancelled" })), {
    action: "blocked",
    reason: "appointment_cancelled",
  });
});

test("3: scheduled + stale -> cancel stale_schedule_revision", () => {
  assert.deepEqual(decideReconciliation(input({ ...STALE })), {
    action: "cancel",
    reason: "stale_schedule_revision",
  });
});

test("3b: revisão da mensagem MAIOR que a da consulta também é divergente (impossível no modelo; tratada como stale)", () => {
  assert.deepEqual(decideReconciliation(input({ messageRevision: 3, appointmentRevision: 2 })), {
    action: "cancel",
    reason: "stale_schedule_revision",
  });
});

test("4: scheduled + consentimento revogado -> cancel consent_revoked", () => {
  assert.deepEqual(decideReconciliation(input({ revokedAt: REVOKED })), {
    action: "cancel",
    reason: "consent_revoked",
  });
});

// ---------------------------------------------------------------------
// Prioridade: integridade > stale > consent_revoked > appointment_cancelled > keep
// (as permanentes vencem a temporária)
// ---------------------------------------------------------------------

test("5: consulta cancelled + stale -> CANCEL stale_schedule_revision (não fica blocked)", () => {
  assert.deepEqual(decideReconciliation(input({ appointmentStatus: "cancelled", ...STALE })), {
    action: "cancel",
    reason: "stale_schedule_revision",
  });
});

test("6: consulta cancelled + consentimento revogado -> CANCEL consent_revoked (não fica blocked)", () => {
  assert.deepEqual(decideReconciliation(input({ appointmentStatus: "cancelled", revokedAt: REVOKED })), {
    action: "cancel",
    reason: "consent_revoked",
  });
});

test("7: consulta cancelled + stale + revogado -> stale_schedule_revision", () => {
  assert.deepEqual(
    decideReconciliation(input({ appointmentStatus: "cancelled", ...STALE, revokedAt: REVOKED })),
    { action: "cancel", reason: "stale_schedule_revision" },
  );
});

test("8: stale + revogado -> stale_schedule_revision (prioridade sobre consent_revoked)", () => {
  assert.deepEqual(decideReconciliation(input({ ...STALE, revokedAt: REVOKED })), {
    action: "cancel",
    reason: "stale_schedule_revision",
  });
});

test("appointment_cancelled só aparece quando NADA permanente se aplica (blocked é o último reason antes de keep)", () => {
  const blocked = decideReconciliation(input({ appointmentStatus: "cancelled" }));
  assert.equal(blocked.action, "blocked");
  const withStale = decideReconciliation(input({ appointmentStatus: "cancelled", ...STALE }));
  const withRevoked = decideReconciliation(input({ appointmentStatus: "cancelled", revokedAt: REVOKED }));
  assert.equal(withStale.action, "cancel");
  assert.equal(withRevoked.action, "cancel");
});

// ---------------------------------------------------------------------
// Integridade: nunca vira um reason normal
// ---------------------------------------------------------------------

test("9: appointment null (scheduled) -> erro explícito de integridade", () => {
  assert.throws(
    () => decideReconciliation(input({ appointment: null })),
    (e: unknown) => e instanceof ReconciliationIntegrityError && e.code === "appointment_missing",
  );
});

test("10: consent null (scheduled) -> erro explícito de integridade, não um reason", () => {
  assert.throws(
    () => decideReconciliation(input({ consent: null })),
    (e: unknown) =>
      e instanceof ReconciliationIntegrityError && e.code === "consent_missing" && e.messageId === "msg-1",
  );
});

test("integridade vale mesmo quando outra condição já bastaria (não mascara input quebrado)", () => {
  assert.throws(() => decideReconciliation(input({ appointment: null, revokedAt: REVOKED })), ReconciliationIntegrityError);
  assert.throws(() => decideReconciliation(input({ consent: null, ...STALE })), ReconciliationIntegrityError);
  assert.throws(
    () => decideReconciliation(input({ consent: null, appointmentStatus: "cancelled" })),
    ReconciliationIntegrityError,
  );
});

test("appointment de outro id que o referenciado pela mensagem -> appointment_mismatch", () => {
  assert.throws(
    () =>
      decideReconciliation(input({ appointment: { id: "appt-OUTRO", status: "cancelled", scheduleRevision: 2 } })),
    (e: unknown) => e instanceof ReconciliationIntegrityError && e.code === "appointment_mismatch",
  );
});

test("consentimento de outro id que o referenciado pela mensagem -> consent_mismatch", () => {
  assert.throws(
    () => decideReconciliation(input({ consent: { id: "consent-OUTRO", revokedAt: REVOKED } })),
    (e: unknown) => e instanceof ReconciliationIntegrityError && e.code === "consent_mismatch",
  );
});

test("a mensagem do erro de integridade carrega só código e id da mensagem (sem PII)", () => {
  try {
    decideReconciliation(input({ consent: null }));
    assert.fail("deveria lançar");
  } catch (e) {
    assert.equal((e as Error).message, "reconciliation integrity error: consent_missing (message msg-1)");
  }
});

// ---------------------------------------------------------------------
// Status != scheduled: keep/not_cancellable_status, sem exigir joins
// ---------------------------------------------------------------------

test("11: processing + consulta cancelled -> keep/not_cancellable_status", () => {
  assert.deepEqual(decideReconciliation(input({ status: "processing", appointmentStatus: "cancelled" })), {
    action: "keep",
    reason: "not_cancellable_status",
  });
});

test("12: failed + stale -> keep/not_cancellable_status", () => {
  assert.deepEqual(decideReconciliation(input({ status: "failed", ...STALE })), {
    action: "keep",
    reason: "not_cancellable_status",
  });
});

test("13: sent + consentimento revogado -> keep/not_cancellable_status", () => {
  assert.deepEqual(decideReconciliation(input({ status: "sent", revokedAt: REVOKED })), {
    action: "keep",
    reason: "not_cancellable_status",
  });
});

test("14: delivered / read / cancelled -> keep/not_cancellable_status (mesmo com tudo inválido)", () => {
  for (const status of ["delivered", "read", "cancelled"] as const) {
    assert.deepEqual(
      decideReconciliation(input({
        status,
        appointmentStatus: "cancelled",
        messageRevision: 0,
        appointmentRevision: 5,
        revokedAt: REVOKED,
      })),
      { action: "keep", reason: "not_cancellable_status" },
      status,
    );
  }
});

test("status != scheduled com appointment/consent null NÃO lança (fora do escopo, não é erro de integridade)", () => {
  for (const status of ["processing", "failed", "sent", "delivered", "read", "cancelled"] as const) {
    assert.deepEqual(
      decideReconciliation(input({ status, appointment: null, consent: null })),
      { action: "keep", reason: "not_cancellable_status" },
      status,
    );
  }
});

// ---------------------------------------------------------------------
// Statuses reais do domínio
// ---------------------------------------------------------------------

test("15: fulfilled é um status normal/ativo -> keep (não bloqueia, não cancela)", () => {
  assert.deepEqual(decideReconciliation(input({ appointmentStatus: "fulfilled" })), { action: "keep", reason: null });
});

test("dos 6 statuses reais, só 'cancelled' bloqueia; os outros 5 são keep", () => {
  for (const status of APPOINTMENT_STATUSES) {
    assert.deepEqual(
      decideReconciliation(input({ appointmentStatus: status })),
      status === "cancelled"
        ? { action: "blocked", reason: "appointment_cancelled" }
        : { action: "keep", reason: null },
      status,
    );
  }
});

test("os 6 statuses reais do domínio, sem 'attended' (que não existe)", () => {
  assert.deepEqual([...APPOINTMENT_STATUSES], ["scheduled", "confirmed", "fulfilled", "cancelled", "noShow", "rescheduled"]);
});

test("com revisão velha, QUALQUER um dos 6 statuses de consulta cancela por stale (o status da consulta é irrelevante para as permanentes)", () => {
  for (const status of APPOINTMENT_STATUSES) {
    assert.deepEqual(
      decideReconciliation(input({ appointmentStatus: status, ...STALE })),
      { action: "cancel", reason: "stale_schedule_revision" },
      status,
    );
  }
});

test("a decisão é determinística e não muta o input", () => {
  const i = input({ appointmentStatus: "cancelled", revokedAt: REVOKED });
  const snapshot = JSON.stringify(i);
  const a = decideReconciliation(i);
  const b = decideReconciliation(i);
  assert.deepEqual(a, b);
  assert.equal(JSON.stringify(i), snapshot);
});
