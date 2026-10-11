// Chamadas à Graph API do onboarding (Embedded Signup). Só transporte e
// classificação: nenhuma regra de produto. `fetch` é injetado (testes mockam).
//
// - Token e App Secret só em corpo POST / header Authorization, nunca em URL
//   registrada nem em log. Resultados carregam apenas códigos próprios, jamais
//   texto livre ou corpo de erro da Meta.
// - Timeout explícito em toda chamada.

import { type ConnectConfig } from "./config.ts";

export type MetaFailure = "meta_unreachable" | "meta_rejected" | "meta_invalid_response";
export type Fail = { ok: false; code: MetaFailure };
export type Ok<T> = { ok: true } & T;

export type TemplateState = "approved" | "pending" | "rejected" | "missing";
export interface TemplatesReport {
  confirmation: TemplateState;
  reminder: TemplateState;
}

export interface MetaOnboarding {
  exchangeCode(code: string): Promise<Ok<{ accessToken: string }> | Fail>;
  getPhoneNumber(
    token: string,
    phoneNumberId: string,
  ): Promise<Ok<{ displayPhoneNumber: string | null }> | Fail>;
  phoneBelongsToWaba(token: string, wabaId: string, phoneNumberId: string): Promise<Ok<{ belongs: boolean }> | Fail>;
  subscribeApp(token: string, wabaId: string): Promise<Ok<unknown> | Fail>;
  unsubscribeApp(token: string, wabaId: string): Promise<Ok<unknown> | Fail>;
  registerPhone(token: string, phoneNumberId: string, pin: string): Promise<Ok<unknown> | Fail>;
  ensureTemplates(token: string, wabaId: string): Promise<Ok<{ report: TemplatesReport }> | Fail>;
}

interface Options {
  config: ConnectConfig;
  fetchFn?: typeof fetch;
  timeoutMs?: number;
}

/** Textos idênticos aos aprovados na WABA de teste (não alterar sem nova aprovação). */
export function templateDefinitions(config: ConnectConfig) {
  return [
    {
      key: "confirmation" as const,
      body: {
        name: config.confirmationTemplate,
        language: config.languageCode,
        category: "UTILITY",
        components: [
          {
            type: "BODY",
            text: "Olá, {{1}}! 👋\nSua consulta está agendada para o dia {{2}}, às {{3}}. Obrigado!",
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
        components: [
          {
            type: "BODY",
            text: "Olá, {{1}}! Podemos confirmar seu atendimento no dia {{2}}, às {{3}}? Se sim, toque em Confirmar abaixo.",
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

export function createMetaOnboarding(options: Options): MetaOnboarding {
  const { config } = options;
  const fetchFn = options.fetchFn ?? fetch;
  const timeoutMs = options.timeoutMs ?? 10_000;
  const base = `https://graph.facebook.com/${config.graphApiVersion}`;

  async function call(
    method: "GET" | "POST" | "DELETE",
    path: string,
    init: { token?: string; form?: Record<string, string>; json?: unknown } = {},
  ): Promise<{ ok: true; body: Record<string, unknown> } | Fail> {
    const headers: Record<string, string> = {};
    let body: string | undefined;
    if (init.token) headers.authorization = `Bearer ${init.token}`;
    if (init.form) {
      headers["content-type"] = "application/x-www-form-urlencoded";
      body = new URLSearchParams(init.form).toString();
    } else if (init.json !== undefined) {
      headers["content-type"] = "application/json";
      body = JSON.stringify(init.json);
    }
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const response = await fetchFn(`${base}${path}`, { method, headers, body, signal: controller.signal });
      if (!response.ok) return { ok: false, code: "meta_rejected" };
      let parsed: unknown;
      try {
        parsed = await response.json();
      } catch {
        return { ok: false, code: "meta_invalid_response" };
      }
      if (typeof parsed !== "object" || parsed === null) return { ok: false, code: "meta_invalid_response" };
      return { ok: true, body: parsed as Record<string, unknown> };
    } catch {
      return { ok: false, code: "meta_unreachable" };
    } finally {
      clearTimeout(timer);
    }
  }

  return {
    async exchangeCode(code) {
      const result = await call("POST", "/oauth/access_token", {
        form: { client_id: config.appId, client_secret: config.appSecret, code },
      });
      if (!result.ok) return result;
      const token = result.body.access_token;
      if (typeof token !== "string" || token.length < 16) return { ok: false, code: "meta_invalid_response" };
      return { ok: true, accessToken: token };
    },

    async getPhoneNumber(token, phoneNumberId) {
      const result = await call("GET", `/${phoneNumberId}?fields=display_phone_number`, { token });
      if (!result.ok) return result;
      const display = result.body.display_phone_number;
      return { ok: true, displayPhoneNumber: typeof display === "string" ? display : null };
    },

    async phoneBelongsToWaba(token, wabaId, phoneNumberId) {
      const result = await call("GET", `/${wabaId}/phone_numbers?fields=id&limit=100`, { token });
      if (!result.ok) return result;
      const data = result.body.data;
      if (!Array.isArray(data)) return { ok: false, code: "meta_invalid_response" };
      return { ok: true, belongs: data.some((row) => (row as { id?: unknown })?.id === phoneNumberId) };
    },

    async subscribeApp(token, wabaId) {
      const result = await call("POST", `/${wabaId}/subscribed_apps`, { token });
      return result.ok && result.body.success === true ? { ok: true } : result.ok ? { ok: false, code: "meta_rejected" } : result;
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
      const listed = await call("GET", `/${wabaId}/message_templates?fields=name,language,status&limit=200`, { token });
      if (!listed.ok) return listed;
      const rows = listed.body.data;
      if (!Array.isArray(rows)) return { ok: false, code: "meta_invalid_response" };
      const report: TemplatesReport = { confirmation: "missing", reminder: "missing" };
      for (const def of templateDefinitions(config)) {
        const found = rows.find((row) => {
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
  };
}
