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
import { execFileSync, spawn } from "node:child_process";
import { randomUUID } from "node:crypto";
import { readdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { createWebhookHandler, hmacSha256Hex } from "./handler.ts";
import type { ConfirmationReplyPort } from "../_shared/inbound/types.ts";
import type { DeliveryStatusPort, StatusApplyResult } from "../_shared/delivery/status_port.ts";
import type { TemplateStatusPort } from "../_shared/templates/template_port.ts";
import { reevaluateAfterApproval, type ReadinessReader, type ReevaluationPort } from "../_shared/templates/reevaluate.ts";

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
       perform public.set_whatsapp_connection_access_token(
         (select id from public.whatsapp_connections where fisioterapeuta_id = f), 'token-ficticio-e2e');
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

// --------------------------------------------------------------------------
// 0034: histórico preservado, eventos fora de ordem, concorrência e
// reavaliação automática (SQL real)
// --------------------------------------------------------------------------


const BASE = now + 1000;
const iso = (unix: number) => new Date(unix * 1000).toISOString();

function connection() {
  const [status, code, verified, event12h] = psql(
    `select status, coalesce(last_error->>'code', ''), coalesce(setup_state->>'templates_verified_at', ''),
            coalesce(setup_state->'templates'->'appointment_12h:pt_BR'->>'event', '')
       from public.whatsapp_connections;`,
  ).split("|");
  return { status, code, verified, event12h };
}

/** O mesmo upsert que o whatsapp-connect faz ao gravar uma avaliação. */
function upsertSql(status: string, evaluatedAt: number | null): string {
  const setup = evaluatedAt === null ? `'{"mode":"cloud"}'::jsonb` : `jsonb_build_object('mode','cloud','evaluated_at','${iso(evaluatedAt)}')`;
  const err = status === "connected" ? "null" : `'{"code":"templates_pending"}'::jsonb`;
  return `select public.upsert_whatsapp_connection_from_signup(
            (select fisioterapeuta_id from public.whatsapp_connections), '${WABA}', '${PNID}', null, '${status}', ${err}, ${setup});`;
}

function tryUpsert(status: string, evaluatedAt: number | null): string {
  try {
    psql(`set role service_role; ${upsertSql(status, evaluatedAt)}`);
    return "ok";
  } catch (e) {
    return String((e as { stderr?: string }).stderr ?? e).includes("template mudou") ? "WA010" : "error";
  }
}

const sqlReevaluationPort: ReevaluationPort = {
  async candidates(wabaId) {
    const out = psql(
      `set role service_role;
       select coalesce(json_agg(json_build_object('f', fisioterapeuta_id, 'p', phone_number_id, 's', setup_state)), '[]')
         from public.list_whatsapp_template_reevaluation_candidates(:'waba');`,
      { waba: wabaId },
    );
    return (JSON.parse(out) as Array<{ f: string; p: string; s: Record<string, unknown> }>).map((r) => ({
      fisioterapeutaId: r.f,
      phoneNumberId: r.p,
      displayPhoneNumber: null,
      setupState: r.s,
    }));
  },
  async accessToken() {
    return "token-ficticio-e2e";
  },
  async promote(candidate, input) {
    try {
      psql(
        `set role service_role;
         select public.upsert_whatsapp_connection_from_signup(:'f'::uuid, :'waba', :'pnid', null, 'connected', null,
           (:'setup')::jsonb);`,
        {
          f: candidate.fisioterapeutaId,
          waba: input.wabaId,
          pnid: candidate.phoneNumberId,
          setup: JSON.stringify({ ...candidate.setupState, evaluated_at: input.evaluatedAt }),
        },
      );
      return "connected";
    } catch (e) {
      return String((e as { stderr?: string }).stderr ?? e).includes("template mudou") ? "stale" : "error";
    }
  },
};

function fakeMeta(approved: boolean): ReadinessReader {
  return {
    async getPhoneInfo() {
      return { ok: true, info: { displayPhoneNumber: "+55 62 1", status: "CONNECTED", isPinEnabled: false } };
    },
    async getTemplatesReport() {
      return { ok: true, report: { confirmation: "approved", reminder: approved ? "approved" : "pending" } };
    },
    async getAccountHealth() {
      return { ok: true, health: "available" };
    },
  };
}

test("integração 0034: REJECTED T2 -> Atualizar status (Meta aprovada) -> REJECTED atrasado T1 é ignorado", { skip }, async () => {
  assert.equal(await post(templateBody("REJECTED", BASE + 20)), 200);
  assert.deepEqual(connection(), { status: "pending", code: "templates_pending", verified: "", event12h: "REJECTED" });
  // "Atualizar status" que começou ANTES do REJECTED não conecta.
  assert.equal(tryUpsert("connected", BASE + 10), "WA010");
  // Reavaliação completa depois do REJECTED (Meta já aprovou de novo).
  assert.equal(tryUpsert("connected", BASE + 30), "ok");
  assert.equal(connection().status, "connected");
  assert.equal(connection().event12h, "REJECTED", "histórico preservado pelo upsert");
  // Webhook atrasado de antes da verificação.
  assert.equal(await post(templateBody("REJECTED", BASE + 15)), 200);
  assert.equal(connection().status, "connected");
});

test("integração 0034: dois webhooks fora de ordem: o mais antigo não sobrescreve o mais novo", { skip }, async () => {
  assert.equal(await post(templateBody("PAUSED", BASE + 50)), 200);
  assert.equal(await post(templateBody("APPROVED", BASE + 40)), 200);
  const c = connection();
  assert.equal(c.event12h, "PAUSED");
  assert.equal(c.status, "pending");
});

test("integração 0034: concorrência upsert(connected) x webhook negativo mais novo: nunca termina conectada", { skip }, async () => {
  // 1) a reavaliação trava a linha e demora; o webhook espera e aplica depois.
  const evaluatedAt = BASE + 60;
  const slow = spawn("psql", ["-X", "-q", "-At", "-v", "ON_ERROR_STOP=1", "-d", DB], { env: pgEnv });
  const done = new Promise<number>((resolve) => slow.on("close", (code) => resolve(code ?? 1)));
  slow.stdin.end(`set role service_role; begin; ${upsertSql("connected", evaluatedAt)} select pg_sleep(1.5); commit;`);
  await new Promise((r) => setTimeout(r, 400));
  assert.equal(await post(templateBody("DISABLED", BASE + 70)), 200);
  assert.equal(await done, 0);
  let c = connection();
  assert.equal(c.status, "pending", "o evento mais novo venceu depois do commit");
  assert.equal(c.code, "templates_rejected");

  // 2) o webhook grava primeiro; a reavaliação iniciada antes dele é recusada.
  assert.equal(await post(templateBody("APPROVED", BASE + 80)), 200);
  assert.equal(tryUpsert("connected", BASE + 90), "ok");
  assert.equal(await post(templateBody("PAUSED", BASE + 100)), 200);
  assert.equal(tryUpsert("connected", BASE + 95), "WA010");
  c = connection();
  assert.equal(c.status, "pending");
});

test("integração 0034: reavaliação automática só conecta com a Meta aprovada (e respeita WA010)", { skip }, async () => {
  // Pendente por template (estado do teste anterior).
  const notReady = await reevaluateAfterApproval(WABA, sqlReevaluationPort, fakeMeta(false), () => new Date((BASE + 200) * 1000));
  assert.equal(notReady.promoted, 0);
  assert.equal(connection().status, "pending");
  const ready = await reevaluateAfterApproval(WABA, sqlReevaluationPort, fakeMeta(true), () => new Date((BASE + 200) * 1000));
  assert.deepEqual(ready, { candidates: 1, promoted: 1, notReady: 0, stale: 0, errors: 0 });
  assert.equal(connection().status, "connected");
  assert.equal(await post(templateBody("REJECTED", BASE + 99)), 200, "evento antigo depois da verificação");
  assert.equal(connection().status, "connected");
});
