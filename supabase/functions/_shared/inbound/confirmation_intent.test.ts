// A. Classificação da resposta da paciente. Pura, sem I/O.

import { test } from "node:test";
import assert from "node:assert/strict";
import {
  CONFIRM_BUTTON_PAYLOAD,
  isConfirmationReply,
  isConfirmationText,
  normalizeReplyText,
} from "./confirmation_intent.ts";
import type { InboundMessage } from "./types.ts";

function message(overrides: Partial<InboundMessage> = {}): InboundMessage {
  return {
    wamid: "wamid.in.1",
    phoneNumberId: "pn-1",
    fromWaId: "5562911110001",
    receivedAt: "2026-10-08T12:00:00.000Z",
    type: "text",
    text: "sim",
    buttonPayload: null,
    contextWamid: null,
    ...overrides,
  };
}

for (const text of [
  "sim",
  "Sim",
  "SIM",
  "  sim  ",
  "sim.",
  "Sim!",
  "Sim, confirmo!",
  "sim confirmo",
  "Sim,   confirmo.",
  "confirmo",
  "Confirmo!",
  "confirmado",
  "Confirmado.",
  "pode confirmar",
  "Pode confirmar!",
]) {
  test(`confirma: ${JSON.stringify(text)}`, () => {
    assert.equal(isConfirmationText(text), true);
  });
}

for (const text of [
  "não",
  "Não",
  "nao",
  "não confirmo",
  "Não, confirmo depois",
  "talvez",
  "vou ver",
  "preciso remarcar",
  "sim, mas preciso remarcar",
  "sim?",
  "sim não",
  "simm",
  "ok",
  "👍",
  "",
  "   ",
  "Bom dia! Que horas é a consulta?",
  "confirmar",
]) {
  test(`NÃO confirma: ${JSON.stringify(text)}`, () => {
    assert.equal(isConfirmationText(text), false);
  });
}

test("normalização: trim, caixa, acentos e pontuação simples", () => {
  assert.equal(normalizeReplyText("  Sim, CONFIRMO!! "), "sim confirmo");
  assert.equal(normalizeReplyText("Confirmádo."), "confirmado");
  assert.equal(normalizeReplyText("NÃO"), "nao");
});

test("texto nulo não é confirmação", () => {
  assert.equal(isConfirmationText(null), false);
});

test("botão com o payload estruturado confirma, qualquer que seja o texto", () => {
  assert.equal(
    isConfirmationReply(message({ type: "button", text: "Confirmar", buttonPayload: CONFIRM_BUTTON_PAYLOAD })),
    true,
  );
});

test("botão sem payload próprio: a Meta repete o texto, que passa pela lista", () => {
  assert.equal(isConfirmationReply(message({ type: "button", text: "Sim, confirmo", buttonPayload: "Sim, confirmo" })), true);
  assert.equal(isConfirmationReply(message({ type: "button", text: "Remarcar", buttonPayload: "Remarcar" })), false);
});

test("resposta interativa (button_reply) com o id de confirmação confirma", () => {
  assert.equal(
    isConfirmationReply(message({ type: "interactive", text: "Confirmar", buttonPayload: CONFIRM_BUTTON_PAYLOAD })),
    true,
  );
  assert.equal(
    isConfirmationReply(message({ type: "interactive", text: "Cancelar", buttonPayload: "LA_PELVE_CANCEL" })),
    false,
  );
});

test("texto livre usa só a lista", () => {
  assert.equal(isConfirmationReply(message({ text: "Sim, confirmo!" })), true);
  assert.equal(isConfirmationReply(message({ text: "não confirmo" })), false);
  // payload de botão não vale para mensagem de texto
  assert.equal(isConfirmationReply(message({ text: "oi", buttonPayload: CONFIRM_BUTTON_PAYLOAD })), false);
});
