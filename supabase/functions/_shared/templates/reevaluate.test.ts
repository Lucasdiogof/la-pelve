import { test } from "node:test";
import assert from "node:assert/strict";
import { reevaluateAfterApproval, type ReadinessReader, type ReevaluationCandidate, type ReevaluationPort } from "./reevaluate.ts";

const WABA = "102290129340398";
const NOW = new Date("2026-10-12T12:00:00Z");

function candidate(id = "fisio-1"): ReevaluationCandidate {
  return { fisioterapeutaId: id, phoneNumberId: "106540352242922", displayPhoneNumber: "+55 62 1", setupState: { mode: "cloud" } };
}

function makePort(opts: { candidates?: ReevaluationCandidate[] | null; token?: string | null; promote?: "connected" | "stale" | "error" } = {}) {
  const calls: string[] = [];
  const promoted: Array<{ id: string; evaluatedAt: string }> = [];
  const port: ReevaluationPort = {
    async candidates() {
      calls.push("candidates");
      return opts.candidates === undefined ? [candidate()] : opts.candidates;
    },
    async accessToken() {
      calls.push("token");
      return opts.token === undefined ? "EAAB-token" : opts.token;
    },
    async promote(c, input) {
      calls.push("promote");
      promoted.push({ id: c.fisioterapeutaId, evaluatedAt: input.evaluatedAt });
      return opts.promote ?? "connected";
    },
  };
  return { port, calls, promoted };
}

function makeMeta(state: {
  phone?: string;
  confirmation?: "approved" | "pending" | "rejected" | "missing";
  reminder?: "approved" | "pending" | "rejected" | "missing";
  health?: "available" | "limited" | "blocked" | "unknown";
  fail?: boolean;
} = {}) {
  const calls: string[] = [];
  const meta: ReadinessReader = {
    async getPhoneInfo() {
      calls.push("phone");
      if (state.fail) return { ok: false, code: "meta_unreachable" };
      return { ok: true, info: { displayPhoneNumber: "+55 62 9", status: state.phone ?? "CONNECTED", isPinEnabled: false } };
    },
    async getTemplatesReport() {
      calls.push("templates");
      return { ok: true, report: { confirmation: state.confirmation ?? "approved", reminder: state.reminder ?? "approved" } };
    },
    async getAccountHealth() {
      calls.push("health");
      return { ok: true, health: state.health ?? "available" };
    },
  };
  return { meta, calls };
}

test("tudo pronto na Meta: promove com o início da avaliação ANTES das leituras", async () => {
  const p = makePort();
  const m = makeMeta();
  let clock = NOW;
  const summary = await reevaluateAfterApproval(WABA, p.port, m.meta, () => {
    const t = clock;
    clock = new Date(clock.getTime() + 1000);
    return t;
  });
  assert.deepEqual(summary, { candidates: 1, promoted: 1, notReady: 0, stale: 0, errors: 0 });
  assert.equal(p.promoted[0].evaluatedAt, NOW.toISOString());
  assert.deepEqual(m.calls, ["phone", "templates", "health"], "só leituras, nada é criado na Meta");
});

test("aprovação do webhook sozinha não basta: template ainda pendente/rejeitado na Meta não promove", async () => {
  for (const state of [{ reminder: "pending" as const }, { confirmation: "rejected" as const }, { confirmation: "missing" as const }]) {
    const p = makePort();
    const summary = await reevaluateAfterApproval(WABA, p.port, makeMeta(state).meta, () => NOW);
    assert.equal(summary.promoted, 0);
    assert.equal(summary.notReady, 1);
    assert.ok(!p.calls.includes("promote"));
  }
});

test("número não conectado, conta limitada/bloqueada ou Meta fora: não promove", async () => {
  for (const state of [{ phone: "PENDING" }, { health: "limited" as const }, { health: "blocked" as const }, { health: "unknown" as const }, { fail: true }]) {
    const p = makePort();
    const summary = await reevaluateAfterApproval(WABA, p.port, makeMeta(state).meta, () => NOW);
    assert.equal(summary.promoted, 0, JSON.stringify(state));
    assert.ok(!p.calls.includes("promote"));
  }
});

test("sem token: não consulta a Meta nem promove", async () => {
  const p = makePort({ token: null });
  const m = makeMeta();
  const summary = await reevaluateAfterApproval(WABA, p.port, m.meta, () => NOW);
  assert.equal(summary.notReady, 1);
  assert.deepEqual(m.calls, []);
});

test("banco recusa por evento negativo mais novo (WA010): conta como stale, não como conectada", async () => {
  const p = makePort({ promote: "stale" });
  const summary = await reevaluateAfterApproval(WABA, p.port, makeMeta().meta, () => NOW);
  assert.deepEqual(summary, { candidates: 1, promoted: 0, notReady: 0, stale: 1, errors: 0 });
});

test("falha ao listar candidatas ou exceção não lança", async () => {
  const none = await reevaluateAfterApproval(WABA, makePort({ candidates: null }).port, makeMeta().meta, () => NOW);
  assert.equal(none.errors, 1);
  const p = makePort({ candidates: [candidate("a"), candidate("b")] });
  const meta = makeMeta().meta;
  meta.getAccountHealth = async () => {
    throw new Error("boom");
  };
  const summary = await reevaluateAfterApproval(WABA, p.port, meta, () => NOW);
  assert.deepEqual(summary, { candidates: 2, promoted: 0, notReady: 0, stale: 0, errors: 2 });
});
