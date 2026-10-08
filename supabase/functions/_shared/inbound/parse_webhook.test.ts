// Extração defensiva do payload da Meta. Pura, sem I/O.

import { test } from "node:test";
import assert from "node:assert/strict";
import { parseWebhookPayload } from "./parse_webhook.ts";

const TS = "1791460800"; // 2026-10-08T12:00:00Z

function webhook(value: Record<string, unknown>, field = "messages") {
  return {
    object: "whatsapp_business_account",
    entry: [{ id: "waba-1", changes: [{ field, value: { messaging_product: "whatsapp", ...value } }] }],
  };
}

const metadata = { display_phone_number: "556230000000", phone_number_id: "pn-1" };

test("mensagem de texto: extrai id, número, remetente, horário e texto", () => {
  const parsed = parseWebhookPayload(
    webhook({
      metadata,
      messages: [{ id: "wamid.in.1", from: "5562911110001", timestamp: TS, type: "text", text: { body: "Sim" } }],
    }),
  );
  assert.deepEqual(parsed.messages, [
    {
      wamid: "wamid.in.1",
      phoneNumberId: "pn-1",
      fromWaId: "5562911110001",
      receivedAt: "2026-10-08T12:00:00.000Z",
      type: "text",
      text: "Sim",
      buttonPayload: null,
      contextWamid: null,
    },
  ]);
  assert.equal(parsed.ignoredMessages, 0);
});

test("botão de resposta rápida: payload, texto e context.id", () => {
  const parsed = parseWebhookPayload(
    webhook({
      metadata,
      messages: [
        {
          id: "wamid.in.2",
          from: "5562911110001",
          timestamp: TS,
          type: "button",
          context: { from: "556230000000", id: "wamid.out.1" },
          button: { text: "Sim, confirmo", payload: "LA_PELVE_CONFIRM_APPOINTMENT" },
        },
      ],
    }),
  );
  assert.equal(parsed.messages[0].type, "button");
  assert.equal(parsed.messages[0].buttonPayload, "LA_PELVE_CONFIRM_APPOINTMENT");
  assert.equal(parsed.messages[0].text, "Sim, confirmo");
  assert.equal(parsed.messages[0].contextWamid, "wamid.out.1");
});

test("interactive button_reply: id vira payload, title vira texto", () => {
  const parsed = parseWebhookPayload(
    webhook({
      metadata,
      messages: [
        {
          id: "wamid.in.3",
          from: "5562911110001",
          timestamp: TS,
          type: "interactive",
          interactive: { type: "button_reply", button_reply: { id: "LA_PELVE_CONFIRM_APPOINTMENT", title: "Confirmar" } },
        },
      ],
    }),
  );
  assert.equal(parsed.messages[0].type, "interactive");
  assert.equal(parsed.messages[0].buttonPayload, "LA_PELVE_CONFIRM_APPOINTMENT");
});

test("D: statuses de entrega/leitura são ignorados (não viram mensagem)", () => {
  const parsed = parseWebhookPayload(
    webhook({
      metadata,
      statuses: [
        { id: "wamid.out.1", status: "delivered", timestamp: TS, recipient_id: "5562911110001" },
        { id: "wamid.out.1", status: "read", timestamp: TS, recipient_id: "5562911110001" },
      ],
    }),
  );
  assert.equal(parsed.messages.length, 0);
  assert.equal(parsed.ignoredStatuses, 2);
});

test("D: payload incompleto ou estranho não lança e não vira mensagem", () => {
  for (const body of [
    null,
    undefined,
    "texto",
    42,
    [],
    {},
    { entry: null },
    { entry: [null, 1, "x"] },
    { entry: [{ changes: [null, { value: null }, { value: "x" }] }] },
    webhook({ messages: "não é array" }),
    webhook({ metadata: {}, messages: [{ id: "a", from: "5562911110001", timestamp: TS, type: "text", text: { body: "sim" } }] }),
  ]) {
    const parsed = parseWebhookPayload(body);
    assert.equal(parsed.messages.length, 0, JSON.stringify(body));
  }
});

test("D: mensagem sem campo essencial é contada como ignorada; as outras seguem", () => {
  const good = { id: "wamid.ok", from: "5562911110001", timestamp: TS, type: "text", text: { body: "sim" } };
  const parsed = parseWebhookPayload(
    webhook({
      metadata,
      messages: [
        { ...good, id: undefined },
        { ...good, id: "" },
        { ...good, from: "+5562911110001" },
        { ...good, from: "abc" },
        { ...good, timestamp: "ontem" },
        { ...good, timestamp: undefined },
        { ...good, text: undefined },
        { ...good, text: { body: 123 } },
        { ...good, type: "image", image: { id: "media" } },
        { ...good, type: "audio" },
        { ...good, type: "reaction", reaction: { emoji: "👍" } },
        { ...good, type: "interactive", interactive: { type: "list_reply", list_reply: { id: "x" } } },
        null,
        good,
      ],
    }),
  );
  assert.equal(parsed.messages.length, 1);
  assert.equal(parsed.messages[0].wamid, "wamid.ok");
  assert.equal(parsed.ignoredMessages, 13);
});

test("change de outro field (não 'messages') é ignorado", () => {
  const parsed = parseWebhookPayload(
    webhook(
      { metadata, messages: [{ id: "w", from: "5562911110001", timestamp: TS, type: "text", text: { body: "sim" } }] },
      "account_update",
    ),
  );
  assert.equal(parsed.messages.length, 0);
});

test("texto absurdamente longo é ignorado (não é uma resposta de confirmação)", () => {
  const parsed = parseWebhookPayload(
    webhook({
      metadata,
      messages: [{ id: "w", from: "5562911110001", timestamp: TS, type: "text", text: { body: "a".repeat(5000) } }],
    }),
  );
  assert.equal(parsed.messages.length, 0);
  assert.equal(parsed.ignoredMessages, 1);
});
