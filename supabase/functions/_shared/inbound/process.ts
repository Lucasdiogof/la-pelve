// Orquestra um webhook já autenticado: extrai as mensagens, descarta o que
// não é confirmação inequívoca e manda cada confirmação para a porta (que
// decide tudo numa transação no banco). Nunca lança; devolve só contagens.

import { isConfirmationReply } from "./confirmation_intent.ts";
import { parseWebhookPayload } from "./parse_webhook.ts";
import { senderE164Candidates } from "./phone.ts";
import type { ConfirmationReplyPort, InboundSummary } from "./types.ts";

export async function processInboundWebhook(
  body: unknown,
  port: ConfirmationReplyPort,
): Promise<InboundSummary> {
  const parsed = parseWebhookPayload(body);
  const summary: InboundSummary = {
    messages: parsed.messages.length,
    ignoredStatuses: parsed.ignoredStatuses,
    ignoredMessages: parsed.ignoredMessages,
    notConfirmation: 0,
    results: {},
    errors: 0,
  };

  // Sequencial, na ordem do payload: duas respostas da mesma paciente no
  // mesmo webhook são decididas uma depois da outra.
  for (const message of parsed.messages) {
    if (!isConfirmationReply(message)) {
      summary.notConfirmation++;
      continue;
    }
    const fromE164Candidates = senderE164Candidates(message.fromWaId);
    if (!fromE164Candidates) {
      summary.ignoredMessages++;
      continue;
    }
    const outcome = await port.processConfirmationReply({
      wamid: message.wamid,
      phoneNumberId: message.phoneNumberId,
      fromE164Candidates,
      receivedAt: message.receivedAt,
      messageType: message.type,
      contextWamid: message.contextWamid,
    });
    if (outcome.kind === "error") {
      summary.errors++;
    } else {
      summary.results[outcome.result] = (summary.results[outcome.result] ?? 0) + 1;
    }
  }
  return summary;
}
