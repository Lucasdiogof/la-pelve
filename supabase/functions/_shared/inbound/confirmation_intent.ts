// Classifica se uma mensagem recebida é uma CONFIRMAÇÃO INEQUÍVOCA da
// consulta. Pura e deliberadamente conservadora: só a mensagem INTEIRA,
// depois de normalizada, igual a uma das frases aceitas conta. Qualquer
// outra coisa ("não", "não confirmo", "talvez", "preciso remarcar", texto
// livre) NÃO é confirmação e não altera nada.

import type { InboundMessage } from "./types.ts";

/**
 * Payload do botão de resposta rápida do template da solicitação de
 * confirmação. O envio (dispatch, etapa futura) deve mandar o botão com
 * este payload; a Meta devolve o valor em button.payload.
 */
export const CONFIRM_BUTTON_PAYLOAD = "LA_PELVE_CONFIRM_APPOINTMENT";

/** Frases aceitas, já na forma normalizada (ver normalizeReplyText). */
export const ACCEPTED_CONFIRMATION_REPLIES: ReadonlySet<string> = new Set([
  "sim",
  "sim confirmo",
  "confirmo",
  "confirmado",
  "pode confirmar",
]);

/**
 * trim + minúsculas + sem acentos + sem pontuação simples + espaços
 * colapsados. "  Sim, CONFIRMO!! " -> "sim confirmo". O "?" é mantido de
 * propósito: "sim?" é uma pergunta, não uma confirmação.
 */
export function normalizeReplyText(text: string): string {
  return text
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[.,!;:¡"'()\-]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function isConfirmationText(text: string | null): boolean {
  if (text === null) return false;
  return ACCEPTED_CONFIRMATION_REPLIES.has(normalizeReplyText(text));
}

/**
 * Botão (button / interactive): vale o payload estruturado; se o template
 * não definiu payload, a Meta repete o texto do botão, que passa pela mesma
 * lista de frases. Texto livre: só a lista.
 */
export function isConfirmationReply(message: InboundMessage): boolean {
  if (message.type === "button" || message.type === "interactive") {
    if (message.buttonPayload === CONFIRM_BUTTON_PAYLOAD) return true;
    return isConfirmationText(message.buttonPayload) || isConfirmationText(message.text);
  }
  return isConfirmationText(message.text);
}
