// Adapter real da RPC com um client FALSO (nunca supabase-js, nunca rede).

import { test } from "node:test";
import assert from "node:assert/strict";
import { CONFIRMATION_REPLY_RPC, createSupabaseConfirmationReplyPort } from "./supabase_confirmation_port.ts";
import type { ConfirmationReplyInput } from "./types.ts";

const input: ConfirmationReplyInput = {
  wamid: "wamid.in.1",
  phoneNumberId: "pn-1",
  fromE164Candidates: ["+5562911110001"],
  receivedAt: "2026-10-08T12:00:00.000Z",
  messageType: "text",
  contextWamid: null,
};

function fakeClient(rpc: (name: string, args: unknown) => Promise<{ data: unknown; error: unknown }>) {
  // deno-lint-ignore no-explicit-any
  return { rpc } as any;
}

test("chama a RPC com os parâmetros nomeados da migration 0025", async () => {
  const calls: Array<{ name: string; args: unknown }> = [];
  const port = createSupabaseConfirmationReplyPort(
    fakeClient(async (name, args) => {
      calls.push({ name, args });
      return { data: { outcome: "confirmed", appointment_id: "appt-1" }, error: null };
    }),
  );
  const outcome = await port.processConfirmationReply({ ...input, contextWamid: "wamid.out.1" });
  assert.deepEqual(outcome, { kind: "processed", result: "confirmed" });
  assert.deepEqual(calls, [
    {
      name: CONFIRMATION_REPLY_RPC,
      args: {
        p_wamid: "wamid.in.1",
        p_phone_number_id: "pn-1",
        p_from_e164_candidates: ["+5562911110001"],
        p_received_at: "2026-10-08T12:00:00.000Z",
        p_message_type: "text",
        p_context_wamid: "wamid.out.1",
      },
    },
  ]);
});

test("todos os resultados conhecidos passam adiante", async () => {
  for (const result of [
    "confirmed",
    "already_confirmed",
    "duplicate",
    "no_pending_request",
    "ambiguous",
    "request_expired",
    "request_stale",
    "consent_revoked",
    "appointment_status_incompatible",
  ]) {
    const port = createSupabaseConfirmationReplyPort(
      fakeClient(async () => ({ data: { outcome: result }, error: null })),
    );
    assert.deepEqual(await port.processConfirmationReply(input), { kind: "processed", result });
  }
});

test("erro da RPC, resposta inesperada ou exceção -> persistence_error (nunca lança)", async () => {
  const errorCases = [
    async () => ({ data: null, error: { message: "boom", details: "+5562911110001" } }),
    async () => ({ data: { outcome: "inventado" }, error: null }),
    async () => ({ data: null, error: null }),
    async () => {
      throw new Error("rede");
    },
  ];
  const originalError = console.error;
  const logged: string[] = [];
  console.error = (line: string) => logged.push(line);
  try {
    for (const rpc of errorCases) {
      const port = createSupabaseConfirmationReplyPort(fakeClient(rpc));
      assert.deepEqual(await port.processConfirmationReply(input), { kind: "error", code: "persistence_error" });
    }
  } finally {
    console.error = originalError;
  }
  assert.equal(logged.length, errorCases.length);
  for (const line of logged) {
    assert.ok(!line.includes("5562911110001"), "log não pode conter telefone");
    assert.ok(!line.includes("boom"), "log não pode conter erro bruto");
  }
});
