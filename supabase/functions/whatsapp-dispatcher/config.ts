// Configuração do dispatcher, lida de variáveis de ambiente (secrets da
// Edge Function). PURO: recebe um getter, para ser testável em Node.
//
// Obrigatórias:
//   WHATSAPP_DISPATCHER_TOKEN      segredo que o cron envia em Authorization: Bearer
//   WHATSAPP_GRAPH_API_VERSION     ex.: v23.0 (sem default: o projeto ainda não fixou)
//   WHATSAPP_TEMPLATE_LANGUAGE     ex.: pt_BR
// Opcionais (tipo sem template não é enviado; fica na fila):
//   WHATSAPP_TEMPLATE_APPOINTMENT_CONFIRMATION
//   WHATSAPP_TEMPLATE_APPOINTMENT_12H
//   WHATSAPP_TEMPLATE_APPOINTMENT_RESCHEDULED
//
// Nenhuma credencial da Meta aqui: o token de cada profissional fica no
// Vault (migration 0026).

import { isValidGraphApiVersion } from "../_shared/dispatch/meta_provider.ts";
import type { TemplateConfig } from "../_shared/dispatch/types.ts";

const TEMPLATE_NAME_RE = /^[a-z0-9_]{1,512}$/;
const LANGUAGE_RE = /^[a-z]{2,3}(_[A-Z]{2})?$/;

export interface DispatcherConfig {
  dispatcherToken: string;
  graphApiVersion: string;
  templates: TemplateConfig;
}

export type ConfigResult = { ok: true; config: DispatcherConfig } | { ok: false; missing: string[] };

export function readDispatcherConfig(env: (name: string) => string | undefined): ConfigResult {
  const problems: string[] = [];
  const dispatcherToken = env("WHATSAPP_DISPATCHER_TOKEN") ?? "";
  if (dispatcherToken.length < 32) problems.push("WHATSAPP_DISPATCHER_TOKEN");
  const graphApiVersion = env("WHATSAPP_GRAPH_API_VERSION");
  if (!isValidGraphApiVersion(graphApiVersion)) problems.push("WHATSAPP_GRAPH_API_VERSION");
  const languageCode = env("WHATSAPP_TEMPLATE_LANGUAGE") ?? "";
  if (!LANGUAGE_RE.test(languageCode)) problems.push("WHATSAPP_TEMPLATE_LANGUAGE");

  const names: TemplateConfig["names"] = {};
  const templateVars = {
    appointment_confirmation: "WHATSAPP_TEMPLATE_APPOINTMENT_CONFIRMATION",
    appointment_12h: "WHATSAPP_TEMPLATE_APPOINTMENT_12H",
    appointment_rescheduled: "WHATSAPP_TEMPLATE_APPOINTMENT_RESCHEDULED",
  } as const;
  for (const [type, variable] of Object.entries(templateVars)) {
    const value = env(variable);
    if (value === undefined || value === "") continue;
    if (!TEMPLATE_NAME_RE.test(value)) problems.push(variable);
    else names[type as keyof typeof templateVars] = value;
  }

  if (problems.length > 0) return { ok: false, missing: problems };
  return {
    ok: true,
    config: { dispatcherToken, graphApiVersion: graphApiVersion!, templates: { names, languageCode } },
  };
}
