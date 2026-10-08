import { test } from "node:test";
import assert from "node:assert/strict";
import { formatDayMonth, RenderError, renderTemplateMessage } from "./render.ts";
import type { PreparedSend, TemplateConfig } from "./types.ts";

const templates: TemplateConfig = {
  languageCode: "pt_BR",
  names: {
    appointment_confirmation: "la_pelve_agendamento",
    appointment_12h: "la_pelve_confirmacao",
    appointment_rescheduled: "la_pelve_remarcacao",
  },
};

// 2026-10-30 08:00 em São Paulo = 11:00 UTC. "Agora" = 29/10 20:00 SP.
const NOW = new Date("2026-10-29T23:00:00Z");

function send(overrides: Partial<PreparedSend> = {}): PreparedSend {
  return {
    reminderType: "appointment_12h",
    attemptCount: 1,
    destinationPhoneE164: "+5562911110001",
    patientFirstName: "Camila",
    appointmentDate: "2026-10-30",
    appointmentTime: "08:00",
    timeZone: "America/Sao_Paulo",
    phoneNumberId: "123456789012345",
    accessToken: "tok_teste_render_000000000000",
    ...overrides,
  };
}

test("solicitação de confirmação (12h): nome, data dd/MM, hora e botão com o payload do inbound", () => {
  const { templateName, message } = renderTemplateMessage(send(), templates, NOW);
  assert.equal(templateName, "la_pelve_confirmacao");
  assert.deepEqual(message, {
    messaging_product: "whatsapp",
    recipient_type: "individual",
    to: "5562911110001",
    type: "template",
    template: {
      name: "la_pelve_confirmacao",
      language: { code: "pt_BR" },
      components: [
        {
          type: "body",
          parameters: [
            { type: "text", text: "Camila" },
            { type: "text", text: "30/10" },
            { type: "text", text: "08:00" },
          ],
        },
        {
          type: "button",
          sub_type: "quick_reply",
          index: "0",
          parameters: [{ type: "payload", payload: "LA_PELVE_CONFIRM_APPOINTMENT" }],
        },
      ],
    },
  });
});

test("aviso de agendamento e de remarcação: data curta, sem botão", () => {
  for (const [type, name] of [
    ["appointment_confirmation", "la_pelve_agendamento"],
    ["appointment_rescheduled", "la_pelve_remarcacao"],
  ] as const) {
    const { message } = renderTemplateMessage(send({ reminderType: type }), templates, NOW);
    assert.equal(message.template.name, name);
    assert.equal(message.template.components.length, 1);
    assert.deepEqual(message.template.components[0].parameters, [
      { type: "text", text: "Camila" },
      { type: "text", text: "30/10" },
      { type: "text", text: "08:00" },
    ]);
  }
});

/** {{2}} do appointment_12h para uma consulta em `date` (`time` local), com "agora" = `now`. */
function dayParam12h(date: string, now: Date, time = "08:00", timeZone = "America/Sao_Paulo"): string {
  const { message } = renderTemplateMessage(
    send({ appointmentDate: date, appointmentTime: time, timeZone }),
    templates,
    now,
  );
  return (message.template.components[0].parameters as Array<{ text: string }>)[1].text;
}

test("12h: {{2}} é sempre dd/MM, nunca hoje/amanhã", () => {
  // NOW = 29/10 20:00 em São Paulo.
  assert.equal(dayParam12h("2026-10-29", NOW, "21:30"), "29/10", "consulta de hoje");
  assert.equal(dayParam12h("2026-10-30", NOW), "30/10", "consulta de amanhã");
  assert.equal(dayParam12h("2026-11-08", NOW, "14:30"), "08/11", "data mais distante");
});

test("12h: virada de mês e de ano continuam dd/MM, sem ano", () => {
  const endOfMonth = new Date("2026-10-31T23:00:00Z"); // 31/10 20:00 SP
  assert.equal(dayParam12h("2026-11-01", endOfMonth), "01/11");
  const newYearsEve = new Date("2026-12-31T23:00:00Z"); // 31/12 20:00 SP
  assert.equal(dayParam12h("2027-01-01", newYearsEve), "01/01");
  assert.equal(dayParam12h("2026-12-31", newYearsEve, "23:30"), "31/12");
});

test("12h: perto da meia-noite, a data é o dia local da consulta, não o dia em UTC", () => {
  // Consulta 29/10 23:30 em São Paulo = 30/10 02:30 UTC: continua 29/10.
  const evening = new Date("2026-10-29T22:00:00Z"); // 29/10 19:00 SP
  assert.equal(dayParam12h("2026-10-29", evening, "23:30"), "29/10");
  // Consulta 30/10 00:30 em São Paulo = 30/10 03:30 UTC: 30/10.
  assert.equal(dayParam12h("2026-10-30", evening, "00:30"), "30/10");
  // "Agora" já é 30/10 em UTC (01:00 UTC) mas ainda 29/10 22:00 em SP:
  // a consulta de 30/10 08:00 continua "30/10" (não depende do relógio).
  const lateNight = new Date("2026-10-30T01:00:00Z");
  assert.equal(dayParam12h("2026-10-30", lateNight), "30/10");
  // Fuso a leste de UTC: 30/10 00:30 em Tóquio = 29/10 15:30 UTC: 30/10.
  assert.equal(dayParam12h("2026-10-30", NOW, "00:30", "Asia/Tokyo"), "30/10");
});

test("12h: {{1}} primeiro nome, {{3}} HH:mm e botão inalterados", () => {
  const { message } = renderTemplateMessage(
    send({ patientFirstName: "Camila", appointmentDate: "2026-11-08", appointmentTime: "14:30" }),
    templates,
    NOW,
  );
  const [body, button] = message.template.components;
  assert.deepEqual(body.parameters, [
    { type: "text", text: "Camila" },
    { type: "text", text: "08/11" },
    { type: "text", text: "14:30" },
  ]);
  assert.deepEqual(button, {
    type: "button",
    sub_type: "quick_reply",
    index: "0",
    parameters: [{ type: "payload", payload: "LA_PELVE_CONFIRM_APPOINTMENT" }],
  });
  assert.equal(message.template.components.length, 2);
});

test("formatDayMonth: só reformata a data civil, sem Date/UTC", () => {
  assert.equal(formatDayMonth("2026-10-30"), "30/10");
  assert.equal(formatDayMonth("2027-01-01"), "01/01");
  assert.equal(formatDayMonth("2026-02-28"), "28/02");
});

test("agendamento e remarcação mantêm o formato anterior (ano só fora do ano corrente)", () => {
  for (const type of ["appointment_confirmation", "appointment_rescheduled"] as const) {
    const newYearsEve = new Date("2026-12-31T23:00:00Z");
    const { message } = renderTemplateMessage(
      send({ reminderType: type, appointmentDate: "2027-01-15" }),
      templates,
      newYearsEve,
    );
    assert.equal((message.template.components[0].parameters as Array<{ text: string }>)[1].text, "15/01/2027");
    assert.equal(message.template.components.length, 1);
  }
});

test("payload só com dados administrativos (nome, dia, hora, telefone de destino)", () => {
  const serialized = JSON.stringify(renderTemplateMessage(send(), templates, NOW).message);
  assert.ok(!serialized.includes("tok_teste"), "token nunca no payload");
  for (const forbidden of ["anamnese", "diagn", "evolu", "queixa"]) {
    assert.ok(!serialized.toLowerCase().includes(forbidden));
  }
});

test("tipo sem template configurado -> RenderError (nunca inventa template)", () => {
  assert.throws(
    () => renderTemplateMessage(send(), { languageCode: "pt_BR", names: {} }, NOW),
    (e: unknown) => e instanceof RenderError && e.code === "template_not_configured",
  );
});

test("entrada malformada -> RenderError", () => {
  for (const bad of [{ appointmentDate: "30/10/2026" }, { appointmentTime: "8h" }, { destinationPhoneE164: "62999" }]) {
    assert.throws(() => renderTemplateMessage(send(bad), templates, NOW), RenderError);
  }
});

test("nome vazio usa saudação neutra", () => {
  const { message } = renderTemplateMessage(send({ patientFirstName: "  " }), templates, NOW);
  assert.deepEqual((message.template.components[0].parameters as unknown[])[0], { type: "text", text: "tudo bem" });
});
