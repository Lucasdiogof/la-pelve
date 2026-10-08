// HTTP do whatsapp-dispatcher -- PURO (sem Deno.*), testável em Node.
//
// Chamado pelo agendador (pg_cron + pg_net, ver supabase/rollout-0026/) com
// POST e Authorization: Bearer <WHATSAPP_DISPATCHER_TOKEN>. Sem o token
// certo, nada é lido nem enviado. Não é uma API do app.
//
// Resposta e logs: só contagens. Nunca token, telefone, nome ou erro bruto.

import { isAuthorizedRequest } from "../whatsapp-scheduler-dry-run/http.ts";
import type { PipelineSummary } from "../_shared/pipeline/run_pipeline.ts";
import type { ConfigResult, DispatcherConfig } from "./config.ts";

export interface DispatcherHandlerDeps {
  config: ConfigResult;
  /** Monta as dependências reais e roda 1 rodada (index.ts). */
  runPipeline: (config: DispatcherConfig) => Promise<PipelineSummary>;
  log?: (event: string, data: Record<string, unknown>) => void;
}

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
}

export function createDispatcherHandler(deps: DispatcherHandlerDeps): (req: Request) => Promise<Response> {
  const log = deps.log ?? ((event, data) => console.log(JSON.stringify({ event, ...data })));
  let running = false;

  return async (req: Request): Promise<Response> => {
    if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

    const token = deps.config.ok ? deps.config.config.dispatcherToken : undefined;
    if (!isAuthorizedRequest(req.headers.get("authorization"), token)) {
      log("whatsapp_dispatcher_unauthorized", {});
      return new Response("Unauthorized", { status: 401 });
    }
    if (!deps.config.ok) {
      // Inalcançável com token válido (token ausente já reprova acima), mas
      // explícito: configuração incompleta nunca roda.
      log("whatsapp_dispatcher_config_error", { missing: deps.config.missing });
      return json(500, { error: "misconfigured" });
    }

    // Uma rodada por instância de cada vez. Entre instâncias diferentes, o
    // banco garante (claim com SKIP LOCKED + lease).
    if (running) return json(409, { error: "already_running" });
    running = true;
    try {
      const summary = await deps.runPipeline(deps.config.config);
      log("whatsapp_dispatcher_run", { ...summary });
      return json(200, summary);
    } catch {
      log("whatsapp_dispatcher_failed", {});
      return json(500, { error: "run_failed" });
    } finally {
      running = false;
    }
  };
}
