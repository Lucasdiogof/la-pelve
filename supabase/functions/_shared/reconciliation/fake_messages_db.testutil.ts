// Client Supabase FALSO com estado, só para testes (nunca toca rede nem
// produção). Imita apenas a forma dos métodos encadeados que o adapter de
// reconciliação usa:
//   from(t).update(patch).eq(c,v).eq(c,v).select(cols)
//   from(t).select(cols).eq(c,v).limit(n)
//
// Semântica relevante do Postgres reproduzida: o UPDATE aplica o patch SÓ
// nas linhas que casam com TODOS os filtros, avaliados no momento da
// execução (é isso que torna o WHERE status='scheduled' uma proteção real
// contra a corrida, e não uma checagem em memória). Se o adapter esquecesse
// o filtro de status, o fake cancelaria uma linha processing -- e os testes
// de corrida falhariam.

export interface FakeMessageRow {
  id: string;
  status: string;
  fisioterapeuta_id: string;
  patient_id: string;
  appointment_id: string;
  reminder_type: string;
  schedule_revision: number;
  scheduled_for: string;
  destination_phone_e164: string;
  consent_id: string;
  wamid: string | null;
  error: unknown;
  sent_at: string | null;
  failed_at: string | null;
}

export const FAKE_PHONE = "+5562911111111";

export function makeRow(id: string, status = "scheduled", overrides: Partial<FakeMessageRow> = {}): FakeMessageRow {
  return {
    id,
    status,
    fisioterapeuta_id: "fisio-1",
    patient_id: "patient-1",
    appointment_id: `appt-${id}`,
    reminder_type: "appointment_confirmation",
    schedule_revision: 0,
    scheduled_for: "2026-10-10T17:00:00.000Z",
    destination_phone_e164: FAKE_PHONE,
    consent_id: `consent-${id}`,
    wamid: null,
    error: null,
    sent_at: null,
    failed_at: null,
    ...overrides,
  };
}

interface FakeResult {
  data: unknown;
  error: { code?: string; message?: string; details?: string } | null;
}

/** Texto bruto de erro com PII de propósito: nunca pode aparecer em outcome/log. */
export const RAW_DB_ERROR = {
  code: "57014",
  message: `canceling statement for row with ${FAKE_PHONE}`,
  details: "Failing row contains (consent-1, +5562911111111)",
};

export function fakeMessagesDb(
  initialRows: FakeMessageRow[],
  opts: {
    /** Roda ANTES do N-ésimo UPDATE (1-based): simula outro processo mudando a linha. */
    beforeUpdate?: (call: number, rows: FakeMessageRow[]) => void;
    /** Falha só no N-ésimo UPDATE. */
    updateFailOnCall?: { call: number; mode: "throw" | "error" };
    /** Resposta forçada do UPDATE (forma inesperada). */
    updateResult?: FakeResult;
    /** Falha só no N-ésimo SELECT. */
    selectFailOnCall?: { call: number; mode: "throw" | "error" };
    selectResult?: FakeResult;
  } = {},
) {
  const rows = initialRows.map((r) => ({ ...r }));
  const calls = { update: 0, select: 0 };
  const tables: string[] = [];
  const updates: Array<{ patch: Record<string, unknown>; filters: Array<[string, unknown]>; cols: string }> = [];
  const selects: Array<{ cols: string; filters: Array<[string, unknown]> }> = [];
  /** Campos que cada UPDATE realmente alterou, por linha. */
  const changedFields: string[][] = [];

  // deno-lint-ignore no-explicit-any
  const client: any = {
    from(table: string) {
      tables.push(table);
      return {
        update(patch: Record<string, unknown>) {
          const filters: Array<[string, unknown]> = [];
          const chain = {
            eq(col: string, val: unknown) {
              filters.push([col, val]);
              return chain;
            },
            select(cols: string) {
              calls.update++;
              updates.push({ patch, filters: [...filters], cols });
              opts.beforeUpdate?.(calls.update, rows);
              if (opts.updateFailOnCall?.call === calls.update) {
                if (opts.updateFailOnCall.mode === "throw") throw new Error("fetch failed (simulado)");
                return Promise.resolve({ data: null, error: RAW_DB_ERROR });
              }
              if (opts.updateResult) return Promise.resolve(opts.updateResult);
              const matched = rows.filter((r) =>
                filters.every(([c, v]) => (r as unknown as Record<string, unknown>)[c] === v)
              );
              for (const r of matched) {
                const rec = r as unknown as Record<string, unknown>;
                const changed: string[] = [];
                for (const [k, v] of Object.entries(patch)) {
                  if (rec[k] !== v) changed.push(k);
                  rec[k] = v;
                }
                changedFields.push(changed);
              }
              return Promise.resolve({ data: matched.map((r) => ({ id: r.id })), error: null });
            },
          };
          return chain;
        },
        select(cols: string) {
          const filters: Array<[string, unknown]> = [];
          const chain = {
            eq(col: string, val: unknown) {
              filters.push([col, val]);
              return chain;
            },
            limit(n: number) {
              calls.select++;
              selects.push({ cols, filters: [...filters] });
              if (opts.selectFailOnCall?.call === calls.select) {
                if (opts.selectFailOnCall.mode === "throw") throw new Error("fetch failed (simulado)");
                return Promise.resolve({ data: null, error: RAW_DB_ERROR });
              }
              if (opts.selectResult) return Promise.resolve(opts.selectResult);
              const found = rows
                .filter((r) => filters.every(([c, v]) => (r as unknown as Record<string, unknown>)[c] === v))
                .slice(0, n)
                .map((r) => ({ id: r.id }));
              return Promise.resolve({ data: found, error: null });
            },
          };
          return chain;
        },
      };
    },
  };

  return {
    client,
    rows,
    calls,
    tables,
    updates,
    selects,
    changedFields,
    byId: (id: string) => rows.find((r) => r.id === id),
  };
}
