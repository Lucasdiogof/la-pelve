// Portas Supabase de status de entrega e de template com um client FALSO
// (só .rpc). Garantem os parâmetros da RPC e que falhas viram null sem lançar
// e sem logar wamid/telefone.

import { test } from "node:test";
import assert from "node:assert/strict";
import { createSupabaseDeliveryStatusPort } from "./status_port.ts";
import { createSupabaseTemplateStatusPort } from "../templates/template_port.ts";

type Rpc = (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>;
// deno-lint-ignore no-explicit-any
const client = (rpc: Rpc) => ({ rpc }) as any;

const STATUS = {
  phoneNumberId: "106540352242922",
  wamid: "wamid.SEGREDO",
  status: "failed" as const,
  occurredAt: "2026-10-08T00:00:00.000Z",
  errorCode: 131026,
};

async function captureErrors(fn: () => Promise<unknown>): Promise<string> {
  const original = console.error;
  const lines: string[] = [];
  console.error = (...args: unknown[]) => lines.push(args.join(" "));
  try {
    await fn();
  } finally {
    console.error = original;
  }
  return lines.join("\n");
}

test("status: chama apply_whatsapp_message_status com os parâmetros certos", async () => {
  const calls: Array<[string, Record<string, unknown>]> = [];
  const port = createSupabaseDeliveryStatusPort(client(async (fn, args) => {
    calls.push([fn, args]);
    return { data: "updated", error: null };
  }));
  assert.equal(await port.applyStatus(STATUS), "updated");
  assert.deepEqual(calls, [[
    "apply_whatsapp_message_status",
    {
      p_phone_number_id: "106540352242922",
      p_wamid: "wamid.SEGREDO",
      p_status: "failed",
      p_occurred_at: "2026-10-08T00:00:00.000Z",
      p_error_code: 131026,
    },
  ]]);
});

test("status: erro, resposta inesperada ou exceção => null, log sem wamid", async () => {
  for (const rpc of [
    async () => ({ data: null, error: { message: "boom" } }),
    async () => ({ data: "hacked", error: null }),
    async () => {
      throw new Error("rede");
    },
  ] as Rpc[]) {
    const port = createSupabaseDeliveryStatusPort(client(rpc));
    let result: unknown;
    const logs = await captureErrors(async () => {
      result = await port.applyStatus(STATUS);
    });
    assert.equal(result, null);
    assert.ok(logs.includes("whatsapp_status_apply_failed"));
    assert.ok(!logs.includes("SEGREDO") && !logs.includes("106540352242922"));
  }
});

test("template: chama apply_whatsapp_template_status; falha => null", async () => {
  const calls: Array<[string, Record<string, unknown>]> = [];
  const ok = createSupabaseTemplateStatusPort(client(async (fn, args) => {
    calls.push([fn, args]);
    return { data: 1, error: null };
  }));
  const event = { wabaId: "102290129340398", name: "appointment_12h", language: "pt_BR", event: "PAUSED", occurredAt: null };
  assert.equal(await ok.applyTemplateStatus(event), 1);
  assert.deepEqual(calls[0], [
    "apply_whatsapp_template_status",
    { p_waba_id: "102290129340398", p_template_name: "appointment_12h", p_language: "pt_BR", p_event: "PAUSED", p_occurred_at: null },
  ]);
  const broken = createSupabaseTemplateStatusPort(client(async () => ({ data: null, error: { message: "x" } })));
  let result: unknown;
  await captureErrors(async () => {
    result = await broken.applyTemplateStatus(event);
  });
  assert.equal(result, null);
});
