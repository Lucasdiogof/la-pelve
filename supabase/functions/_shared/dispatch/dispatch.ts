// dispatchPendingWhatsappMessages: reserva -> revalida -> envia -> grava.
//
// Cada etapa de banco é uma transação curta (RPCs da 0026); nenhuma fica
// aberta durante a chamada HTTP. Duas execuções simultâneas nunca enviam a
// mesma linha (claim com SKIP LOCKED + lease_token). Nunca lança; devolve
// só contagens. O token existe só em memória, dentro de uma iteração.

import { decideCompletion } from "./retry_policy.ts";
import { RenderError, renderTemplateMessage } from "./render.ts";
import type { MessageType } from "../scheduler/decision.ts";
import type {
  CompletionInput,
  DispatchStore,
  DispatchSummary,
  TemplateConfig,
  WhatsappProvider,
} from "./types.ts";

export interface DispatchDeps {
  store: DispatchStore;
  provider: WhatsappProvider;
  templates: TemplateConfig;
  now: () => Date;
  limit?: number;
  leaseSeconds?: number;
  log?: (event: string, data: Record<string, unknown>) => void;
}

function defaultLog(event: string, data: Record<string, unknown>) {
  console.log(JSON.stringify({ event, ...data }));
}

function emptySummary(): DispatchSummary {
  return { claimed: 0, sent: 0, retried: 0, failed: 0, unknownOutcome: 0, cancelled: 0, deferred: 0, leaseLost: 0, errors: 0 };
}

/** Tipos com template configurado: os demais nem são reservados. */
export function configuredTypes(templates: TemplateConfig): MessageType[] {
  return (Object.keys(templates.names) as MessageType[]).filter((t) => Boolean(templates.names[t]));
}

export async function dispatchPendingWhatsappMessages(deps: DispatchDeps): Promise<DispatchSummary> {
  const log = deps.log ?? defaultLog;
  const summary = emptySummary();
  const types = configuredTypes(deps.templates);
  if (types.length === 0) return summary;

  let claimed;
  try {
    claimed = await deps.store.claim({
      limit: deps.limit ?? 25,
      leaseSeconds: deps.leaseSeconds ?? 300,
      reminderTypes: types,
    });
  } catch {
    log("whatsapp_dispatch_claim_failed", {});
    summary.errors++;
    return summary;
  }
  summary.claimed = claimed.length;

  for (const item of claimed) {
    let prepared;
    try {
      prepared = await deps.store.prepare(item.messageId, item.leaseToken);
    } catch {
      // Lease continua; sem send_started_at, a mensagem volta à fila quando vencer.
      log("whatsapp_dispatch_prepare_failed", { messageId: item.messageId });
      summary.errors++;
      continue;
    }
    if (prepared.kind === "cancelled") {
      summary.cancelled++;
      continue;
    }
    if (prepared.kind === "deferred") {
      summary.deferred++;
      continue;
    }
    if (prepared.kind === "lease_lost") {
      summary.leaseLost++;
      continue;
    }

    const send = prepared.send;
    let completion: CompletionInput;
    try {
      const { templateName, message } = renderTemplateMessage(send, deps.templates, deps.now());
      const result = await deps.provider.sendTemplate({
        phoneNumberId: send.phoneNumberId,
        accessToken: send.accessToken,
        message,
      });
      completion = decideCompletion(result, send.attemptCount, templateName);
    } catch (error) {
      // Falha antes de chamar a Meta (render) ou exceção inesperada do provedor.
      const code = error instanceof RenderError ? error.code : "dispatch_exception";
      completion = { result: "failed", templateName: null, error: { code } };
    }

    // Gravar o resultado é crítico depois de um envio aceito (o wamid liga a
    // resposta da paciente à consulta): 1 nova tentativa se a 1ª falhar.
    let written: "ok" | "lease_lost" | null = null;
    for (let attempt = 0; attempt < 2 && written === null; attempt++) {
      try {
        written = await deps.store.complete(item.messageId, item.leaseToken, completion);
      } catch {
        written = null;
      }
    }
    if (written === null) {
      log("whatsapp_dispatch_complete_failed", { messageId: item.messageId, result: completion.result });
      summary.errors++;
      continue;
    }
    if (written === "lease_lost") {
      summary.leaseLost++;
      continue;
    }

    if (completion.result === "sent") summary.sent++;
    else if (completion.result === "retry") summary.retried++;
    else if (completion.error.code === "send_outcome_unknown") summary.unknownOutcome++;
    else summary.failed++;
  }

  return summary;
}
