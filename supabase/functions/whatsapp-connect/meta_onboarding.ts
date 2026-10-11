// Chamadas à Graph API do onboarding (Embedded Signup). Só transporte e
// classificação: nenhuma regra de produto. `fetch` é injetado (testes mockam).
//
// - Troca do code: GET /oauth/access_token (contrato da documentação de Tech
//   Provider), servidor a servidor. Essa URL carrega o App Secret: nunca é
//   logada nem devolvida; erros viram só códigos próprios.
// - Demais chamadas: token só no header Authorization.
// - Listagens seguem `paging.next` (limite defensivo de páginas) e só aceitam
//   URLs HTTPS de graph.facebook.com.
// - Timeout explícito em toda chamada.

import { type ConnectConfig } from "./config.ts";

export type MetaFailure = "meta_unreachable" | "meta_rejected" | "meta_invalid_response";
/** `metaCode` = código numérico do erro da Meta (ex.: 133016), nunca texto livre. */
export type Fail = { ok: false; code: MetaFailure; metaCode?: number };
export type Ok<T> = { ok: true } & T;

export type TemplateState = "approved" | "pending" | "rejected" | "missing";
export interface TemplatesReport {
  confirmation: TemplateState;
  reminder: TemplateState;
}

export interface PhoneInfo {
  displayPhoneNumber: string | null;
  /** status do número na Cloud API; só "CONNECTED" envia/recebe. */
  status: string | null;
  /** null quando a Meta não informa o campo. */
  isPinEnabled: boolean | null;
}

export type AccountHealth = "available" | "limited" | "blocked" | "unknown";

/** Código de erro da Meta: limite de 10 registros por número em 72 h. */
export const META_REGISTRATION_RATE_LIMIT = 133016;

export interface MetaOnboarding {
  exchangeCode(code: string): Promise<Ok<{ accessToken: string }> | Fail>;
  getPhoneInfo(token: string, phoneNumberId: string): Promise<Ok<{ info: PhoneInfo }> | Fail>;
  phoneBelongsToWaba(token: string, wabaId: string, phoneNumberId: string): Promise<Ok<{ belongs: boolean }> | Fail>;
  subscribeApp(token: string, wabaId: string): Promise<Ok<unknown> | Fail>;
  unsubscribeApp(token: string, wabaId: string): Promise<Ok<unknown> | Fail>;
  registerPhone(token: string, phoneNumberId: string, pin: string): Promise<Ok<unknown> | Fail>;
  ensureTemplates(token: string, wabaId: string): Promise<Ok<{ report: TemplatesReport }> | Fail>;
  getAccountHealth(token: string, wabaId: string): Promise<Ok<{ health: AccountHealth }> | Fail>;
}

interface Options {
  config: ConnectConfig;
  fetchFn?: typeof fetch;
  timeoutMs?: number;
  /** Páginas no máximo por listagem (defesa contra laço infinito). */
  maxPages?: number;
}

/**
 * Textos idênticos aos aprovados na WABA de teste (inclui as DUAS quebras de
 * linha depois do emoji no aviso). Não alterar sem nova aprovação da Meta.
 */
export const CONFIRMATION_TEMPLATE_TEXT =
  "Olá, {{1}}! 👋\n\nSua consulta está agendada para o dia {{2}}, às {{3}}. Obrigado!";
export const REMINDER_TEMPLATE_TEXT =
  "Olá, {{1}}! Podemos confirmar seu atendimento no dia {{2}}, às {{3}}? Se sim, toque em Confirmar abaixo.";

export function templateDefinitions(config: ConnectConfig) {
  return [
    {
      key: "confirmation" as const,
      body: {
        name: config.confirmationTemplate,
        language: config.languageCode,
        category: "UTILITY",
        allow_category_change: false,
        components: [
          {
            type: "BODY",
            text: CONFIRMATION_TEMPLATE_TEXT,
            example: { body_text: [["Maria", "15/10", "14:00"]] },
          },
        ],
      },
    },
    {
      key: "reminder" as const,
      body: {
        name: config.reminderTemplate,
        language: config.languageCode,
        category: "UTILITY",
        allow_category_change: false,
        components: [
          {
            type: "BODY",
            text: REMINDER_TEMPLATE_TEXT,
            example: { body_text: [["Maria", "15/10", "14:00"]] },
          },
          { type: "BUTTONS", buttons: [{ type: "QUICK_REPLY", text: "Confirmar" }] },
        ],
      },
    },
  ];
}

function stateOf(status: unknown): TemplateState {
  if (status === "APPROVED") return "approved";
  if (status === "REJECTED" || status === "DISABLED" || status === "PAUSED") return "rejected";
  return "pending";
}

const TOKEN_TEXT_RE = /^[A-Za-z0-9_\-.]{16,2048}$/;

export function createMetaOnboarding(options: Options): MetaOnboarding {
  const { config } = options;
  const fetchFn = options.fetchFn ?? fetch;
  const timeoutMs = options.timeoutMs ?? 10_000;
  const maxPages = options.maxPages ?? 20;
  const base = `https://graph.facebook.com/${config.graphApiVersion}`;

  async function request(
    method: "GET" | "POST" | "DELETE",
    url: string,
    init: { token?: string; json?: unknown } = {},
  ): Promise<{ ok: true; text: string } | Fail> {
    const headers: Record<string, string> = {};
    let body: string | undefined;
    if (init.token) headers.authorization = `Bearer ${init.token}`;
    if (init.json !== undefined) {
      headers["content-type"] = "application/json";
      body = JSON.stringify(init.json);
    }
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const response = await fetchFn(url, { method, headers, body, signal: controller.signal });
      const text = await response.text().catch(() => "");
      if (!response.ok) {
        let metaCode: number | undefined;
        try {
          const code = (JSON.parse(text) as { error?: { code?: unknown } })?.error?.code;
          if (typeof code === "number" && Number.isFinite(code)) metaCode = code;
        } catch {
          // corpo de erro ilegível: só o status HTTP importa
        }
        return { ok: false, code: "meta_rejected", metaCode };
      }
      return { ok: true, text };
    } catch {
      return { ok: false, code: "meta_unreachable" };
    } finally {
      clearTimeout(timer);
    }
  }

  async function call(
    method: "GET" | "POST" | "DELETE",
    path: string,
    init: { token?: string; json?: unknown } = {},
  ): Promise<{ ok: true; body: Record<string, unknown> } | Fail> {
    const result = await request(method, `${base}${path}`, init);
    if (!result.ok) return result;
    try {
      const parsed = JSON.parse(result.text);
      if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) throw new Error();
      return { ok: true, body: parsed as Record<string, unknown> };
    } catch {
      return { ok: false, code: "meta_invalid_response" };
    }
  }

  /** Percorre `data[]` seguindo `paging.next`; devolve todas as linhas (ou falha). */
  async function listAll(path: string, token: string): Promise<{ ok: true; rows: unknown[] } | Fail> {
    const rows: unknown[] = [];
    let url: string | null = `${base}${path}`;
    for (let page = 0; url && page < maxPages; page++) {
      const result = await request("GET", url, { token });
      if (!result.ok) return result;
      let body: Record<string, unknown>;
      try {
        body = JSON.parse(result.text) as Record<string, unknown>;
      } catch {
        return { ok: false, code: "meta_invalid_response" };
      }
      if (!Array.isArray(body.data)) return { ok: false, code: "meta_invalid_response" };
      rows.push(...body.data);
      const next = (body.paging as { next?: unknown } | undefined)?.next;
      url = null;
      if (typeof next === "string") {
        try {
          const parsed = new URL(next);
          if (parsed.protocol === "https:" && parsed.hostname === "graph.facebook.com") url = parsed.toString();
        } catch {
          // paging.next inválido: encerra a listagem
        }
      }
    }
    // Ainda havia página e o limite acabou: resultado incompleto não é confiável.
    if (url) return { ok: false, code: "meta_invalid_response" };
    return { ok: true, rows };
  }

  return {
    async exchangeCode(code) {
      const query = new URLSearchParams({
        client_id: config.appId,
        client_secret: config.appSecret,
        code,
      });
      const result = await request("GET", `${base}/oauth/access_token?${query.toString()}`);
      if (!result.ok) return { ok: false, code: result.code };
      // A Meta devolve JSON ({access_token}); a documentação também descreve texto puro.
      let token: unknown;
      try {
        token = (JSON.parse(result.text) as { access_token?: unknown })?.access_token;
      } catch {
        const trimmed = result.text.trim();
        token = TOKEN_TEXT_RE.test(trimmed) ? trimmed : undefined;
      }
      if (typeof token !== "string" || token.length < 16) return { ok: false, code: "meta_invalid_response" };
      return { ok: true, accessToken: token };
    },

    async getPhoneInfo(token, phoneNumberId) {
      const result = await call("GET", `/${phoneNumberId}?fields=display_phone_number,status,is_pin_enabled`, { token });
      if (!result.ok) return result;
      const b = result.body;
      return {
        ok: true,
        info: {
          displayPhoneNumber: typeof b.display_phone_number === "string" ? b.display_phone_number : null,
          status: typeof b.status === "string" ? b.status : null,
          isPinEnabled: typeof b.is_pin_enabled === "boolean" ? b.is_pin_enabled : null,
        },
      };
    },

    async phoneBelongsToWaba(token, wabaId, phoneNumberId) {
      const listed = await listAll(`/${wabaId}/phone_numbers?fields=id&limit=100`, token);
      if (!listed.ok) return listed;
      return { ok: true, belongs: listed.rows.some((row) => (row as { id?: unknown })?.id === phoneNumberId) };
    },

    async subscribeApp(token, wabaId) {
      const result = await call("POST", `/${wabaId}/subscribed_apps`, { token });
      if (!result.ok) return result;
      return result.body.success === true ? { ok: true } : { ok: false, code: "meta_rejected" };
    },

    async unsubscribeApp(token, wabaId) {
      const result = await call("DELETE", `/${wabaId}/subscribed_apps`, { token });
      return result.ok ? { ok: true } : result;
    },

    async registerPhone(token, phoneNumberId, pin) {
      const result = await call("POST", `/${phoneNumberId}/register`, {
        token,
        json: { messaging_product: "whatsapp", pin },
      });
      return result.ok ? { ok: true } : result;
    },

    async ensureTemplates(token, wabaId) {
      const report: TemplatesReport = { confirmation: "missing", reminder: "missing" };
      for (const def of templateDefinitions(config)) {
        // Filtra por nome (todas as línguas) e segue a paginação.
        const listed = await listAll(
          `/${wabaId}/message_templates?name=${encodeURIComponent(def.body.name)}&fields=name,language,status&limit=100`,
          token,
        );
        if (!listed.ok) return listed;
        const found = listed.rows.find((row) => {
          const r = row as { name?: unknown; language?: unknown };
          return r.name === def.body.name && r.language === def.body.language;
        }) as { status?: unknown } | undefined;
        if (found) {
          report[def.key] = stateOf(found.status);
          continue;
        }
        const created = await call("POST", `/${wabaId}/message_templates`, { token, json: def.body });
        report[def.key] = created.ok ? "pending" : "missing";
      }
      return { ok: true, report };
    },

    async getAccountHealth(token, wabaId) {
      const result = await call("GET", `/${wabaId}?fields=health_status`, { token });
      if (!result.ok) return result;
      const status = (result.body.health_status as { can_send_message?: unknown } | undefined)?.can_send_message;
      if (status === "AVAILABLE") return { ok: true, health: "available" };
      if (status === "LIMITED") return { ok: true, health: "limited" };
      if (status === "BLOCKED") return { ok: true, health: "blocked" };
      return { ok: true, health: "unknown" };
    },
  };
}
