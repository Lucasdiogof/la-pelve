// Testes do ADAPTER REAL (createSupabaseMaterializationPort), com um
// client Supabase FALSO (não é o jsr:@supabase/supabase-js real, nunca
// toca rede/produção) que imita só a forma dos métodos encadeados que o
// adapter usa: from().select().eq().eq().eq().limit() e
// from().upsert().select(). Isto é possível em Node porque o adapter só
// importa `SupabaseClient` como `import type` (apagado inteiramente pelo
// strip de tipos do Node) -- nenhum código do supabase-js real é
// carregado ou executado.
//
// O fake tem ESTADO (linhas + consentimentos) e reproduz a ordem real do
// Postgres num INSERT ... ON CONFLICT DO NOTHING: primeiro o trigger
// BEFORE INSERT (valida o consentimento, pode levantar WA001), só depois
// a checagem de conflito na UNIQUE. É essa ordem que torna o pre-check
// necessário (ver teste "documentação" abaixo).
//
// NÃO toca produção. NÃO usa o cliente Supabase real.

import { test } from "node:test";
import assert from "node:assert/strict";
import { createSupabaseMaterializationPort } from "./supabase_materialization_port.ts";
import { materializeAll } from "./materialize.ts";
import type { MaterializableMessage } from "./types.ts";

const PHONE = "+5562911111111";

function msg(overrides: Partial<MaterializableMessage> = {}): MaterializableMessage {
  return {
    fisioterapeutaId: "fisio-1",
    patientId: "patient-1",
    appointmentId: "appt-1",
    reminderType: "appointment_confirmation",
    scheduleRevision: 0,
    scheduledFor: "2026-10-10T17:00:00.000Z",
    destinationPhoneE164: PHONE,
    consentId: "consent-1",
    ...overrides,
  };
}

interface FakeResult {
  data: unknown;
  error: { code?: string; message?: string; details?: string } | null;
}

interface Row {
  id: string;
  appointment_id: string;
  reminder_type: string;
  schedule_revision: number;
  destination_phone_e164: string;
  consent_id: string;
  status?: string;
}

interface Consent {
  contactValue: string;
  revoked: boolean;
}

/**
 * Banco falso com estado. Respostas podem ser forçadas (selectResult/
 * upsertResult) para simular formas inesperadas; sem isso, o fake segue
 * a semântica do Postgres real.
 */
function fakeDb(opts: {
  consents?: Record<string, Consent>;
  selectResult?: FakeResult;
  upsertResult?: FakeResult;
  throwOnSelect?: boolean;
  /** Falha só no N-ésimo SELECT (1 = pre-check, 2 = SELECT após WA001). */
  selectFailOnCall?: { call: number; mode: "throw" | "error" };
  throwOnUpsert?: boolean;
  /** Executa entre o pre-check e o INSERT -- simula outro scheduler. */
  beforeUpsert?: () => void;
} = {}) {
  const rows: Row[] = [];
  const consents = new Map(Object.entries(opts.consents ?? { "consent-1": { contactValue: PHONE, revoked: false } }));
  const calls = { select: 0, upsert: 0, update: 0 };
  const eqCalls: Array<[string, unknown]> = [];
  const selectColsCalls: string[] = [];
  let nextId = 1;

  function insertWithTrigger(row: Omit<Row, "id">): FakeResult {
    // 1) BEFORE INSERT trigger -- roda ANTES de saber se há conflito.
    const consent = consents.get(row.consent_id);
    if (!consent || consent.revoked || consent.contactValue !== row.destination_phone_e164) {
      return {
        data: null,
        error: {
          code: "WA001",
          message: "whatsapp_messages: consentimento ativo incompativel com a mensagem",
        },
      };
    }
    // 2) ON CONFLICT (tripla) DO NOTHING.
    const conflict = rows.some((r) =>
      r.appointment_id === row.appointment_id &&
      r.reminder_type === row.reminder_type &&
      r.schedule_revision === row.schedule_revision
    );
    if (conflict) return { data: [], error: null };
    const id = `row-${nextId++}`;
    rows.push({ id, ...row });
    return { data: [{ id }], error: null };
  }

  // deno-lint-ignore no-explicit-any
  const client: any = {
    from(_table: string) {
      return {
        select(cols: string) {
          selectColsCalls.push(cols);
          const filters: Array<[string, unknown]> = [];
          const chain = {
            eq(col: string, val: unknown) {
              eqCalls.push([col, val]);
              filters.push([col, val]);
              return chain;
            },
            limit(n: number) {
              calls.select++;
              if (opts.throwOnSelect) throw new Error("network down (simulado)");
              if (opts.selectFailOnCall?.call === calls.select) {
                if (opts.selectFailOnCall.mode === "throw") throw new Error("fetch failed (simulado)");
                return Promise.resolve({
                  data: null,
                  error: { code: "57014", message: `timeout lendo ${PHONE}`, details: "Failing row contains (consent-1)" },
                });
              }
              if (opts.selectResult) return Promise.resolve(opts.selectResult);
              const found = rows
                .filter((r) => filters.every(([c, v]) => (r as unknown as Record<string, unknown>)[c] === v))
                .slice(0, n)
                .map((r) => ({ id: r.id }));
              return Promise.resolve({ data: found, error: null });
            },
          };
          return chain;
        },
        update(_patch: unknown) {
          // O adapter nunca deveria chegar aqui -- só contamos.
          calls.update++;
          throw new Error("UPDATE nao permitido na materializacao");
        },
        upsert(row: Omit<Row, "id">, _upsertOpts: unknown) {
          return {
            select(_cols: string) {
              calls.upsert++;
              if (opts.throwOnUpsert) throw new Error("network down (simulado)");
              opts.beforeUpsert?.();
              if (opts.upsertResult) return Promise.resolve(opts.upsertResult);
              return Promise.resolve(insertWithTrigger(row));
            },
          };
        },
      };
    },
  };

  return { client, rows, consents, calls, eqCalls, selectColsCalls, insertWithTrigger };
}

function rowOf(m: MaterializableMessage): Omit<Row, "id"> {
  return {
    appointment_id: m.appointmentId,
    reminder_type: m.reminderType,
    schedule_revision: m.scheduleRevision,
    destination_phone_e164: m.destinationPhoneE164,
    consent_id: m.consentId,
  };
}

/** Captura console.error durante fn -- para provar que nenhum log vaza PII. */
async function captureErrors(fn: () => Promise<unknown>): Promise<string> {
  const original = console.error;
  const lines: string[] = [];
  console.error = (...args: unknown[]) => lines.push(args.map(String).join(" "));
  try {
    await fn();
  } finally {
    console.error = original;
  }
  return lines.join("\n");
}

// ---------------------------------------------------------------------
// Documentação do motivo do pre-check: no fake (como no Postgres), um
// INSERT DIRETO da mesma tripla, com o consentimento já revogado, é
// barrado pelo trigger ANTES do ON CONFLICT -- daria WA001, não "já
// existe". O adapter nunca chega aqui porque o pre-check encontra a linha.
// ---------------------------------------------------------------------

test("documentação: INSERT direto (sem pre-check) de linha existente com consentimento revogado daria WA001", () => {
  const db = fakeDb();
  assert.deepEqual(db.insertWithTrigger(rowOf(msg())).error, null);
  db.consents.get("consent-1")!.revoked = true;
  assert.equal(db.insertWithTrigger(rowOf(msg())).error?.code, "WA001");
  assert.equal(db.rows.length, 1);
});

// ---------------------------------------------------------------------
// 26/27/36. Linha já existe -> already_exists, SEM tentar INSERT.
// ---------------------------------------------------------------------

test("26: linha já existe + consentimento continua ativo -> already_exists, sem INSERT", async () => {
  const db = fakeDb();
  const port = createSupabaseMaterializationPort(db.client);
  assert.deepEqual(await port.insertIfAbsent(msg()), { kind: "inserted" });
  const upsertsAntes = db.calls.upsert;

  assert.deepEqual(await port.insertIfAbsent(msg()), { kind: "already_exists" });
  assert.equal(db.calls.upsert, upsertsAntes, "nao deveria tentar INSERT quando o pre-check ja encontrou a linha");
  assert.equal(db.rows.length, 1);
});

test("27 (CASO A): linha já existe + consentimento revogado depois -> already_exists, sem INSERT", async () => {
  const db = fakeDb();
  const port = createSupabaseMaterializationPort(db.client);
  assert.deepEqual(await port.insertIfAbsent(msg()), { kind: "inserted" });
  const linhaOriginal = { ...db.rows[0] };

  db.consents.get("consent-1")!.revoked = true;
  const upsertsAntes = db.calls.upsert;

  assert.deepEqual(await port.insertIfAbsent(msg()), { kind: "already_exists" });
  assert.equal(db.calls.upsert, upsertsAntes, "nao deveria tentar INSERT (o trigger daria WA001)");
  assert.deepEqual(db.rows, [linhaOriginal], "linha historica intacta");
});

test("36: pre-check existente não executa INSERT, mesmo com valores divergentes na candidata", async () => {
  const db = fakeDb({
    consents: {
      "consent-1": { contactValue: PHONE, revoked: false },
      "consent-novo": { contactValue: "+5562988888888", revoked: false },
    },
  });
  const port = createSupabaseMaterializationPort(db.client);
  await port.insertIfAbsent(msg());
  const linhaOriginal = { ...db.rows[0] };

  const divergente = msg({ destinationPhoneE164: "+5562988888888", consentId: "consent-novo", scheduledFor: "2026-10-11T17:00:00.000Z" });
  assert.deepEqual(await port.insertIfAbsent(divergente), { kind: "already_exists" });
  assert.equal(db.calls.upsert, 1, "so o INSERT original");
  assert.deepEqual(db.rows, [linhaOriginal], "nada comparado, nada corrigido");
});

// ---------------------------------------------------------------------
// 28/29. Linha ausente.
// ---------------------------------------------------------------------

test("28 (CASO D): linha ausente + consentimento revogado -> consent_no_longer_valid", async () => {
  const db = fakeDb({ consents: { "consent-1": { contactValue: PHONE, revoked: true } } });
  const port = createSupabaseMaterializationPort(db.client);
  assert.deepEqual(await port.insertIfAbsent(msg()), { kind: "consent_no_longer_valid" });
  assert.equal(db.calls.upsert, 1);
  assert.equal(db.rows.length, 0);
});

test("29 (CASO B): linha ausente + consentimento ativo -> inserted", async () => {
  const db = fakeDb();
  const port = createSupabaseMaterializationPort(db.client);
  assert.deepEqual(await port.insertIfAbsent(msg()), { kind: "inserted" });
  assert.equal(db.rows.length, 1);
});

// ---------------------------------------------------------------------
// 30. Corrida: pre-check não encontra, outro scheduler insere, o INSERT
// desta execução colide (DO NOTHING) -> already_exists.
// ---------------------------------------------------------------------

test("30 (CASO C): corrida -- pre-check vazio, outro scheduler insere, INSERT colide -> already_exists", async () => {
  let db!: ReturnType<typeof fakeDb>;
  db = fakeDb({
    beforeUpsert: () => {
      if (db.rows.length === 0) db.insertWithTrigger(rowOf(msg())); // scheduler concorrente
    },
  });
  const port = createSupabaseMaterializationPort(db.client);
  assert.deepEqual(await port.insertIfAbsent(msg()), { kind: "already_exists" });
  assert.equal(db.calls.select, 1);
  assert.equal(db.calls.upsert, 1);
  assert.equal(db.rows.length, 1, "nenhuma duplicata");
});

// ---------------------------------------------------------------------
// 31/32/33. Classificação por SQLSTATE (nunca pelo texto da mensagem).
// ---------------------------------------------------------------------

test("31: SQLSTATE customizado WA001 -> consent_no_longer_valid", async () => {
  const db = fakeDb({ upsertResult: { data: null, error: { code: "WA001", message: "qualquer texto" } } });
  const port = createSupabaseMaterializationPort(db.client);
  assert.deepEqual(await port.insertIfAbsent(msg()), { kind: "consent_no_longer_valid" });
});

test("32: P0001 genérico (mesmo com a mensagem antiga da 0023) NÃO é consent_no_longer_valid", async () => {
  const db = fakeDb({
    upsertResult: {
      data: null,
      error: { code: "P0001", message: "whatsapp_messages: consentimento ativo incompativel com a mensagem" },
    },
  });
  const port = createSupabaseMaterializationPort(db.client);
  assert.deepEqual(await port.insertIfAbsent(msg()), { kind: "error", code: "persistence_error" });
});

test("33: outro SQLSTATE (23505, 23514, 42501, sem code) -> error", async () => {
  for (const code of ["23505", "23514", "42501", undefined]) {
    const db = fakeDb({ upsertResult: { data: null, error: { code, message: "x" } } });
    const port = createSupabaseMaterializationPort(db.client);
    assert.deepEqual(await port.insertIfAbsent(msg()), { kind: "error", code: "persistence_error" }, `code=${code}`);
  }
});

// ---------------------------------------------------------------------
// 34. Exceção de rede/fetch e resposta inesperada -> error, NUNCA lança.
// ---------------------------------------------------------------------

test("34: exceção de rede/fetch no pre-check -> error, não lança", async () => {
  const port = createSupabaseMaterializationPort(fakeDb({ throwOnSelect: true }).client);
  await assert.doesNotReject(() => port.insertIfAbsent(msg()));
  assert.deepEqual(await port.insertIfAbsent(msg()), { kind: "error", code: "persistence_error" });
});

test("34b: exceção de rede/fetch no INSERT -> error, não lança", async () => {
  const port = createSupabaseMaterializationPort(fakeDb({ throwOnUpsert: true }).client);
  await assert.doesNotReject(() => port.insertIfAbsent(msg()));
  assert.deepEqual(await port.insertIfAbsent(msg()), { kind: "error", code: "persistence_error" });
});

test("34c: resposta inesperada (data null/não-array/>1 linha, sem error) -> error, nunca inserted/already_exists", async () => {
  for (const data of [null, undefined, {}, [{ id: "a" }, { id: "b" }]]) {
    const port = createSupabaseMaterializationPort(fakeDb({ upsertResult: { data, error: null } }).client);
    assert.deepEqual(await port.insertIfAbsent(msg()), { kind: "error", code: "persistence_error" }, JSON.stringify(data));
  }
  const portSelect = createSupabaseMaterializationPort(fakeDb({ selectResult: { data: null, error: null } }).client);
  assert.deepEqual(await portSelect.insertIfAbsent(msg()), { kind: "error", code: "persistence_error" });
});

test("34d: materializeAll não aborta o lote quando o port falha numa candidata", async () => {
  let n = 0;
  const db = fakeDb({ beforeUpsert: () => { if (++n === 2) throw new Error("fetch failed (simulado)"); } });
  const port = createSupabaseMaterializationPort(db.client);
  const summary = await materializeAll(port, [
    msg({ appointmentId: "a1" }),
    msg({ appointmentId: "a2" }),
    msg({ appointmentId: "a3" }),
  ]);
  assert.deepEqual(summary, { candidates: 3, inserted: 2, alreadyExisting: 0, rejected: 0, errors: 1 });
});

// ---------------------------------------------------------------------
// 35. Erro bruto com telefone/consentId/failing row nunca aparece no
// MaterializationSummary, no outcome nem nos logs.
// ---------------------------------------------------------------------

test("35: raw error com telefone fictício não aparece em MaterializationSummary, outcome nem logs", async () => {
  const db = fakeDb({
    upsertResult: {
      data: null,
      error: {
        code: "23514",
        message: `new row violates check constraint, destination_phone_e164 = ${PHONE}`,
        details: `Failing row contains (row-x, fisio-1, patient-1, appt-1, ${PHONE}, consent-1).`,
      },
    },
  });
  const port = createSupabaseMaterializationPort(db.client);

  let outcomeJson = "";
  let summaryJson = "";
  const logs = await captureErrors(async () => {
    outcomeJson = JSON.stringify(await port.insertIfAbsent(msg()));
    summaryJson = JSON.stringify(await materializeAll(port, [msg()]));
  });

  for (const [nome, texto] of [["outcome", outcomeJson], ["summary", summaryJson], ["logs", logs]]) {
    for (const segredo of [PHONE, "consent-1", "patient-1", "Failing row", "check constraint"]) {
      assert.ok(!texto.includes(segredo), `${nome} nao deveria conter '${segredo}'`);
    }
  }
  assert.deepEqual(JSON.parse(summaryJson), { candidates: 1, inserted: 0, alreadyExisting: 0, rejected: 0, errors: 1 });
  assert.ok(logs.includes("whatsapp_message_materialization_failed"), "o log interno sanitizado existe");
});

// ---------------------------------------------------------------------
// 37. O pre-check consulta SOMENTE a tripla de identidade.
// ---------------------------------------------------------------------

test("37: pre-check consulta somente appointment_id+reminder_type+schedule_revision", async () => {
  const db = fakeDb();
  const port = createSupabaseMaterializationPort(db.client);
  await port.insertIfAbsent(msg({ appointmentId: "appt-37", reminderType: "appointment_12h", scheduleRevision: 3 }));

  assert.deepEqual(db.eqCalls, [
    ["appointment_id", "appt-37"],
    ["reminder_type", "appointment_12h"],
    ["schedule_revision", 3],
  ]);
  assert.deepEqual(db.selectColsCalls, ["id"], "pre-check so pede o id, nunca telefone/consentimento");
});

// ---------------------------------------------------------------------
// 38-44. WA001 não prova que a tripla está livre: o adapter faz um
// SEGUNDO SELECT só pela identidade antes de decidir.
// ---------------------------------------------------------------------

/** CASO E: entre o pre-check e o nosso INSERT, outro scheduler insere a tripla e o consentimento é revogado. */
function casoE(linhaConcorrente: Partial<Omit<Row, "id">> = {}) {
  let db!: ReturnType<typeof fakeDb>;
  db = fakeDb({
    beforeUpsert: () => {
      if (db.rows.length === 0) {
        const r = db.insertWithTrigger({ ...rowOf(msg()), ...linhaConcorrente });
        assert.equal(r.error, null, "a insercao concorrente deveria passar");
        if (linhaConcorrente.status) db.rows[0].status = linhaConcorrente.status;
      }
      db.consents.get("consent-1")!.revoked = true;
    },
  });
  return db;
}

test("38 e 41 (CASO E): WA001 + segundo SELECT encontra a tripla -> already_exists, sem UPDATE", async () => {
  const db = casoE();
  const port = createSupabaseMaterializationPort(db.client);
  const outcome = await port.insertIfAbsent(msg());
  assert.deepEqual(outcome, { kind: "already_exists" });
  assert.equal(db.calls.select, 2, "pre-check + SELECT apos WA001");
  assert.equal(db.calls.upsert, 1);
  assert.equal(db.calls.update, 0, "nenhuma tentativa de UPDATE");
  assert.equal(db.rows.length, 1, "nenhuma duplicata");
});

test("39 (CASO D): WA001 + segundo SELECT não encontra -> consent_no_longer_valid", async () => {
  const db = fakeDb({ consents: { "consent-1": { contactValue: PHONE, revoked: true } } });
  const port = createSupabaseMaterializationPort(db.client);
  assert.deepEqual(await port.insertIfAbsent(msg()), { kind: "consent_no_longer_valid" });
  assert.equal(db.calls.select, 2);
  assert.equal(db.rows.length, 0);
});

test("40 (CASO F): WA001 + segundo SELECT falha (erro ou exceção) -> error, nunca consent_no_longer_valid", async () => {
  for (const mode of ["error", "throw"] as const) {
    const db = fakeDb({
      consents: { "consent-1": { contactValue: PHONE, revoked: true } },
      selectFailOnCall: { call: 2, mode },
    });
    const port = createSupabaseMaterializationPort(db.client);
    let outcome: unknown;
    const logs = await captureErrors(async () => {
      outcome = await port.insertIfAbsent(msg());
    });
    assert.deepEqual(outcome, { kind: "error", code: "persistence_error" }, mode);
    assert.equal(db.calls.select, 2, mode);
    for (const segredo of [PHONE, "consent-1", "Failing row", "timeout", "fetch failed"]) {
      assert.ok(!logs.includes(segredo), `log (${mode}) nao deveria conter '${segredo}'`);
    }
    assert.ok(logs.includes("postconflict_select_failed"), mode);
  }
});

test("42: segundo SELECT usa somente a tripla de identidade e só pede o id", async () => {
  const db = fakeDb({ consents: { "consent-1": { contactValue: PHONE, revoked: true } } });
  const port = createSupabaseMaterializationPort(db.client);
  await port.insertIfAbsent(msg({ appointmentId: "appt-42", reminderType: "appointment_12h", scheduleRevision: 2 }));
  const tripla = [
    ["appointment_id", "appt-42"],
    ["reminder_type", "appointment_12h"],
    ["schedule_revision", 2],
  ];
  assert.deepEqual(db.eqCalls, [...tripla, ...tripla], "pre-check e 2o SELECT: so a tripla, nada mais");
  assert.deepEqual(db.selectColsCalls, ["id", "id"]);
});

test("43: P0001 continua NÃO sendo consent_no_longer_valid (e nem dispara o segundo SELECT)", async () => {
  const db = fakeDb({
    upsertResult: {
      data: null,
      error: { code: "P0001", message: "whatsapp_messages: consentimento ativo incompativel com a mensagem" },
    },
  });
  const port = createSupabaseMaterializationPort(db.client);
  assert.deepEqual(await port.insertIfAbsent(msg()), { kind: "error", code: "persistence_error" });
  assert.equal(db.calls.select, 1, "so WA001 aciona o segundo SELECT");
});

test("44: segundo SELECT não compara destination/consent/status -- linha concorrente divergente e cancelled vence", async () => {
  const db = casoE({ destination_phone_e164: "+5562977777777", consent_id: "consent-outro", status: "cancelled" });
  db.consents.set("consent-outro", { contactValue: "+5562977777777", revoked: false });
  const port = createSupabaseMaterializationPort(db.client);

  assert.deepEqual(await port.insertIfAbsent(msg()), { kind: "already_exists" });
  assert.equal(db.calls.update, 0);
  assert.equal(db.rows.length, 1);
  assert.equal(db.rows[0].destination_phone_e164, "+5562977777777", "nada corrigido");
  assert.equal(db.rows[0].consent_id, "consent-outro", "nada corrigido");
  assert.equal(db.rows[0].status, "cancelled", "cancelled nao e ressuscitada");
});
