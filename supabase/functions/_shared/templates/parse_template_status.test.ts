import { test } from "node:test";
import assert from "node:assert/strict";
import { parseTemplateStatusUpdates } from "./parse_template_status.ts";

const WABA = "102290129340398";

function payload(value: unknown, field = "message_template_status_update", entryId: unknown = WABA, time: unknown = 1791460800) {
  return { object: "whatsapp_business_account", entry: [{ id: entryId, time, changes: [{ field, value }] }] };
}

test("APPROVED: WABA do entry.id, nome, idioma, evento e instante; descarta reason e ids", () => {
  const events = parseTemplateStatusUpdates(
    payload({
      event: "APPROVED",
      message_template_id: 806312974732579,
      message_template_name: "appointment_12h",
      message_template_language: "pt_BR",
      reason: "NONE",
      message_template_category: "UTILITY",
    }),
  );
  assert.deepEqual(events, [
    { wabaId: WABA, name: "appointment_12h", language: "pt_BR", event: "APPROVED", occurredAt: "2026-10-08T12:00:00.000Z" },
  ]);
});

test("REJECTED com rejection_info e PAUSED com other_info: texto livre não sai do parser", () => {
  const rejected = parseTemplateStatusUpdates(
    payload({
      event: "REJECTED",
      message_template_name: "appointment_confirmation",
      message_template_language: "pt_BR",
      reason: "INVALID_FORMAT",
      rejection_info: { reason: "texto da Meta", recommendation: "outro texto" },
    }),
  );
  assert.equal(rejected[0].event, "REJECTED");
  const paused = parseTemplateStatusUpdates(
    payload({
      event: "PAUSED",
      message_template_name: "appointment_12h",
      message_template_language: "pt_BR",
      other_info: { title: "FIRST_PAUSE", description: "baixa qualidade" },
    }),
  );
  assert.equal(paused[0].event, "PAUSED");
  assert.ok(!JSON.stringify([rejected, paused]).match(/texto|qualidade|FIRST_PAUSE/));
});

test("sem entry.time o instante fica nulo (o banco usa now())", () => {
  const events = parseTemplateStatusUpdates(
    payload({ event: "DISABLED", message_template_name: "appointment_12h", message_template_language: "pt_BR" }, undefined, WABA, null),
  );
  assert.equal(events[0].occurredAt, null);
});

test("campos inválidos, outros fields e lixo são ignorados sem lançar", () => {
  const base = { event: "APPROVED", message_template_name: "appointment_12h", message_template_language: "pt_BR" };
  assert.deepEqual(parseTemplateStatusUpdates(payload(base, "messages")), []);
  assert.deepEqual(parseTemplateStatusUpdates(payload(base, undefined, "abc")), []);
  assert.deepEqual(parseTemplateStatusUpdates(payload({ ...base, event: "drop table" })), []);
  assert.deepEqual(parseTemplateStatusUpdates(payload({ ...base, message_template_name: "Nome Inválido" })), []);
  assert.deepEqual(parseTemplateStatusUpdates(payload({ ...base, message_template_language: "portuguese" })), []);
  for (const junk of [null, undefined, 1, "x", [], { entry: "x" }, { entry: [null, { changes: 3 }] }]) {
    assert.deepEqual(parseTemplateStatusUpdates(junk), []);
  }
});
