// Configuração do onboarding (Embedded Signup), lida de variáveis de ambiente
// (secrets da Edge Function). PURO: recebe um getter, testável em Node.
//
// Sem TODAS as obrigatórias a conexão fica DESLIGADA ("not_configured") e o
// app mostra a tela segura "Integração em preparação" -- nunca simula sucesso.
//
//   WHATSAPP_SELF_CONNECT_ENABLED   "true" liga o fluxo (chave geral)
//   META_APP_ID                     id do app Meta (público)
//   META_ES_CONFIG_ID               id da configuração Embedded Signup v4
//                                   (Facebook Login for Business)
//   WHATSAPP_APP_SECRET             App Secret (já usado pelo webhook); só aqui
//   WHATSAPP_GRAPH_API_VERSION      ex.: v25.0
//   WHATSAPP_TEMPLATE_LANGUAGE      ex.: pt_BR
//   WHATSAPP_CONNECT_PAGE_URL       página HTTPS de onboarding (domínio já
//                                   cadastrado em "Allowed domains" na Meta)
// Opcionais (nomes dos templates; default = nomes aprovados na WABA de teste):
//   WHATSAPP_TEMPLATE_APPOINTMENT_CONFIRMATION, WHATSAPP_TEMPLATE_APPOINTMENT_12H

import { isValidGraphApiVersion } from "../_shared/dispatch/meta_provider.ts";

const LANGUAGE_RE = /^[a-z]{2,3}(_[A-Z]{2})?$/;
const TEMPLATE_NAME_RE = /^[a-z0-9_]{1,512}$/;
const NUMERIC_ID_RE = /^\d{5,32}$/;

export interface ConnectConfig {
  appId: string;
  configId: string;
  appSecret: string;
  graphApiVersion: string;
  languageCode: string;
  connectPageUrl: string;
  confirmationTemplate: string;
  reminderTemplate: string;
}

export type ConnectConfigResult =
  | { enabled: true; config: ConnectConfig }
  | { enabled: false; missing: string[] };

export function readConnectConfig(env: (name: string) => string | undefined): ConnectConfigResult {
  if (env("WHATSAPP_SELF_CONNECT_ENABLED") !== "true") {
    return { enabled: false, missing: ["WHATSAPP_SELF_CONNECT_ENABLED"] };
  }
  const missing: string[] = [];
  const appId = env("META_APP_ID") ?? "";
  if (!NUMERIC_ID_RE.test(appId)) missing.push("META_APP_ID");
  const configId = env("META_ES_CONFIG_ID") ?? "";
  if (!NUMERIC_ID_RE.test(configId)) missing.push("META_ES_CONFIG_ID");
  const appSecret = env("WHATSAPP_APP_SECRET") ?? "";
  if (appSecret.length < 16) missing.push("WHATSAPP_APP_SECRET");
  const graphApiVersion = env("WHATSAPP_GRAPH_API_VERSION");
  if (!isValidGraphApiVersion(graphApiVersion)) missing.push("WHATSAPP_GRAPH_API_VERSION");
  const languageCode = env("WHATSAPP_TEMPLATE_LANGUAGE") ?? "";
  if (!LANGUAGE_RE.test(languageCode)) missing.push("WHATSAPP_TEMPLATE_LANGUAGE");
  const connectPageUrl = env("WHATSAPP_CONNECT_PAGE_URL") ?? "";
  if (!isHttpsUrl(connectPageUrl)) missing.push("WHATSAPP_CONNECT_PAGE_URL");
  const confirmationTemplate = env("WHATSAPP_TEMPLATE_APPOINTMENT_CONFIRMATION") || "appointment_confirmation";
  const reminderTemplate = env("WHATSAPP_TEMPLATE_APPOINTMENT_12H") || "appointment_12h";
  if (!TEMPLATE_NAME_RE.test(confirmationTemplate)) missing.push("WHATSAPP_TEMPLATE_APPOINTMENT_CONFIRMATION");
  if (!TEMPLATE_NAME_RE.test(reminderTemplate)) missing.push("WHATSAPP_TEMPLATE_APPOINTMENT_12H");
  if (missing.length > 0) return { enabled: false, missing };
  return {
    enabled: true,
    config: {
      appId,
      configId,
      appSecret,
      graphApiVersion: graphApiVersion!,
      languageCode,
      connectPageUrl,
      confirmationTemplate,
      reminderTemplate,
    },
  };
}

function isHttpsUrl(value: string): boolean {
  try {
    const url = new URL(value);
    return url.protocol === "https:" && !url.username && !url.password;
  } catch {
    return false;
  }
}
