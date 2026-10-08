// Monta o payload de TEMPLATE da Cloud API para 1 mensagem. Puro.
//
// Só dados administrativos: primeiro nome, dia e horário. Nada clínico. O
// corpo do texto vive no template aprovado na Meta; aqui vão só os
// parâmetros, então nenhuma cópia do corpo é guardada em lugar nenhum.
//
// Contrato dos templates (a criar/aprovar na Meta, idioma pt_BR):
//   appointment_confirmation (aviso de agendamento, informativo):
//     "Olá, {{1}}! Seu atendimento foi agendado para {{2}}, às {{3}}."
//       {{1}} primeiro nome  {{2}} data "30/10"  {{3}} hora "08:00"
//   appointment_12h (SOLICITAÇÃO DE CONFIRMAÇÃO):
//     "Olá, {{1}}! Podemos confirmar seu atendimento de {{2}}, às {{3}}?"
//       {{2}} "hoje" | "amanhã" | "30/10"
//       + botão de resposta rápida (índice 0), ex. "Sim, confirmo", com o
//         payload LA_PELVE_CONFIRM_APPOINTMENT enviado aqui -- é o que o
//         webhook (inbound, migration 0025) reconhece como confirmação.
//   appointment_rescheduled (aviso de remarcação, informativo):
//     "Olá, {{1}}! Seu atendimento foi remarcado para {{2}}, às {{3}}."

import { CONFIRM_BUTTON_PAYLOAD } from "../inbound/confirmation_intent.ts";
import type { MessageType } from "../scheduler/decision.ts";
import type { MetaTemplateMessage, PreparedSend, TemplateConfig } from "./types.ts";

const DATE_RE = /^(\d{4})-(\d{2})-(\d{2})$/;
const TIME_RE = /^\d{2}:\d{2}$/;
const E164_RE = /^\+[1-9][0-9]{7,14}$/;
const FALLBACK_NAME = "tudo bem";

export class RenderError extends Error {
  readonly code: "template_not_configured" | "invalid_render_input";

  constructor(code: "template_not_configured" | "invalid_render_input") {
    super(`render error: ${code}`);
    this.name = "RenderError";
    this.code = code;
  }
}

/** Data civil 'YYYY-MM-DD' de `instant` no fuso `timeZone`. */
function civilDate(instant: Date, timeZone: string): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(instant);
  const get = (type: string) => parts.find((p) => p.type === type)?.value ?? "";
  return `${get("year")}-${get("month")}-${get("day")}`;
}

function addDays(date: string, days: number): string {
  const [y, m, d] = date.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d + days)).toISOString().slice(0, 10);
}

/** "30/10"; com o ano quando não é o ano corrente ("15/01/2027"). */
export function formatShortDate(date: string, today: string): string {
  const [, y, m, d] = DATE_RE.exec(date)!;
  return y === today.slice(0, 4) ? `${d}/${m}` : `${d}/${m}/${y}`;
}

/** "hoje", "amanhã" ou a data curta, no fuso do profissional. */
export function relativeDayLabel(date: string, now: Date, timeZone: string): string {
  const today = civilDate(now, timeZone);
  if (date === today) return "hoje";
  if (date === addDays(today, 1)) return "amanhã";
  return formatShortDate(date, today);
}

function text(value: string) {
  return { type: "text", text: value };
}

export function renderTemplateMessage(
  send: PreparedSend,
  config: TemplateConfig,
  now: Date,
): { templateName: string; message: MetaTemplateMessage } {
  const templateName = config.names[send.reminderType];
  if (!templateName) throw new RenderError("template_not_configured");
  if (
    !DATE_RE.test(send.appointmentDate) ||
    !TIME_RE.test(send.appointmentTime) ||
    !E164_RE.test(send.destinationPhoneE164)
  ) {
    throw new RenderError("invalid_render_input");
  }

  const name = send.patientFirstName.trim() || FALLBACK_NAME;
  const today = civilDate(now, send.timeZone);
  const dayParam: Record<MessageType, string> = {
    appointment_confirmation: formatShortDate(send.appointmentDate, today),
    appointment_rescheduled: formatShortDate(send.appointmentDate, today),
    appointment_12h: relativeDayLabel(send.appointmentDate, now, send.timeZone),
  };

  const components: Array<Record<string, unknown>> = [
    {
      type: "body",
      parameters: [text(name), text(dayParam[send.reminderType]), text(send.appointmentTime)],
    },
  ];
  if (send.reminderType === "appointment_12h") {
    components.push({
      type: "button",
      sub_type: "quick_reply",
      index: "0",
      parameters: [{ type: "payload", payload: CONFIRM_BUTTON_PAYLOAD }],
    });
  }

  return {
    templateName,
    message: {
      messaging_product: "whatsapp",
      recipient_type: "individual",
      to: send.destinationPhoneE164.slice(1),
      type: "template",
      template: { name: templateName, language: { code: config.languageCode }, components },
    },
  };
}
