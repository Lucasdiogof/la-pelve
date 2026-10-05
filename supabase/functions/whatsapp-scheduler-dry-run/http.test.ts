import { test } from "node:test";
import assert from "node:assert/strict";
import { isAuthorizedRequest, parseWindow } from "./http.ts";

// ---------------------------------------------------------------------
// Janela: from/to são OBRIGATÓRIOS (sem default) -- appointments.date é
// civil por profissional, não existe "data atual" universal derivável de
// UTC que sirva para todos.
// ---------------------------------------------------------------------

test("2: from ausente -> 400/erro claro", () => {
  const result = parseWindow(new URL("https://x/dry-run?to=2026-10-12"));
  assert.match(result.error!, /from é obrigatório/);
});

test("3: to ausente -> 400/erro claro", () => {
  const result = parseWindow(new URL("https://x/dry-run?from=2026-10-05"));
  assert.match(result.error!, /to é obrigatório/);
});

test("4: ambos ausentes -> erro (from é checado primeiro, mas nunca aceita a janela)", () => {
  const result = parseWindow(new URL("https://x/dry-run"));
  assert.ok(result.error);
  assert.equal(result.window, undefined);
});

test("5: from/to válidos (YYYY-MM-DD) -> aceito, sem nenhuma inferência de data", () => {
  const result = parseWindow(new URL("https://x/dry-run?from=2026-10-05&to=2026-10-12"));
  assert.equal(result.error, undefined);
  assert.equal(result.window!.fromDate, "2026-10-05");
  assert.equal(result.window!.toDate, "2026-10-12");
  assert.equal(result.window!.fisioterapeutaId, null);
});

test("from inválido -> erro, nunca aceito como filtro cru", () => {
  const result = parseWindow(new URL("https://x/dry-run?from=10-05-2026&to=2026-10-12"));
  assert.match(result.error!, /from inválido/);
});

test("from com SQL/texto arbitrário -> erro (nunca é usado como filtro cru)", () => {
  const result = parseWindow(new URL("https://x/dry-run?from=2026-10-05%20OR%201%3D1&to=2026-10-12"));
  assert.match(result.error!, /from inválido/);
});

test("to inválido -> erro", () => {
  const result = parseWindow(new URL("https://x/dry-run?from=2026-10-05&to=not-a-date"));
  assert.match(result.error!, /to inválido/);
});

test("6: from > to -> rejeita", () => {
  const result = parseWindow(new URL("https://x/dry-run?from=2026-10-10&to=2026-10-05"));
  assert.match(result.error!, /to não pode ser anterior a from/);
});

test("from == to -> aceito (janela de 1 dia)", () => {
  const result = parseWindow(new URL("https://x/dry-run?from=2026-10-10&to=2026-10-10"));
  assert.equal(result.error, undefined);
  assert.equal(result.window!.fromDate, "2026-10-10");
  assert.equal(result.window!.toDate, "2026-10-10");
});

test("7: exatamente 31 dias -> aceita", () => {
  const result = parseWindow(new URL("https://x/dry-run?from=2026-10-01&to=2026-11-01"));
  assert.equal(result.error, undefined);
});

test("8: 32 dias -> rejeita", () => {
  const result = parseWindow(new URL("https://x/dry-run?from=2026-10-01&to=2026-11-02"));
  assert.match(result.error!, /janela máxima é de 31 dias/);
});

test("fisioterapeuta_id ausente -> null (varre todos, só permitido pós-autenticação admin)", () => {
  const result = parseWindow(new URL("https://x/dry-run?from=2026-10-05&to=2026-10-12"));
  assert.equal(result.window!.fisioterapeutaId, null);
});

test("fisioterapeuta_id válido (UUID) -> aceito", () => {
  const result = parseWindow(
    new URL(
      "https://x/dry-run?from=2026-10-05&to=2026-10-12&fisioterapeuta_id=00000000-0000-4000-8000-000000000001",
    ),
  );
  assert.equal(result.error, undefined);
  assert.equal(result.window!.fisioterapeutaId, "00000000-0000-4000-8000-000000000001");
});

test("fisioterapeuta_id inválido (não-UUID) -> erro, nunca passa para a query", () => {
  const result = parseWindow(
    new URL("https://x/dry-run?from=2026-10-05&to=2026-10-12&fisioterapeuta_id=1%20OR%201%3D1"),
  );
  assert.match(result.error!, /fisioterapeuta_id inválido/);
});

// ---------------------------------------------------------------------
// Autenticação administrativa.
// ---------------------------------------------------------------------

test("token ausente (sem ADMIN_TOKEN configurado) -> nunca autoriza, mesmo com header correto", () => {
  assert.equal(isAuthorizedRequest("Bearer qualquer-coisa", undefined), false);
});

test("Authorization ausente -> não autoriza", () => {
  assert.equal(isAuthorizedRequest(null, "segredo-correto"), false);
});

test("Authorization sem prefixo 'Bearer ' -> não autoriza", () => {
  assert.equal(isAuthorizedRequest("segredo-correto", "segredo-correto"), false);
  assert.equal(isAuthorizedRequest("Token segredo-correto", "segredo-correto"), false);
});

test("Bearer com token vazio -> não autoriza", () => {
  assert.equal(isAuthorizedRequest("Bearer ", "segredo-correto"), false);
});

test("Bearer com token errado -> não autoriza (401)", () => {
  assert.equal(isAuthorizedRequest("Bearer segredo-errado", "segredo-correto"), false);
});

test("Bearer com token certo -> autoriza", () => {
  assert.equal(isAuthorizedRequest("Bearer segredo-correto", "segredo-correto"), true);
});

test("um JWT de usuário comum do Supabase NUNCA autoriza por si só -- só comparação de bytes com o admin token", () => {
  const fakeJwtLikeString =
    "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJmaXNpby0xIiwicm9sZSI6ImF1dGhlbnRpY2F0ZWQifQ.assinatura";
  assert.equal(isAuthorizedRequest(`Bearer ${fakeJwtLikeString}`, "segredo-correto"), false);
});
