// Eventos message_template_status_update do webhook da WABA. PURO e
// defensivo: nunca lança, nunca loga. Extrai WABA (entry.id), nome, idioma e
// evento do template; descarta reason/other_info/rejection_info (texto livre).
//
// Formato (documentação da Meta): entry[] = { id: <WABA_ID>, time,
// changes: [{ field: "message_template_status_update", value: { event,
// message_template_id, message_template_name, message_template_language,
// reason, ... } }] }.
// Eventos: APPROVED, ARCHIVED, UNARCHIVED, DELETED, DISABLED, FLAGGED,
// IN_APPEAL, LIMIT_EXCEEDED, LOCKED, PAUSED, PENDING, REINSTATED,
// PENDING_DELETION, REJECTED.

export interface TemplateStatusEvent {
  wabaId: string;
  name: string;
  language: string;
  event: string;
  /** ISO 8601 UTC de entry.time; null quando ausente (o banco usa now()). */
  occurredAt: string | null;
}

const WABA_ID_RE = /^[0-9]{5,32}$/;
const NAME_RE = /^[a-z0-9_]{1,512}$/;
const LANGUAGE_RE = /^[a-z]{2,3}(_[A-Z]{2})?$/;
const EVENT_RE = /^[A-Z_]{3,32}$/;
const UNIX_SECONDS_RE = /^[0-9]{1,12}$/;

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

function isoFromUnix(value: unknown): string | null {
  const raw = typeof value === "number" ? String(value) : value;
  if (typeof raw !== "string" || !UNIX_SECONDS_RE.test(raw)) return null;
  const date = new Date(Number(raw) * 1000);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

export function parseTemplateStatusUpdates(body: unknown): TemplateStatusEvent[] {
  const events: TemplateStatusEvent[] = [];
  const entries = asRecord(body)?.entry;
  if (!Array.isArray(entries)) return events;
  for (const entry of entries) {
    const entryRecord = asRecord(entry);
    const wabaId = String(entryRecord?.id ?? "");
    const changes = entryRecord?.changes;
    if (!WABA_ID_RE.test(wabaId) || !Array.isArray(changes)) continue;
    for (const change of changes) {
      const changeRecord = asRecord(change);
      if (changeRecord?.field !== "message_template_status_update") continue;
      const value = asRecord(changeRecord.value);
      const name = value?.message_template_name;
      const language = value?.message_template_language;
      const event = value?.event;
      if (
        typeof name !== "string" || !NAME_RE.test(name) ||
        typeof language !== "string" || !LANGUAGE_RE.test(language) ||
        typeof event !== "string" || !EVENT_RE.test(event)
      ) {
        continue;
      }
      events.push({ wabaId, name, language, event, occurredAt: isoFromUnix(entryRecord?.time) });
    }
  }
  return events;
}
