import { test } from "node:test";
import assert from "node:assert/strict";
import { parseStatuses } from "./parse_statuses.ts";

const PNID = "106540352242922";

function payload(statuses: unknown[], phoneNumberId: unknown = PNID, field: unknown = "messages") {
  return {
    object: "whatsapp_business_account",
    entry: [
      {
        id: "102290129340398",
        changes: [
          {
            field,
            value: {
              messaging_product: "whatsapp",
              metadata: { display_phone_number: "15550783881", phone_number_id: phoneNumberId },
              statuses,
            },
          },
        ],
      },
    ],
  };
}

test("extrai sent/delivered/read com instante e número; descarta telefone, conversa e preço", () => {
  const parsed = parseStatuses(
    payload([
      {
        id: "wamid.A",
        status: "sent",
        timestamp: "1791460800",
        recipient_id: "5562911110001",
        conversation: { id: "c1", origin: { type: "utility" } },
        pricing: { billable: true, category: "utility" },
      },
      { id: "wamid.A", status: "delivered", timestamp: 1791460810, recipient_id: "5562911110001" },
      { id: "wamid.A", status: "read", timestamp: "1791460820", recipient_id: "5562911110001" },
    ]),
  );
  assert.equal(parsed.ignored, 0);
  assert.deepEqual(parsed.statuses, [
    { phoneNumberId: PNID, wamid: "wamid.A", status: "sent", occurredAt: "2026-10-08T12:00:00.000Z", errorCode: null },
    { phoneNumberId: PNID, wamid: "wamid.A", status: "delivered", occurredAt: "2026-10-08T12:00:10.000Z", errorCode: null },
    { phoneNumberId: PNID, wamid: "wamid.A", status: "read", occurredAt: "2026-10-08T12:00:20.000Z", errorCode: null },
  ]);
  assert.ok(!JSON.stringify(parsed).includes("5562911110001"), "telefone da paciente nunca sai do parser");
});

test("failed leva só o código numérico do erro, nunca título/mensagem", () => {
  const parsed = parseStatuses(
    payload([
      {
        id: "wamid.B",
        status: "failed",
        timestamp: "1791460800",
        recipient_id: "5562911110001",
        errors: [{ code: 131026, title: "Message undeliverable", message: "x", error_data: { details: "y" } }],
      },
    ]),
  );
  assert.deepEqual(parsed.statuses, [
    { phoneNumberId: PNID, wamid: "wamid.B", status: "failed", occurredAt: "2026-10-08T12:00:00.000Z", errorCode: 131026 },
  ]);
  assert.ok(!JSON.stringify(parsed).includes("undeliverable"));
});

test("played, status desconhecido, wamid/timestamp/número inválidos são ignorados e contados", () => {
  const parsed = parseStatuses(
    payload([
      { id: "wamid.C", status: "played", timestamp: "1791460800" },
      { id: "wamid.C", status: "deleted", timestamp: "1791460800" },
      { id: "", status: "sent", timestamp: "1791460800" },
      { id: "wamid.C", status: "sent", timestamp: "ontem" },
      { id: "x".repeat(300), status: "sent", timestamp: "1791460800" },
      null,
    ]),
  );
  assert.equal(parsed.statuses.length, 0);
  assert.equal(parsed.ignored, 6);
  const badPhone = parseStatuses(payload([{ id: "wamid.D", status: "sent", timestamp: "1791460800" }], "pn-x"));
  assert.deepEqual(badPhone, { statuses: [], ignored: 1 });
});

test("outros campos (account_update, templates) e lixo não geram status, sem lançar", () => {
  assert.deepEqual(
    parseStatuses(payload([{ id: "wamid.E", status: "sent", timestamp: "1" }], PNID, "account_update")),
    { statuses: [], ignored: 0 },
  );
  for (const junk of [null, undefined, 1, "x", [], { entry: "x" }, { entry: [null, { changes: 3 }] }]) {
    assert.deepEqual(parseStatuses(junk), { statuses: [], ignored: 0 });
  }
});
