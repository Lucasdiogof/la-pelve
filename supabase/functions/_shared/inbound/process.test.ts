import { test } from "node:test";
import assert from "node:assert/strict";
import { processInboundWebhook } from "./process.ts";
import type { ConfirmationReplyInput, ConfirmationReplyPort } from "./types.ts";

const TS = "1791460800";

function payload(messages: unknown[], statuses: unknown[] = []) {
  return {
    entry: [{ changes: [{ field: "messages", value: { metadata: { phone_number_id: "pn-1" }, messages, statuses } }] }],
  };
}

function text(id: string, body: string, from = "5562911110001") {
  return { id, from, timestamp: TS, type: "text", text: { body } };
}

function recordingPort(results: Record<string, "confirmed" | "ambiguous"> = {}) {
  const calls: ConfirmationReplyInput[] = [];
  const port: ConfirmationReplyPort = {
    async processConfirmationReply(input) {
      calls.push(input);
      return { kind: "processed", result: results[input.wamid] ?? "confirmed" };
    },
  };
  return { port, calls };
}

test("só confirmações inequívocas chegam à porta; o resto vira contagem", async () => {
  const { port, calls } = recordingPort({ w3: "ambiguous" });
  const summary = await processInboundWebhook(
    payload(
      [text("w1", "Sim, confirmo!"), text("w2", "não confirmo"), text("w3", "confirmo"), { id: "bad" }],
      [{ id: "out", status: "read" }],
    ),
    port,
  );
  assert.deepEqual(
    calls.map((c) => c.wamid),
    ["w1", "w3"],
  );
  assert.deepEqual(summary, {
    messages: 3,
    ignoredStatuses: 1,
    ignoredMessages: 1,
    notConfirmation: 1,
    results: { confirmed: 1, ambiguous: 1 },
    errors: 0,
  });
});

test("remetente BR sem o 9 vai com as duas formas", async () => {
  const { port, calls } = recordingPort();
  await processInboundWebhook(payload([text("w1", "sim", "556291110001")]), port);
  assert.deepEqual(calls[0].fromE164Candidates, ["+556291110001", "+5562991110001"]);
});

test("erro da porta é contado, sem interromper as demais mensagens", async () => {
  let n = 0;
  const port: ConfirmationReplyPort = {
    async processConfirmationReply() {
      n++;
      return n === 1 ? { kind: "error", code: "persistence_error" } : { kind: "processed", result: "confirmed" };
    },
  };
  const summary = await processInboundWebhook(payload([text("w1", "sim"), text("w2", "sim")]), port);
  assert.equal(summary.errors, 1);
  assert.deepEqual(summary.results, { confirmed: 1 });
});
