import { test } from "node:test";
import assert from "node:assert/strict";
import { senderE164Candidates } from "./phone.ts";

test("celular BR com o 9: só ele", () => {
  assert.deepEqual(senderE164Candidates("5562911110001"), ["+5562911110001"]);
});

test("celular BR sem o 9 (conta antiga no WhatsApp): também a forma com o 9", () => {
  assert.deepEqual(senderE164Candidates("556291110001"), ["+556291110001", "+5562991110001"]);
});

test("fixo BR (começa em 2-5) não ganha o 9", () => {
  assert.deepEqual(senderE164Candidates("556232221111"), ["+556232221111"]);
});

test("número de outro país: só ele", () => {
  assert.deepEqual(senderE164Candidates("14155550123"), ["+14155550123"]);
});

test("remetente inválido -> null", () => {
  for (const value of ["", "+5562911110001", "0562911110001", "abc", "1234567"]) {
    assert.equal(senderE164Candidates(value), null, value);
  }
});
