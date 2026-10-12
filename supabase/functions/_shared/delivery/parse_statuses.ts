// Status de entrega (statuses[]) do webhook da Cloud API. PURO e defensivo:
// nunca lança, nunca loga. Extrai só wamid, status, instante, o número do
// profissional (metadata.phone_number_id) e o código numérico do erro.
// recipient_id (telefone), conversation, pricing e textos de erro são
// descartados aqui mesmo.
//
// Formato (Meta): entry[].changes[] com field "messages" e
// value = { metadata: { phone_number_id }, statuses: [{ id, status,
// timestamp, recipient_id, errors?: [{ code, ... }] }] }.

export type DeliveryStatusKind = "sent" | "delivered" | "read" | "failed";

export interface DeliveryStatus {
  phoneNumberId: string;
  wamid: string;
  status: DeliveryStatusKind;
  /** ISO 8601 UTC (statuses[].timestamp). */
  occurredAt: string;
  /** errors[0].code quando status = failed. */
  errorCode: number | null;
}

export interface ParsedStatuses {
  statuses: DeliveryStatus[];
  /** Status malformados ou de tipo que não interessa (ex.: played). */
  ignored: number;
}

const PHONE_NUMBER_ID_RE = /^[0-9]{5,32}$/;
const UNIX_SECONDS_RE = /^[0-9]{1,12}$/;
const KINDS = new Set<string>(["sent", "delivered", "read", "failed"]);
const MAX_WAMID = 256;

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

function asArray(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}

function isoFromUnix(value: unknown): string | null {
  const raw = typeof value === "number" ? String(value) : value;
  if (typeof raw !== "string" || !UNIX_SECONDS_RE.test(raw)) return null;
  const date = new Date(Number(raw) * 1000);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

export function parseStatuses(body: unknown): ParsedStatuses {
  const parsed: ParsedStatuses = { statuses: [], ignored: 0 };
  for (const entry of asArray(asRecord(body)?.entry)) {
    for (const change of asArray(asRecord(entry)?.changes)) {
      const changeRecord = asRecord(change);
      if (!changeRecord) continue;
      if (changeRecord.field !== undefined && changeRecord.field !== "messages") continue;
      const value = asRecord(changeRecord.value);
      if (!value) continue;
      const rawPhone = asRecord(value.metadata)?.phone_number_id;
      const phoneNumberId = typeof rawPhone === "string" && PHONE_NUMBER_ID_RE.test(rawPhone) ? rawPhone : null;
      for (const raw of asArray(value.statuses)) {
        const item = asRecord(raw);
        const wamid = typeof item?.id === "string" ? item.id.trim() : "";
        const status = typeof item?.status === "string" ? item.status : "";
        const occurredAt = isoFromUnix(item?.timestamp);
        if (!item || !phoneNumberId || !wamid || wamid.length > MAX_WAMID || !KINDS.has(status) || !occurredAt) {
          parsed.ignored++;
          continue;
        }
        const code = asRecord(asArray(item.errors)[0])?.code;
        parsed.statuses.push({
          phoneNumberId,
          wamid,
          status: status as DeliveryStatusKind,
          occurredAt,
          errorCode: status === "failed" && typeof code === "number" && Number.isInteger(code) ? code : null,
        });
      }
    }
  }
  return parsed;
}
