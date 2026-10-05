import { test } from "node:test";
import assert from "node:assert/strict";
import {
  applySilencePostponement,
  isInSilentHours,
  zonedTimeToUtc,
} from "./timezone.ts";

test("zonedTimeToUtc: America/Sao_Paulo (UTC-3, sem DST) converte corretamente", () => {
  const d = zonedTimeToUtc(2026, 10, 10, 14, 0, 0, "America/Sao_Paulo");
  assert.equal(d.toISOString(), "2026-10-10T17:00:00.000Z");
});

test("zonedTimeToUtc: respeita DST de verdade (America/New_York), não um offset fixo", () => {
  // Em janeiro (horário padrão, UTC-5) e em julho (horário de verão, UTC-4),
  // o MESMO horário local de parede deve gerar instantes UTC diferentes —
  // só é possível acertar isso consultando a timezone IANA de verdade.
  const winter = zonedTimeToUtc(2026, 1, 15, 12, 0, 0, "America/New_York");
  const summer = zonedTimeToUtc(2026, 7, 15, 12, 0, 0, "America/New_York");
  assert.equal(winter.toISOString(), "2026-01-15T17:00:00.000Z"); // UTC-5
  assert.equal(summer.toISOString(), "2026-07-15T16:00:00.000Z"); // UTC-4 (DST)
});

test("isInSilentHours: 21:59 local não é silêncio", () => {
  const d = zonedTimeToUtc(2026, 10, 10, 21, 59, 0, "America/Sao_Paulo");
  assert.equal(isInSilentHours(d, "America/Sao_Paulo"), false);
});

test("isInSilentHours: 22:00 local é silêncio", () => {
  const d = zonedTimeToUtc(2026, 10, 10, 22, 0, 0, "America/Sao_Paulo");
  assert.equal(isInSilentHours(d, "America/Sao_Paulo"), true);
});

test("isInSilentHours: 06:59 local é silêncio", () => {
  const d = zonedTimeToUtc(2026, 10, 10, 6, 59, 0, "America/Sao_Paulo");
  assert.equal(isInSilentHours(d, "America/Sao_Paulo"), true);
});

test("isInSilentHours: 07:00 local não é silêncio", () => {
  const d = zonedTimeToUtc(2026, 10, 10, 7, 0, 0, "America/Sao_Paulo");
  assert.equal(isInSilentHours(d, "America/Sao_Paulo"), false);
});

test("applySilencePostponement: nominal 04:00 -> efetivo 07:00 do mesmo dia", () => {
  const nominal = zonedTimeToUtc(2026, 10, 10, 4, 0, 0, "America/Sao_Paulo");
  const effective = applySilencePostponement(nominal, "America/Sao_Paulo");
  assert.equal(effective.toISOString(), zonedTimeToUtc(2026, 10, 10, 7, 0, 0, "America/Sao_Paulo").toISOString());
});

test("applySilencePostponement: nominal 22:00 -> efetivo 07:00 do dia seguinte", () => {
  const nominal = zonedTimeToUtc(2026, 10, 10, 22, 0, 0, "America/Sao_Paulo");
  const effective = applySilencePostponement(nominal, "America/Sao_Paulo");
  assert.equal(effective.toISOString(), zonedTimeToUtc(2026, 10, 11, 7, 0, 0, "America/Sao_Paulo").toISOString());
});

test("applySilencePostponement: nominal fora do silêncio fica inalterado", () => {
  const nominal = zonedTimeToUtc(2026, 10, 10, 15, 0, 0, "America/Sao_Paulo");
  const effective = applySilencePostponement(nominal, "America/Sao_Paulo");
  assert.equal(effective.getTime(), nominal.getTime());
});

test("applySilencePostponement: postergação atravessa a virada do mês corretamente", () => {
  const nominal = zonedTimeToUtc(2026, 10, 31, 23, 0, 0, "America/Sao_Paulo");
  const effective = applySilencePostponement(nominal, "America/Sao_Paulo");
  assert.equal(effective.toISOString(), zonedTimeToUtc(2026, 11, 1, 7, 0, 0, "America/Sao_Paulo").toISOString());
});

test("applySilencePostponement: postergação atravessa a virada do ano corretamente", () => {
  const nominal = zonedTimeToUtc(2026, 12, 31, 23, 30, 0, "America/Sao_Paulo");
  const effective = applySilencePostponement(nominal, "America/Sao_Paulo");
  assert.equal(effective.toISOString(), zonedTimeToUtc(2027, 1, 1, 7, 0, 0, "America/Sao_Paulo").toISOString());
});
