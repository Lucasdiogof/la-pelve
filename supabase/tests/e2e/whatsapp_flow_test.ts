// E2E do fluxo WhatsApp com os adapters REAIS do Supabase (supabase-js ->
// PostgREST -> Postgres + Vault), sem Meta: o provider é falso.
// Rodar com supabase/tests/e2e/run_e2e.sh (cria e apaga um banco local).
//
//   consulta agendada
//   -> materialização (pedido de confirmação de 12h + aviso de agendamento)
//   -> dispatch (claim/prepare/complete) -> provider falso -> wamid/sent_at
//   -> paciente responde "Sim, confirmo!" -> whatsapp-webhook
//   -> process_whatsapp_confirmation_reply -> consulta confirmada
//
// Também: idempotência da materialização, reconciliação (consentimento
// revogado, remarcação) e dois dispatchers concorrentes sem envio duplo.

import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { assert, assertEquals } from "jsr:@std/assert@1";
import { createSupabaseSchedulerDataPort } from "../../functions/whatsapp-scheduler-dry-run/supabase_data_port.ts";
import { createSupabaseMaterializationPort } from "../../functions/_shared/materialization/supabase_materialization_port.ts";
import { createSupabaseReconciliationPort } from "../../functions/_shared/reconciliation/supabase_reconciliation_port.ts";
import { createSupabaseReconciliationDataPort } from "../../functions/_shared/pipeline/reconciliation_inputs.ts";
import { runWhatsappPipeline } from "../../functions/_shared/pipeline/run_pipeline.ts";
import { createSupabaseDispatchStore } from "../../functions/_shared/dispatch/supabase_dispatch_store.ts";
import { dispatchPendingWhatsappMessages } from "../../functions/_shared/dispatch/dispatch.ts";
import { createFakeWhatsappProvider } from "../../functions/_shared/dispatch/fake_provider.testutil.ts";
import type { TemplateConfig, WhatsappProvider } from "../../functions/_shared/dispatch/types.ts";
import { createSupabaseConfirmationReplyPort } from "../../functions/_shared/inbound/supabase_confirmation_port.ts";
import { createWebhookHandler, hmacSha256Hex } from "../../functions/whatsapp-webhook/handler.ts";

const DB = Deno.env.get("E2E_DB")!;
const REST_URL = Deno.env.get("E2E_REST_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("E2E_SERVICE_ROLE_KEY")!;

const TOKEN = `tok_teste_e2e_${crypto.randomUUID()}`;
const APP_SECRET = `secret_e2e_${crypto.randomUUID()}`;
const PHONE_NUMBER_ID = "123456789012345";
const silentLog = () => {};

// Fuso em que "agora" é meio-dia: o teste não depende da hora em que roda
// (fora do silêncio 22:00-06:59 do scheduler).
const OFFSET = 12 - new Date().getUTCHours();
const TZ = OFFSET === 0 ? "Etc/GMT" : OFFSET > 0 ? `Etc/GMT-${OFFSET}` : `Etc/GMT+${-OFFSET}`;

const ALL_TEMPLATES: TemplateConfig = {
  languageCode: "pt_BR",
  names: {
    appointment_confirmation: "la_pelve_agendamento",
    appointment_12h: "la_pelve_confirmacao",
    appointment_rescheduled: "la_pelve_remarcacao",
  },
};
const ONLY_12H: TemplateConfig = { languageCode: "pt_BR", names: { appointment_12h: "la_pelve_confirmacao" } };

/** PostgREST local serve na raiz; supabase-js chama /rest/v1. */
function client(): SupabaseClient {
  return createClient(REST_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
    global: {
      fetch: (input: string | URL | Request, init?: RequestInit) =>
        fetch(String(input instanceof Request ? input.url : input).replace(`${REST_URL}/rest/v1`, REST_URL), init),
    },
  });
}

/** SQL de preparação como superusuário (só o que o app/scheduler criaria). */
async function sql(query: string): Promise<string> {
  const out = await new Deno.Command("psql", {
    args: ["-X", "-q", "-At", "-v", "ON_ERROR_STOP=1", "-d", DB],
    stdin: "piped",
    stdout: "piped",
    stderr: "piped",
    env: { PGOPTIONS: "-c client_min_messages=warning" },
  }).spawn();
  const writer = out.stdin.getWriter();
  await writer.write(new TextEncoder().encode(query));
  await writer.close();
  const { code, stdout, stderr } = await out.output();
  if (code !== 0) throw new Error(new TextDecoder().decode(stderr));
  return new TextDecoder().decode(stdout).trim();
}

function pipeline(db: SupabaseClient, provider: WhatsappProvider, templates: TemplateConfig) {
  return runWhatsappPipeline({
    schedulerData: createSupabaseSchedulerDataPort(db),
    materialization: createSupabaseMaterializationPort(db),
    reconciliationData: createSupabaseReconciliationDataPort(db),
    reconciliation: createSupabaseReconciliationPort(db),
    dispatch: { store: createSupabaseDispatchStore(db), provider, templates, now: () => new Date(), log: silentLog },
    now: () => new Date(),
  });
}

async function newPatient(fisio: string, id: string, phone: string, name: string) {
  await sql(`
    insert into public.patients (id, fisioterapeuta_id, name, phone, phone_e164)
    values ('${id}', '${fisio}', '${name}', '${phone}', '${phone}');
    insert into public.patient_consents (fisioterapeuta_id, patient_id, channel, purpose, contact_value, source)
    values ('${fisio}', '${id}', 'whatsapp', 'appointment_reminder', '${phone}', 'teste');`);
}

/** Consulta que começa em now()+startsIn, criada agora (trigger normal). */
async function newAppointment(fisio: string, patient: string, id: string, startsIn: string) {
  await sql(`
    insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status, patient_id)
    select '${id}', '${fisio}', l::date, date_trunc('minute', l)::time, 'x', 'scheduled', '${patient}'
    from (select (now() + interval '${startsIn}') at time zone '${TZ}' as l) s;`);
}

function messages(appointmentId: string) {
  return sql(`
    select string_agg(reminder_type || ':' || schedule_revision || ':' || status || ':' || coalesce(wamid, '-'), ',' order by reminder_type, schedule_revision)
    from public.whatsapp_messages where appointment_id = '${appointmentId}';`);
}

Deno.test({
  name: "WhatsApp outbound -> inbound com adapters reais",
  // O supabase-js deixa timers internos (auth/realtime) abertos por cliente;
  // não são do código testado.
  sanitizeOps: false,
  sanitizeResources: false,
}, async (t) => {
  const db = client();

  const fisio = await sql(`
    insert into auth.users (email) values ('fisio@e2e.local') returning id;`);
  await sql(`update public.profiles set timezone = '${TZ}' where id = '${fisio}';`);
  const connectionId = await sql(`
    insert into public.whatsapp_connections (fisioterapeuta_id, waba_id, phone_number_id, status, connected_at)
    values ('${fisio}', 'waba-e2e', '${PHONE_NUMBER_ID}', 'connected', now()) returning id;`);

  await t.step("credencial provisionada no Vault pela RPC (service_role)", async () => {
    const { error } = await db.rpc("set_whatsapp_connection_access_token", {
      p_connection_id: connectionId,
      p_access_token: TOKEN,
    });
    assertEquals(error, null);
    assertEquals(await sql(`select count(*) from vault.secrets where secret = '${TOKEN}';`), "0");
  });

  // Camila: consulta criada há 2 dias, começa daqui a 11h50 -> o pedido de
  // confirmação (12h antes) já está devido. Simula a criação antiga.
  await newPatient(fisio, "pat-camila", "+5562911118888", "Camila Souza");
  await sql(`
    alter table public.appointments disable trigger appointments_set_schedule_revision;
    insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status, patient_id,
      created_at, schedule_revision, schedule_revision_at)
    select 'appt-camila', '${fisio}', l::date, date_trunc('minute', l)::time, 'x', 'scheduled', 'pat-camila',
      now() - interval '2 days', 0, now() - interval '2 days'
    from (select (now() + interval '11 hours 50 minutes') at time zone '${TZ}' as l) s;
    alter table public.appointments enable trigger appointments_set_schedule_revision;`);
  // Bruna: consulta criada agora, daqui a 3 dias -> aviso de agendamento devido.
  await newPatient(fisio, "pat-bruna", "+5562911117777", "Bruna Lima");
  await newAppointment(fisio, "pat-bruna", "appt-bruna", "3 days");

  const provider = createFakeWhatsappProvider();

  await t.step("1a rodada: materializa e envia o pedido de confirmação e o aviso", async () => {
    const summary = await pipeline(db, provider, ALL_TEMPLATES);
    assert(!("error" in summary.materialization), "materialização sem erro");
    assertEquals(summary.materialization.inserted, 2);
    assertEquals(summary.dispatch.sent, 2);
    assertEquals(provider.sent.length, 2);

    const twelve = provider.sent.find((s) => s.message.template.name === "la_pelve_confirmacao")!;
    assertEquals(twelve.accessToken, TOKEN);
    assertEquals(twelve.phoneNumberId, PHONE_NUMBER_ID);
    assertEquals(twelve.message.to, "5562911118888");
    const params = twelve.message.template.components[0].parameters as Array<{ text: string }>;
    assertEquals(params[0].text, "Camila");
    // {{2}} do pedido de confirmação é sempre a data "dd/MM" (nunca hoje/amanhã).
    assert(/^\d{2}\/\d{2}$/.test(params[1].text));
    assert(/^\d{2}:\d{2}$/.test(params[2].text));
    assertEquals(twelve.message.template.components[1], {
      type: "button",
      sub_type: "quick_reply",
      index: "0",
      parameters: [{ type: "payload", payload: "LA_PELVE_CONFIRM_APPOINTMENT" }],
    });

    assert((await messages("appt-camila")).startsWith("appointment_12h:0:sent:wamid.fake-"));
    assertEquals(
      await sql(`select (sent_at is not null and lease_token is null and attempt_count = 1 and error is null)::text
                 from public.whatsapp_messages where appointment_id = 'appt-camila';`),
      "true",
    );
    assert((await messages("appt-bruna")).startsWith("appointment_confirmation:0:sent:wamid.fake-"));
  });

  await t.step("2a rodada: nada duplica (materialização idempotente, nada reenviado)", async () => {
    const summary = await pipeline(db, provider, ALL_TEMPLATES);
    assert(!("error" in summary.materialization));
    assertEquals(summary.materialization.inserted, 0);
    assertEquals(summary.materialization.alreadyExisting, 2);
    assertEquals(summary.dispatch.claimed, 0);
    assertEquals(provider.sent.length, 2);
    assertEquals(await sql(`select count(*) from public.whatsapp_messages;`), "2");
  });

  await t.step("paciente responde 'Sim, confirmo!' citando a mensagem -> consulta confirmada", async () => {
    const wamid = await sql(`select wamid from public.whatsapp_messages where appointment_id = 'appt-camila';`);
    const handler = createWebhookHandler({
      verifyToken: "verify-e2e",
      appSecret: APP_SECRET,
      getPort: () => createSupabaseConfirmationReplyPort(db),
      log: silentLog,
    });
    const body = JSON.stringify({
      object: "whatsapp_business_account",
      entry: [{
        id: "waba-e2e",
        changes: [{
          field: "messages",
          value: {
            metadata: { phone_number_id: PHONE_NUMBER_ID },
            messages: [{
              id: "wamid.in.e2e-1",
              from: "5562911118888",
              timestamp: String(Math.floor(Date.now() / 1000)),
              type: "text",
              context: { id: wamid },
              text: { body: "Sim, confirmo!" },
            }],
          },
        }],
      }],
    });
    const post = async () =>
      handler(new Request("https://example.test/whatsapp-webhook", {
        method: "POST",
        headers: { "x-hub-signature-256": `sha256=${await hmacSha256Hex(APP_SECRET, body)}` },
        body,
      }));
    assertEquals((await post()).status, 200);
    assertEquals(await sql(`select status from public.appointments where id = 'appt-camila';`), "confirmed");
    assertEquals(
      await sql(`select (confirmation_consumed_at is not null)::text from public.whatsapp_messages where appointment_id = 'appt-camila';`),
      "true",
    );
    assertEquals(await sql(`select status from public.appointments where id = 'appt-bruna';`), "scheduled");
    // Webhook reenviado: nada muda.
    assertEquals((await post()).status, 200);
    assertEquals(await sql(`select count(*) from public.whatsapp_inbound_messages;`), "1");
  });

  await t.step("reconciliação: consentimento revogado antes do envio -> cancelada, nunca enviada", async () => {
    await newPatient(fisio, "pat-dora", "+5562911116666", "Dora Alves");
    await newAppointment(fisio, "pat-dora", "appt-dora", "3 days");
    await pipeline(db, provider, ONLY_12H); // aviso materializado, mas sem template: fica na fila
    assertEquals(await messages("appt-dora"), "appointment_confirmation:0:scheduled:-");
    await sql(`update public.patient_consents set revoked_at = now() where patient_id = 'pat-dora';`);
    const before = provider.sent.length;
    const summary = await pipeline(db, provider, ALL_TEMPLATES);
    assert(!("error" in summary.reconciliation));
    assertEquals(summary.reconciliation.cancelledByReason.consent_revoked, 1);
    assertEquals(await messages("appt-dora"), "appointment_confirmation:0:cancelled:-");
    assertEquals(provider.sent.length, before);
  });

  await t.step("reconciliação: remarcação cancela o aviso antigo e materializa o de remarcação", async () => {
    await newPatient(fisio, "pat-elis", "+5562911115555", "Elis Prado");
    await newAppointment(fisio, "pat-elis", "appt-elis", "3 days");
    await pipeline(db, provider, ONLY_12H);
    await sql(`update public.appointments set date = date + 1 where id = 'appt-elis';`);
    const summary = await pipeline(db, provider, ONLY_12H);
    assert(!("error" in summary.reconciliation));
    assertEquals(summary.reconciliation.cancelledByReason.stale_schedule_revision, 1);
    assertEquals(
      await messages("appt-elis"),
      "appointment_confirmation:0:cancelled:-,appointment_rescheduled:1:scheduled:-",
    );
  });

  await t.step("dois dispatchers simultâneos nunca enviam a mesma mensagem duas vezes", async () => {
    await newPatient(fisio, "pat-fila", "+5562911114444", "Fila Teste");
    await sql(`
      insert into public.appointments (id, fisioterapeuta_id, date, time, patient_name, status, patient_id)
      select 'appt-fila-' || g, '${fisio}', l::date, date_trunc('minute', l)::time, 'x', 'scheduled', 'pat-fila'
      from generate_series(1, 12) g, (select (now() + interval '4 days') at time zone '${TZ}' as l) s;
      insert into public.whatsapp_messages (fisioterapeuta_id, patient_id, appointment_id, reminder_type,
        schedule_revision, scheduled_for, destination_phone_e164, consent_id)
      select '${fisio}', 'pat-fila', 'appt-fila-' || g, 'appointment_confirmation', 0, now() - interval '1 minute',
        '+5562911114444', (select id from public.patient_consents where patient_id = 'pat-fila')
      from generate_series(1, 12) g;`);
    const slow = createFakeWhatsappProvider(async (_r, i) => {
      await new Promise((r) => setTimeout(r, 15));
      return { kind: "sent", wamid: `wamid.concurrent-${i + 1}` };
    });
    const run = () =>
      dispatchPendingWhatsappMessages({
        store: createSupabaseDispatchStore(client()),
        provider: slow,
        // Só o tipo das 12 mensagens desta etapa (a remarcação da etapa
        // anterior também está devida e ficaria fora da contagem).
        templates: { languageCode: "pt_BR", names: { appointment_confirmation: "la_pelve_agendamento" } },
        now: () => new Date(),
        limit: 8,
        log: silentLog,
      });
    const [a, b] = await Promise.all([run(), run()]);
    assertEquals(a.claimed + b.claimed, 12);
    assertEquals(slow.sent.length, 12);
    assertEquals(
      await sql(`select count(distinct wamid) || '/' || count(*) from public.whatsapp_messages
                 where appointment_id like 'appt-fila-%' and status = 'sent';`),
      "12/12",
    );
  });

  await t.step("token nunca fora do Vault", async () => {
    assertEquals(
      await sql(`select count(*) from public.whatsapp_messages m where m::text like '%${TOKEN}%';`),
      "0",
    );
    assertEquals(
      await sql(`select count(*) from public.whatsapp_inbound_messages m where m::text like '%${TOKEN}%';`),
      "0",
    );
  });
});
