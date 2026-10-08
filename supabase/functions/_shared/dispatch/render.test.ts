import { test } from "node:test";
import assert from "node:assert/strict";
import { RenderError, relativeDayLabel, renderTemplateMessage } from "./render.ts";
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

test("solicitação de confirmação (12h): nome, dia relativo, hora e botão com o payload do inbound", () => {
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
            { type: "text", text: "amanhã" },
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

test("dia relativo no fuso do profissional, não em UTC", () => {
  // 30/10 01:00 UTC ainda é 29/10 22:00 em São Paulo.
  const lateNight = new Date("2026-10-30T01:00:00Z");
  assert.equal(relativeDayLabel("2026-10-29", lateNight, "America/Sao_Paulo"), "hoje");
  assert.equal(relativeDayLabel("2026-10-30", lateNight, "America/Sao_Paulo"), "amanhã");
  assert.equal(relativeDayLabel("2026-11-02", lateNight, "America/Sao_Paulo"), "02/11");
  assert.equal(relativeDayLabel("2027-01-15", lateNight, "America/Sao_Paulo"), "15/01/2027");
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
