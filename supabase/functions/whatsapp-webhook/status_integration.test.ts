// Integração dos webhooks de status de entrega e de templates SEM a Meta
// real, contra um Postgres LOCAL descartável com todas as migrations:
// webhook assinado -> handler -> parser -> apply_whatsapp_message_status /
// apply_whatsapp_template_status (SQL real, como service_role).
//
// Só roda com LA_PELVE_TEST_PGHOST definido (socket ou localhost), ex.:
//   LA_PELVE_TEST_PGHOST=/var/run/postgresql \
//     node --test --experimental-strip-types supabase/functions/whatsapp-webhook/status_integration.test.ts
// Nunca aponte para o projeto Supabase real.

import { after, before, test } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { randomUUID } from "node:crypto";
import { readdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { createWebhookHandler, hmacSha256Hex } from "./handler.ts";
import type { ConfirmationReplyPort } from "../_shared/inbound/types.ts";
import type { DeliveryStatusPort, StatusApplyResult } from "../_shared/delivery/status_port.ts";
import type { TemplateStatusPort } from "../_shared/templates/template_port.ts";

const PGHOST = process.env.LA_PELVE_TEST_PGHOST;
const PGPORT = process.env.LA_PELVE_TEST_PGPORT ?? "5432";
const PGUSER = process.env.LA_PELVE_TEST_PGUSER ?? "postgres";
const skip = !PGHOST
  ? "LA_PELVE_TEST_PGHOST não definido"
  : !(PGHOST.startsWith("/") || PGHOST === "localhost" || PGHOST === "127.0.0.1")
  ? "LA_PELVE_TEST_PGHOST precisa ser local"
  : false;

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "..");
const DB = `la_pelve_status_${process.pid}`;
const APP_SECRET = `secret-${randomUUID()}`;
const PNID = "5511000000777";
const WABA = "9100000000777";
const WAMID = "wamid.out.status.e2e";

const pgEnv = { ...process.env, PGHOST, PGPORT, PGUSER, PGOPTIONS: "-c client_min_messages=warning" };

function psql(sql: string, vars: Record<string, string> = {}): string {
  const args = ["-X", "-q", "-At", "-v", "ON_ERROR_STOP=1", "-d", DB];
  for (const [k, v] of Object.entries(vars)) args.push("-v", `${k}=${v}`);
  return execFileSync("psql", args, { input: sql, env: pgEnv, encoding: "utf8" }).trim();
}

const statusPort: DeliveryStatusPort = {
  async applyStatus(s) {
    return psql(
      `set role service_role;
       select public.apply_whatsapp_message_status(:'pnid', :'wamid', :'status', :'at'::timestamptz,
         nullif(:'code', '')::integer);`,
      { pnid: s.phoneNumberId, wamid: s.wamid, status: s.status, at: s.occurredAt, code: s.errorCode === null ? "" : String(s.errorCode) },
    ) as StatusApplyResult;
  },
};

const templatePort: TemplateStatusPort = {
  async applyTemplateStatus(e) {
    return Number(
      psql(
        `set role service_role;
         select public.apply_whatsapp_template_status(:'waba', :'name', :'lang', :'event', nullif(:'at', '')::timestamptz);`,
        { waba: e.wabaId, name: e.name, lang: e.language, event: e.event, at: e.occurredAt ?? "" },
      ),
    );
  },
};

const noReplies: ConfirmationReplyPort = {
  async processConfirmationReply() {
    throw new Error("não deveria haver resposta de paciente neste teste");
  },
};

before(() => {
  if (skip) return;
  execFileSync("createdb", [DB], { env: pgEnv });
  psql(readFileSync(join(ROOT, "supabase/tests/supabase_stubs.sql"), "utf8"));
  const migrations = readdirSync(join(ROOT, "supabase/migrations"))
    .filter((f) => f.endsWith(".sql") && !f.startsWith("0013_"))
    .sort();
  migrations.splice(migrations.indexOf("0011_rename_domain_to_english.sql"), 0, "0013_financial_entries_outro_fields.sql");
  for (const f of migrations) {
    execFileSync("psql", ["-X", "-q", "-v", "ON_ERROR_STOP=1", "-d", DB, "-f", join(ROOT, "supabase/migrations", f)], {
      env: pgEnv,
      stdio: ["ignore", "ignore", "pipe"],
    });
  }
  psql(
    `do $$
     declare f uuid; c uuid; m uuid;
       local_start timestamp := (now() + interval '20 hours') at time zone 'America/Sao_Paulo';
     begin
       insert into auth.users (email) values ('fisio@status.local') returning id into f;
       insert into public.whatsapp_connections (fisioterapeuta_id, waba_id, phone_number_id, status, connected_at)
       values (f, '${WABA}', '${PNID}', 'connected', now());
       insert into public.patients (id, fisioterapeuta_id, name, phone, phone_e164)
       values ('pat-status', f, 'Paciente', '(62) 91111-7777', '+5562911117777');
       insert into public.patient_consents (fisioterapeuta_id, patient_id, channel, purpose, contact_value, source)
       values (f, 'pat-status', 'whatsapp', 'appointment_reminder', '+5562911117777', 'teste') returning id into c;
       insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status, patient_id)
       values ('appt-status', f, local_start::date, date_trunc('second', local_start)::time, 'Paciente', 'scheduled', 'pat-status');
       insert into public.whatsapp_messages (fisioterapeuta_id, patient_id, appointment_id, reminder_type,
         schedule_revision, scheduled_for, destination_phone_e164, consent_id)
       values (f, 'pat-status', 'appt-status', 'appointment_12h', 0, now() - interval '1 hour', '+5562911117777', c)
       returning id into m;
       update public.whatsapp_messages set status = 'sent', wamid = '${WAMID}', sent_at = now() where id = m;
     end $$;`,
  );
});

after(() => {
  if (skip) return;
  execFileSync("dropdb", ["--if-exists", DB], { env: pgEnv });
});

async function post(body: unknown): Promise<number> {
  const handler = createWebhookHandler({
    verifyToken: "verify-status",
    appSecret: APP_SECRET,
    getPort: () => noReplies,
    getStatusPort: () => statusPort,
    getTemplatePort: () => templatePort,
    templates: { names: ["appointment_confirmation", "appointment_12h"], language: "pt_BR" },
    log: () => {},
  });
  const raw = JSON.stringify(body);
  const res = await handler(
    new Request("https://example.test/functions/v1/whatsapp-webhook", {
      method: "POST",
      headers: { "x-hub-signature-256": `sha256=${await hmacSha256Hex(APP_SECRET, raw)}` },
      body: raw,
    }),
  );
  return res.status;
}

const statusBody = (status: string, ts: number, extra: Record<string, unknown> = {}) => ({
  object: "whatsapp_business_account",
  entry: [{
    id: WABA,
    changes: [{
      field: "messages",
      value: {
        metadata: { display_phone_number: "556230000000", phone_number_id: PNID },
        statuses: [{ id: WAMID, status, timestamp: String(ts), recipient_id: "5562911117777", ...extra }],
      },
    }],
  }],
});

const templateBody = (event: string, ts: number) => ({
  object: "whatsapp_business_account",
  entry: [{
    id: WABA,
    time: ts,
    changes: [{
      field: "message_template_status_update",
      value: { event, message_template_id: 1, message_template_name: "appointment_12h", message_template_language: "pt_BR", reason: "NONE" },
    }],
  }],
});

function message() {
  const [status, delivered, read, error] = psql(
    `select status, (delivered_at is not null)::text, (read_at is not null)::text, coalesce(error::text, '')
       from public.whatsapp_messages where wamid = '${WAMID}';`,
  ).split("|");
  return { status, delivered: delivered === "true", read: read === "true", error };
}

const now = Math.floor(Date.now() / 1000);

test("integração: delivered e read avançam; duplicado e sent atrasado não rebaixam", { skip }, async () => {
  assert.equal(await post(statusBody("delivered", now)), 200);
  assert.deepEqual(message(), { status: "delivered", delivered: true, read: false, error: "" });
  assert.equal(await post(statusBody("read", now + 5)), 200);
  assert.equal(await post(statusBody("read", now + 5)), 200);
  assert.equal(await post(statusBody("sent", now - 5)), 200);
  assert.equal(await post(statusBody("failed", now + 9, { errors: [{ code: 131026, title: "x" }] })), 200);
  assert.deepEqual(message(), { status: "read", delivered: true, read: true, error: "" });
});

test("integração: PAUSED tira a conexão de connected; APPROVED não promove", { skip }, async () => {
  assert.equal(await post(templateBody("PAUSED", now)), 200);
  assert.equal(psql(`select status || ':' || (last_error->>'code') from public.whatsapp_connections;`), "pending:templates_pending");
  assert.equal(await post(templateBody("APPROVED", now + 60)), 200);
  assert.equal(psql(`select status from public.whatsapp_connections;`), "pending");
});
