// Extração DEFENSIVA das mensagens recebidas de um payload de webhook da
// WhatsApp Cloud API. Pura: nunca lança, nunca loga. Qualquer campo
// essencial ausente ou com formato inesperado faz a mensagem ser ignorada
// (contada), sem derrubar as demais.
//
// Formato (Meta): body.entry[].changes[] com field 'messages' e
// value = { metadata: { phone_number_id }, messages?: [...], statuses?: [...] }.

import type { InboundMessage, InboundMessageType, ParsedWebhook } from "./types.ts";

const WA_ID_RE = /^[1-9][0-9]{7,14}$/;
const UNIX_SECONDS_RE = /^[0-9]{1,12}$/;
const MAX_ID_LENGTH = 256;
const MAX_TEXT_LENGTH = 1024;

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

function asArray(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}

function asId(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length > 0 && trimmed.length <= MAX_ID_LENGTH ? trimmed : null;
}

function asText(value: unknown): string | null {
  return typeof value === "string" && value.length <= MAX_TEXT_LENGTH ? value : null;
}

function toIsoFromUnixSeconds(value: unknown): string | null {
  const raw = typeof value === "number" ? String(value) : value;
  if (typeof raw !== "string" || !UNIX_SECONDS_RE.test(raw)) return null;
  const date = new Date(Number(raw) * 1000);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

/** Texto e payload, por tipo. null = tipo que não interessa (áudio, imagem, reação...). */
function readContent(
  msg: Record<string, unknown>,
): { type: InboundMessageType; text: string | null; buttonPayload: string | null } | null {
  switch (msg.type) {
    case "text": {
      const text = asText(asRecord(msg.text)?.body);
      return text === null ? null : { type: "text", text, buttonPayload: null };
    }
    case "button": {
      const button = asRecord(msg.button);
      if (!button) return null;
      return { type: "button", text: asText(button.text), buttonPayload: asText(button.payload) };
    }
    case "interactive": {
      const interactive = asRecord(msg.interactive);
      if (interactive?.type !== "button_reply") return null;
      const reply = asRecord(interactive.button_reply);
      if (!reply) return null;
      return { type: "interactive", text: asText(reply.title), buttonPayload: asText(reply.id) };
    }
    default:
      return null;
  }
}

export function parseWebhookPayload(body: unknown): ParsedWebhook {
  const parsed: ParsedWebhook = { messages: [], ignoredStatuses: 0, ignoredMessages: 0 };

  for (const entry of asArray(asRecord(body)?.entry)) {
    for (const change of asArray(asRecord(entry)?.changes)) {
      const changeRecord = asRecord(change);
      if (!changeRecord) continue;
      if (changeRecord.field !== undefined && changeRecord.field !== "messages") continue;
      const value = asRecord(changeRecord.value);
      if (!value) continue;

      parsed.ignoredStatuses += asArray(value.statuses).length;

      const rawMessages = asArray(value.messages);
      const phoneNumberId = asId(asRecord(value.metadata)?.phone_number_id);

      for (const raw of rawMessages) {
        const msg = asRecord(raw);
        const wamid = asId(msg?.id);
        const fromWaId = typeof msg?.from === "string" && WA_ID_RE.test(msg.from) ? msg.from : null;
        const receivedAt = toIsoFromUnixSeconds(msg?.timestamp);
        const content = msg ? readContent(msg) : null;
        if (!msg || !wamid || !phoneNumberId || !fromWaId || !receivedAt || !content) {
          parsed.ignoredMessages++;
          continue;
        }
        parsed.messages.push({
          wamid,
          phoneNumberId,
          fromWaId,
          receivedAt,
          type: content.type,
          text: content.text,
          buttonPayload: content.buttonPayload,
          contextWamid: asId(asRecord(msg.context)?.id),
        });
      }
    }
  }
  return parsed;
}
