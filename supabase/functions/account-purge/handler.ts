// HTTP do account-purge -- PURO, testável em Node. Chamado pelo agendador (pg_cron + pg_net) com
// POST e Authorization: Bearer <ACCOUNT_PURGE_TOKEN>. Sem o token certo nada é lido nem apagado.

import { runAccountPurge, type PurgePorts } from "./purge.ts";

export interface PurgeHandlerDeps {
  token: string | undefined;
  ports: () => PurgePorts;
  log?: (event: string, data: Record<string, unknown>) => void;
}

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
}

/** Comparação em tempo constante do Bearer; token ausente ou curto nunca autoriza. */
export function isAuthorized(header: string | null, token: string | undefined): boolean {
  if (!token || token.length < 32 || !header || !header.startsWith("Bearer ")) return false;
  const given = header.slice("Bearer ".length);
  if (given.length !== token.length) return false;
  let diff = 0;
  for (let i = 0; i < token.length; i++) diff |= given.charCodeAt(i) ^ token.charCodeAt(i);
  return diff === 0;
}

export function createPurgeHandler(deps: PurgeHandlerDeps): (req: Request) => Promise<Response> {
  const log = deps.log ?? ((event, data) => console.log(JSON.stringify({ event, ...data })));
  let running = false;
  return async (req) => {
    if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
    if (!isAuthorized(req.headers.get("authorization"), deps.token)) {
      log("account_purge_unauthorized", {});
      return new Response("Unauthorized", { status: 401 });
    }
    if (running) return json(409, { error: "already_running" });
    running = true;
    try {
      const summary = await runAccountPurge(deps.ports());
      log("account_purge_run", { ...summary });
      return json(200, summary);
    } catch {
      log("account_purge_failed", {});
      return json(500, { error: "run_failed" });
    } finally {
      running = false;
    }
  };
}
