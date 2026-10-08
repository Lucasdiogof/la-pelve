// E. Fluxo completo SEM a Meta real, contra um Postgres LOCAL descartável:
//   solicitação de confirmação enviada (whatsapp_messages appointment_12h)
//   -> webhook assinado com "Sim, confirmo!" -> handler -> parser ->
//   process_whatsapp_confirmation_reply (SQL real, como service_role)
//   -> consulta confirmada -> solicitação marcada como respondida.
//
// Só roda com LA_PELVE_TEST_PGHOST definido (socket ou localhost), ex.:
//   LA_PELVE_TEST_PGHOST=/var/run/postgresql LA_PELVE_TEST_PGPORT=5432 \
//     node --test --experimental-strip-types supabase/functions/whatsapp-webhook/integration.test.ts
// Cria um database novo com os stubs do Supabase + todas as migrations e o
// apaga no final. Nunca aponte para o projeto Supabase real.

import { after, before, test } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { randomUUID } from "node:crypto";
import { readdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { createWebhookHandler, hmacSha256Hex } from "./handler.ts";
import type { ConfirmationReplyOutcome, ConfirmationReplyPort } from "../_shared/inbound/types.ts";

const PGHOST = process.env.LA_PELVE_TEST_PGHOST;
const PGPORT = process.env.LA_PELVE_TEST_PGPORT ?? "5432";
const PGUSER = process.env.LA_PELVE_TEST_PGUSER ?? "postgres";
const skip = !PGHOST
  ? "LA_PELVE_TEST_PGHOST não definido"
  : !(PGHOST.startsWith("/") || PGHOST === "localhost" || PGHOST === "127.0.0.1")
  ? "LA_PELVE_TEST_PGHOST precisa ser local"
  : false;

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "..");
const DB = `la_pelve_e2e_${process.pid}`;
const APP_SECRET = `secret-${randomUUID()}`;
const PHONE_NUMBER_ID = "pn-e2e";
const PATIENT_WA_ID = "5562911117777";
const REQUEST_WAMID = "wamid.out.e2e";

const pgEnv = { ...process.env, PGHOST, PGPORT, PGUSER, PGOPTIONS: "-c client_min_messages=warning" };

function psql(sql: string, vars: Record<string, string> = {}): string {
  const args = ["-X", "-q", "-At", "-v", "ON_ERROR_STOP=1", "-d", DB];
  for (const [k, v] of Object.entries(vars)) args.push("-v", `${k}=${v}`);
  return execFileSync("psql", args, { input: sql, env: pgEnv, encoding: "utf8" }).trim();
}

/** Mesma RPC que o adapter Supabase chama, executada como service_role. */
const sqlPort: ConfirmationReplyPort = {
  async processConfirmationReply(input): Promise<ConfirmationReplyOutcome> {
    const out = psql(
      `set role service_role;
       select public.process_whatsapp_confirmation_reply(
         :'wamid', :'pnid', :'from'::text[], :'received'::timestamptz, :'type', nullif(:'ctx', ''));`,
      {
        wamid: input.wamid,
        pnid: input.phoneNumberId,
        from: `{${input.fromE164Candidates.join(",")}}`,
        received: input.receivedAt,
        type: input.messageType,
        ctx: input.contextWamid ?? "",
      },
    );
    return { kind: "processed", result: JSON.parse(out).outcome };
  },
};

let appointmentId = "";

before(() => {
  if (skip) return;
  execFileSync("createdb", [DB], { env: pgEnv });
  psql(readFileSync(join(ROOT, "supabase/tests/supabase_stubs.sql"), "utf8"));
  const migrations = readdirSync(join(ROOT, "supabase/migrations"))
    .filter((f) => f.endsWith(".sql") && !f.startsWith("0013_"))
    .sort();
  // Ordem real: 0013 rodou antes de 0011_rename_domain_to_english.
  migrations.splice(migrations.indexOf("0011_rename_domain_to_english.sql"), 0, "0013_financial_entries_outro_fields.sql");
  for (const f of migrations) {
    execFileSync("psql", ["-X", "-q", "-v", "ON_ERROR_STOP=1", "-d", DB, "-f", join(ROOT, "supabase/migrations", f)], {
      env: pgEnv,
      stdio: ["ignore", "ignore", "pipe"],
    });
  }

  appointmentId = `appt-${randomUUID()}`;
  // Valores são constantes do próprio teste (variáveis do psql não são
  // substituídas dentro de blocos $$).
  psql(
    `do $$
     declare
       f uuid;
       pat text := 'pat-e2e';
       c uuid;
       m uuid;
       local_start timestamp := (now() + interval '20 hours') at time zone 'America/Sao_Paulo';
     begin
       insert into auth.users (email) values ('fisio@e2e.local') returning id into f;
       insert into public.whatsapp_connections (fisioterapeuta_id, waba_id, phone_number_id, status, connected_at)
       values (f, 'waba-e2e', '${PHONE_NUMBER_ID}', 'connected', now());
       insert into public.patients (id, fisioterapeuta_id, name, phone, phone_e164)
       values (pat, f, 'Paciente E2E', '(62) 91111-7777', '+${PATIENT_WA_ID}');
       insert into public.patient_consents (fisioterapeuta_id, patient_id, channel, purpose, contact_value, source)
       values (f, pat, 'whatsapp', 'appointment_reminder', '+${PATIENT_WA_ID}', 'teste')
       returning id into c;
       insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status, patient_id)
       values ('${appointmentId}', f, local_start::date, date_trunc('second', local_start)::time, 'Paciente E2E', 'scheduled', pat);
       insert into public.whatsapp_messages (fisioterapeuta_id, patient_id, appointment_id, reminder_type,
         schedule_revision, scheduled_for, destination_phone_e164, consent_id)
       values (f, pat, '${appointmentId}', 'appointment_12h', 0, now() - interval '1 hour', '+${PATIENT_WA_ID}', c)
       returning id into m;
       update public.whatsapp_messages
       set status = 'delivered', wamid = '${REQUEST_WAMID}', sent_at = now() - interval '1 hour'
       where id = m;
     end $$;`,
  );
});

after(() => {
  if (skip) return;
  execFileSync("dropdb", ["--if-exists", DB], { env: pgEnv });
});

function replyPayload(id: string, body: string, contextId: string | null) {
  const message: Record<string, unknown> = {
    id,
    from: PATIENT_WA_ID,
    timestamp: String(Math.floor(Date.now() / 1000)),
    type: "text",
    text: { body },
  };
  if (contextId) message.context = { from: "556230000000", id: contextId };
  return {
    object: "whatsapp_business_account",
    entry: [
      {
        id: "waba-e2e",
        changes: [{ field: "messages", value: { metadata: { phone_number_id: PHONE_NUMBER_ID }, messages: [message] } }],
      },
    ],
  };
}

async function post(body: unknown): Promise<Response> {
  const handler = createWebhookHandler({
    verifyToken: "verify-e2e",
    appSecret: APP_SECRET,
    getPort: () => sqlPort,
    log: () => {},
  });
  const raw = JSON.stringify(body);
  return handler(
    new Request("https://example.test/functions/v1/whatsapp-webhook", {
      method: "POST",
      headers: { "x-hub-signature-256": `sha256=${await hmacSha256Hex(APP_SECRET, raw)}` },
      body: raw,
    }),
  );
}

function state() {
  const [status, consumed, inbound] = psql(
    `select a.status, (m.confirmation_consumed_at is not null)::text,
            (select count(*) from public.whatsapp_inbound_messages)::text
     from public.appointments a
     join public.whatsapp_messages m on m.appointment_id = a.id
     where a.id = '${appointmentId}';`,
  ).split("|");
  return { status, consumed: consumed === "true", inbound: Number(inbound) };
}

test("E2E: resposta negativa não muda nada", { skip }, async () => {
  const res = await post(replyPayload("wamid.in.e2e.no", "Não confirmo", REQUEST_WAMID));
  assert.equal(res.status, 200);
  assert.deepEqual(state(), { status: "scheduled", consumed: false, inbound: 0 });
});

test("E2E: 'Sim, confirmo!' citando a solicitação confirma a consulta e consome a solicitação", { skip }, async () => {
  const res = await post(replyPayload("wamid.in.e2e.1", "Sim, confirmo!", REQUEST_WAMID));
  assert.equal(res.status, 200);
  assert.deepEqual(state(), { status: "confirmed", consumed: true, inbound: 1 });
  assert.equal(
    psql(`select outcome from public.whatsapp_inbound_messages where wamid = 'wamid.in.e2e.1';`),
    "confirmed",
  );
});

test("E2E: o mesmo webhook reenviado não duplica nada", { skip }, async () => {
  const res = await post(replyPayload("wamid.in.e2e.1", "Sim, confirmo!", REQUEST_WAMID));
  assert.equal(res.status, 200);
  assert.deepEqual(state(), { status: "confirmed", consumed: true, inbound: 1 });
});

test("E2E: um segundo 'sim' (outra mensagem) resulta em já confirmado", { skip }, async () => {
  const res = await post(replyPayload("wamid.in.e2e.2", "sim", null));
  assert.equal(res.status, 200);
  assert.deepEqual(state(), { status: "confirmed", consumed: true, inbound: 2 });
  assert.equal(
    psql(`select outcome from public.whatsapp_inbound_messages where wamid = 'wamid.in.e2e.2';`),
    "already_confirmed",
  );
});
