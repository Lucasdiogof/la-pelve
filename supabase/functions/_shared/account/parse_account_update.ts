// Eventos `account_update` da Meta (webhook da WABA). PURO e defensivo: nunca
// lança, nunca loga. Só extrai o que a revogação/restrição precisa -- WABA,
// evento e um detalhe curto -- e ignora o resto (sem PHI).
//
// Formato (documentação da Meta): entry[].changes[] com field "account_update"
// e value = { event, waba_info?: { waba_id }, ban_info?: { waba_ban_state } }.
// O id da WABA vem de waba_info.waba_id; quando ausente (ex.: ACCOUNT_DELETED,
// DISABLED_UPDATE) usa-se entry[].id, que nos exemplos da Meta é a WABA.

export interface AccountEvent {
  wabaId: string;
  event: string;
  /** DISABLED_UPDATE: waba_ban_state (DISABLE | REINSTATE); senão vazio. */
  detail: string;
}

const WABA_ID_RE = /^[0-9]{5,32}$/;
const EVENT_RE = /^[A-Z_]{3,64}$/;

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

export function parseAccountUpdates(body: unknown): AccountEvent[] {
  const events: AccountEvent[] = [];
  const entries = asRecord(body)?.entry;
  if (!Array.isArray(entries)) return events;
  for (const entry of entries) {
    const entryRecord = asRecord(entry);
    const changes = entryRecord?.changes;
    if (!Array.isArray(changes)) continue;
    for (const change of changes) {
      const changeRecord = asRecord(change);
      if (changeRecord?.field !== "account_update") continue;
      const value = asRecord(changeRecord.value);
      const event = value?.event;
      if (typeof event !== "string" || !EVENT_RE.test(event)) continue;
      const fromInfo = asRecord(value?.waba_info)?.waba_id;
      const candidate = typeof fromInfo === "string" ? fromInfo : String(entryRecord?.id ?? "");
      if (!WABA_ID_RE.test(candidate)) continue;
      const state = asRecord(value?.ban_info)?.waba_ban_state;
      events.push({ wabaId: candidate, event, detail: typeof state === "string" ? state.slice(0, 32) : "" });
    }
  }
  return events;
}
