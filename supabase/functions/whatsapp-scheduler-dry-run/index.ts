// Edge Function de diagnóstico: "se o scheduler rodasse agora, quais
// mensagens existiriam e por quê?". SOMENTE LEITURA -- nenhum insert/
// update/delete em lugar nenhum deste arquivo ou dos que ele importa.
// NÃO envia WhatsApp, NÃO chama a Meta, NÃO grava whatsapp_messages.
//
// NÃO é uma API para o Flutter: é uma ferramenta administrativa/backend de
// diagnóstico técnico. Autenticação própria (ver http.ts:isAuthorizedRequest),
// não o JWT de usuário final do Supabase -- por isso verify_jwt=false no
// config.toml, do mesmo jeito que whatsapp-webhook já faz pelo mesmo
// motivo (quem chama não é um usuário do app). verify_jwt=false só é
// seguro AQUI porque esta function implementa sua própria verificação
// abaixo, antes de qualquer leitura de dado.
//
// NÃO DEPLOYADA ainda.

import { createSupabaseSchedulerDataPort, createServiceRoleClient } from "./supabase_data_port.ts";
import { runDryRun } from "./orchestrate.ts";
import { isAuthorizedRequest, parseWindow } from "./http.ts";

const ADMIN_TOKEN = Deno.env.get("SCHEDULER_DRY_RUN_ADMIN_TOKEN");

function log(event: string, data: Record<string, unknown>) {
  console.log(JSON.stringify({ event, ...data }));
}

Deno.serve(async (req) => {
  if (req.method !== "GET" && req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // Autenticação administrativa PRIMEIRO -- fisioterapeuta_id (e qualquer
  // outro parâmetro) só é lido/avaliado depois disto ter passado.
  if (!isAuthorizedRequest(req.headers.get("authorization"), ADMIN_TOKEN)) {
    log("dry_run_unauthorized", {});
    return new Response("Unauthorized", { status: 401 });
  }

  const now = new Date();
  const url = new URL(req.url);
  // from/to são obrigatórios (ver http.ts): nesta function administrativa
  // não inferimos uma "data atual" universal, porque appointments.date é
  // civil por profissional e vários profissionais podem estar em
  // timezones diferentes. O scheduler automático futuro (cron) vai
  // precisar de estratégia própria -- provavelmente uma janela de
  // consulta mais ampla que cubra todos os timezones com segurança, com a
  // decisão timezone-aware aplicada depois por appointment -- a ser
  // desenhada quando o cron for criado, não aqui.
  const parsed = parseWindow(url);
  if (parsed.error || !parsed.window) {
    return new Response(JSON.stringify({ error: parsed.error }), {
      status: 400,
      headers: { "content-type": "application/json" },
    });
  }

  log("dry_run_started", {
    from: parsed.window.fromDate,
    to: parsed.window.toDate,
    fisioterapeuta_id: parsed.window.fisioterapeutaId,
  });

  try {
    const client = createServiceRoleClient();
    const port = createSupabaseSchedulerDataPort(client);
    const report = await runDryRun(port, parsed.window, now);

    log("dry_run_finished", {
      appointments: report.totals.appointments,
      eligible: report.totals.eligibleMessages,
      ineligible: report.totals.ineligibleMessages,
      errors: report.totals.errors,
    });

    return new Response(JSON.stringify(report), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  } catch (error) {
    log("dry_run_failed", { error: error instanceof Error ? error.message : String(error) });
    return new Response(JSON.stringify({ error: "dry-run failed" }), {
      status: 500,
      headers: { "content-type": "application/json" },
    });
  }
});
