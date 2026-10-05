// Testes do ADAPTER REAL (createSupabaseReconciliationPort), com um client
// Supabase FALSO com estado (fake_messages_db.testutil.ts). Nunca toca
// rede nem produção; o adapter só importa SupabaseClient como `import type`
// (apagado pelo strip de tipos), então nenhum código do supabase-js real
// roda aqui.

import { mock, test } from "node:test";
import assert from "node:assert/strict";
import { createSupabaseReconciliationPort } from "./supabase_reconciliation_port.ts";
import { FAKE_PHONE, fakeMessagesDb, makeRow, RAW_DB_ERROR } from "./fake_messages_db.testutil.ts";

/** Roda `fn` capturando tudo que o adapter escreveria em console.error. */
async function withCapturedErrors<T>(fn: () => Promise<T>): Promise<{ result: T; logs: string[] }> {
  const spy = mock.method(console, "error", () => {});
  try {
    const result = await fn();
    return { result, logs: spy.mock.calls.map((c) => c.arguments.map(String).join(" ")) };
  } finally {
    spy.mock.restore();
  }
}

// ---------------------------------------------------------------------
// 15-19: classificação do resultado
// ---------------------------------------------------------------------

test("15: scheduled -> UPDATE condicional afeta 1 linha -> cancelled", async () => {
  const db = fakeMessagesDb([makeRow("m1")]);
  const port = createSupabaseReconciliationPort(db.client);
  assert.deepEqual(await port.cancelIfScheduled("m1"), { kind: "cancelled" });
  assert.equal(db.byId("m1")?.status, "cancelled");
  assert.equal(db.calls.update, 1);
  assert.equal(db.calls.select, 0, "no caminho feliz não há SELECT de classificação");
});

test("o UPDATE é SEMPRE condicional: filtra por id E por status='scheduled' (nunca só por id)", async () => {
  const db = fakeMessagesDb([makeRow("m1")]);
  await createSupabaseReconciliationPort(db.client).cancelIfScheduled("m1");
  assert.deepEqual(db.tables, ["whatsapp_messages"]);
  assert.equal(db.updates.length, 1);
  assert.deepEqual(db.updates[0].filters, [["id", "m1"], ["status", "scheduled"]]);
  assert.equal(db.updates[0].cols, "id", "RETURNING só do id");
});

test("16: corrida -- mudou para processing ANTES do UPDATE -> 0 linhas -> already_not_scheduled; processing intacta", async () => {
  const db = fakeMessagesDb([makeRow("m1")], {
    beforeUpdate: (_call, rows) => {
      rows[0].status = "processing"; // o dispatch venceu entre a leitura e o UPDATE
    },
  });
  const port = createSupabaseReconciliationPort(db.client);
  assert.deepEqual(await port.cancelIfScheduled("m1"), { kind: "already_not_scheduled" });
  assert.equal(db.byId("m1")?.status, "processing", "NUNCA cancela processing");
  assert.deepEqual(db.changedFields, [], "nenhum campo alterado");
});

test("17: mudou para sent antes do UPDATE -> already_not_scheduled", async () => {
  const db = fakeMessagesDb([makeRow("m1")], {
    beforeUpdate: (_c, rows) => {
      rows[0].status = "sent";
    },
  });
  assert.deepEqual(await createSupabaseReconciliationPort(db.client).cancelIfScheduled("m1"), {
    kind: "already_not_scheduled",
  });
  assert.equal(db.byId("m1")?.status, "sent");
});

test("18: mensagem já cancelled -> already_not_scheduled (não 'cancela de novo')", async () => {
  const db = fakeMessagesDb([makeRow("m1", "cancelled")]);
  assert.deepEqual(await createSupabaseReconciliationPort(db.client).cancelIfScheduled("m1"), {
    kind: "already_not_scheduled",
  });
  assert.equal(db.byId("m1")?.status, "cancelled");
});

test("já fora de scheduled (processing, failed, sent, delivered, read) -> already_not_scheduled e linha intacta", async () => {
  for (const status of ["processing", "failed", "sent", "delivered", "read"]) {
    const db = fakeMessagesDb([makeRow("m1", status)]);
    assert.deepEqual(
      await createSupabaseReconciliationPort(db.client).cancelIfScheduled("m1"),
      { kind: "already_not_scheduled" },
      status,
    );
    assert.equal(db.byId("m1")?.status, status);
  }
});

test("19: mensagem inexistente -> not_found", async () => {
  const db = fakeMessagesDb([makeRow("m1")]);
  assert.deepEqual(await createSupabaseReconciliationPort(db.client).cancelIfScheduled("nao-existe"), {
    kind: "not_found",
  });
  assert.equal(db.byId("m1")?.status, "scheduled", "outras linhas não são tocadas");
});

test("a classificação de 0 linhas consulta SÓ o id (nunca status nem outro campo)", async () => {
  const db = fakeMessagesDb([makeRow("m1", "sent")]);
  await createSupabaseReconciliationPort(db.client).cancelIfScheduled("m1");
  assert.equal(db.selects.length, 1);
  assert.equal(db.selects[0].cols, "id");
  assert.deepEqual(db.selects[0].filters, [["id", "m1"]]);
});

// ---------------------------------------------------------------------
// 20-21: erros e exceções
// ---------------------------------------------------------------------

test("20: erro do banco no UPDATE -> error (persistence_error)", async () => {
  const db = fakeMessagesDb([makeRow("m1")], { updateFailOnCall: { call: 1, mode: "error" } });
  const { result } = await withCapturedErrors(() =>
    createSupabaseReconciliationPort(db.client).cancelIfScheduled("m1")
  );
  assert.deepEqual(result, { kind: "error", code: "persistence_error" });
  assert.equal(db.byId("m1")?.status, "scheduled");
});

test("21: exceção/rede no UPDATE -> error, nunca throw", async () => {
  const db = fakeMessagesDb([makeRow("m1")], { updateFailOnCall: { call: 1, mode: "throw" } });
  const { result } = await withCapturedErrors(() =>
    createSupabaseReconciliationPort(db.client).cancelIfScheduled("m1")
  );
  assert.deepEqual(result, { kind: "error", code: "persistence_error" });
});

test("erro ou exceção no SELECT de classificação (0 linhas) -> error (nunca chuta not_found nem already_not_scheduled)", async () => {
  for (const mode of ["error", "throw"] as const) {
    const db = fakeMessagesDb([makeRow("m1", "sent")], { selectFailOnCall: { call: 1, mode } });
    const { result } = await withCapturedErrors(() =>
      createSupabaseReconciliationPort(db.client).cancelIfScheduled("m1")
    );
    assert.deepEqual(result, { kind: "error", code: "persistence_error" }, mode);
  }
});

test("respostas inesperadas do UPDATE (null, não-array, mais de 1 linha) -> error, nunca cancelled", async () => {
  for (
    const updateResult of [
      { data: null, error: null },
      { data: "oops", error: null },
      { data: [{ id: "a" }, { id: "b" }], error: null },
    ]
  ) {
    const db = fakeMessagesDb([makeRow("m1")], { updateResult });
    const { result } = await withCapturedErrors(() =>
      createSupabaseReconciliationPort(db.client).cancelIfScheduled("m1")
    );
    assert.deepEqual(result, { kind: "error", code: "persistence_error" }, JSON.stringify(updateResult));
  }
});

test("resposta inesperada do SELECT de classificação (null / não-array) -> error", async () => {
  for (const selectResult of [{ data: null, error: null }, { data: {}, error: null }]) {
    const db = fakeMessagesDb([makeRow("m1", "sent")], { selectResult });
    const { result } = await withCapturedErrors(() =>
      createSupabaseReconciliationPort(db.client).cancelIfScheduled("m1")
    );
    assert.deepEqual(result, { kind: "error", code: "persistence_error" });
  }
});

// ---------------------------------------------------------------------
// 22: só status muda
// ---------------------------------------------------------------------

test("22: o UPDATE altera SOMENTE status (payload exato e nenhum outro campo da linha muda)", async () => {
  const original = makeRow("m1", "scheduled", { wamid: null, error: null, sent_at: null, failed_at: null });
  const db = fakeMessagesDb([original]);
  await createSupabaseReconciliationPort(db.client).cancelIfScheduled("m1");

  assert.deepEqual(db.updates[0].patch, { status: "cancelled" });
  assert.deepEqual(db.changedFields, [["status"]]);
  assert.deepEqual(db.byId("m1"), { ...original, status: "cancelled" }, "o resto da linha é idêntico");
});

// ---------------------------------------------------------------------
// 23: privacidade -- erro bruto/PII nunca aparece em outcome nem em log
// ---------------------------------------------------------------------

test("23: erro bruto do banco (com telefone e dados da linha) nunca vaza em outcome nem em log", async () => {
  const cenarios = [
    fakeMessagesDb([makeRow("m1")], { updateFailOnCall: { call: 1, mode: "error" } }),
    fakeMessagesDb([makeRow("m1")], { updateFailOnCall: { call: 1, mode: "throw" } }),
    fakeMessagesDb([makeRow("m1", "sent")], { selectFailOnCall: { call: 1, mode: "error" } }),
  ];
  for (const db of cenarios) {
    const { result, logs } = await withCapturedErrors(() =>
      createSupabaseReconciliationPort(db.client).cancelIfScheduled("m1")
    );
    const everything = JSON.stringify(result) + logs.join("\n");
    for (const secret of [FAKE_PHONE, RAW_DB_ERROR.message, RAW_DB_ERROR.details, "consent-m1", "57014", "patient-1"]) {
      assert.ok(!everything.includes(secret), `vazou: ${secret}`);
    }
    assert.ok(logs.length >= 1, "falha é logada (sanitizada)");
    assert.ok(logs.every((l) => l.includes('"messageId":"m1"')), "log técnico traz o messageId");
  }
});

test("caminho feliz e classificações normais não logam nada", async () => {
  const db = fakeMessagesDb([makeRow("m1"), makeRow("m2", "sent")]);
  const port = createSupabaseReconciliationPort(db.client);
  const { logs } = await withCapturedErrors(async () => {
    await port.cancelIfScheduled("m1");
    await port.cancelIfScheduled("m2");
    await port.cancelIfScheduled("nao-existe");
  });
  assert.deepEqual(logs, []);
});
