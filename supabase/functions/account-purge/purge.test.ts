import { test } from "node:test";
import assert from "node:assert/strict";
import { runAccountPurge, removeUserStorage, type PurgePorts, type StorageLike } from "./purge.ts";
import { createPurgeHandler, isAuthorized } from "./handler.ts";

const TOKEN = "t".repeat(40);

function ports(overrides: Partial<PurgePorts> = {}): PurgePorts & { calls: string[] } {
  const calls: string[] = [];
  return {
    calls,
    listDue: async () => ["u1", "u2"],
    removeStorage: async (id) => { calls.push(`storage:${id}`); return { remaining: 0 }; },
    finalize: async (id) => { calls.push(`finalize:${id}`); },
    ...overrides,
  };
}

test("remove o Storage antes de finalizar, conta por conta", async () => {
  const p = ports();
  const s = await runAccountPurge(p);
  assert.deepEqual(p.calls, ["storage:u1", "finalize:u1", "storage:u2", "finalize:u2"]);
  assert.deepEqual(s, { due: 2, finalized: 2, skippedStorageNotEmpty: 0, failed: 0 });
});

test("arquivo sobrando: NÃO finaliza a conta", async () => {
  const p = ports({ removeStorage: async () => ({ remaining: 3 }) });
  const s = await runAccountPurge(p);
  assert.equal(s.finalized, 0);
  assert.equal(s.skippedStorageNotEmpty, 2);
  assert.deepEqual(p.calls, []);
});

test("falha de Storage em uma conta não impede as outras nem finaliza a que falhou", async () => {
  const p = ports({
    removeStorage: async (id) => {
      if (id === "u1") throw new Error("rede");
      p.calls.push(`storage:${id}`);
      return { remaining: 0 };
    },
  });
  const s = await runAccountPurge(p);
  assert.deepEqual(p.calls, ["storage:u2", "finalize:u2"]);
  assert.deepEqual(s, { due: 2, finalized: 1, skippedStorageNotEmpty: 0, failed: 1 });
});

test("falha da RPC de finalização conta como falha e a conta fica para a próxima rodada", async () => {
  const p = ports({ finalize: async () => { throw new Error("rpc"); } });
  const s = await runAccountPurge(p);
  assert.equal(s.failed, 2);
  assert.equal(s.finalized, 0);
});

test("reexecução é idempotente quando não há nada vencido", async () => {
  const p = ports({ listDue: async () => [] });
  assert.deepEqual(await runAccountPurge(p), { due: 0, finalized: 0, skippedStorageNotEmpty: 0, failed: 0 });
});

function fakeStorage(files: Record<string, string[]>, opts: { failRemove?: boolean; stickyOnce?: boolean } = {}): StorageLike & { removed: string[] } {
  const removed: string[] = [];
  let sticky = opts.stickyOnce ?? false;
  return {
    removed,
    async list(bucket, path, limit, offset) {
      const all = (files[bucket] ?? []).filter((f) => f.startsWith(path + "/"));
      const entries = new Map<string, string | null>();
      for (const f of all) {
        const rest = f.slice(path.length + 1);
        const [first, ...tail] = rest.split("/");
        entries.set(first, tail.length ? null : "id-" + f);
      }
      return [...entries].map(([name, id]) => ({ name, id })).slice(offset, offset + limit);
    },
    async remove(bucket, paths) {
      if (opts.failRemove) throw new Error("falha");
      if (sticky) { sticky = false; return; } // primeira tentativa não remove nada
      for (const p of paths) {
        files[bucket] = (files[bucket] ?? []).filter((f) => f !== p);
        removed.push(p);
      }
    },
  };
}

test("removeUserStorage apaga anexos e avatar e confirma zero", async () => {
  const files = { "patient-attachments": ["u1/p1/a.pdf", "u1/p1/b.jpg", "u1/p2/c.png", "outro/p1/x.pdf"], avatars: ["u1/foto.jpg"] };
  const st = fakeStorage(files);
  assert.deepEqual(await removeUserStorage(st, "u1"), { remaining: 0 });
  assert.equal(st.removed.length, 4);
  assert.deepEqual(files["patient-attachments"], ["outro/p1/x.pdf"]); // não toca em arquivos de outra conta
});

test("paginação: mais de 100 arquivos", async () => {
  const many = Array.from({ length: 250 }, (_, i) => `u1/p1/f${i}.jpg`);
  const st = fakeStorage({ "patient-attachments": many, avatars: [] });
  assert.deepEqual(await removeUserStorage(st, "u1"), { remaining: 0 });
  assert.equal(st.removed.length, 250);
});

test("remoção que não surte efeito na 1ª rodada é repetida", async () => {
  const st = fakeStorage({ "patient-attachments": ["u1/p1/a.pdf"], avatars: [] }, { stickyOnce: true });
  assert.deepEqual(await removeUserStorage(st, "u1"), { remaining: 0 });
});

test("falha de Storage propaga (a conta será pulada)", async () => {
  const st = fakeStorage({ "patient-attachments": ["u1/p1/a.pdf"], avatars: [] }, { failRemove: true });
  await assert.rejects(() => removeUserStorage(st, "u1"));
});

test("HTTP: sem token certo nada roda", async () => {
  let ran = false;
  const h = createPurgeHandler({ token: TOKEN, ports: () => { ran = true; return ports(); }, log: () => {} });
  assert.equal((await h(new Request("http://x", { method: "POST" }))).status, 401);
  assert.equal((await h(new Request("http://x", { method: "POST", headers: { authorization: "Bearer errado" } }))).status, 401);
  assert.equal((await h(new Request("http://x", { method: "GET" }))).status, 405);
  assert.equal(ran, false);
});

test("HTTP: token ausente ou curto nunca autoriza", () => {
  assert.equal(isAuthorized("Bearer abc", "abc"), false);
  assert.equal(isAuthorized(`Bearer ${TOKEN}`, undefined), false);
  assert.equal(isAuthorized(`Bearer ${TOKEN}`, TOKEN), true);
});

test("HTTP: resposta só tem contagens, sem ids", async () => {
  const logs: string[] = [];
  const h = createPurgeHandler({ token: TOKEN, ports: () => ports(), log: (e, d) => logs.push(JSON.stringify({ e, d })) });
  const res = await h(new Request("http://x", { method: "POST", headers: { authorization: `Bearer ${TOKEN}` } }));
  const body = await res.text();
  assert.equal(res.status, 200);
  assert.ok(!body.includes("u1") && !logs.join().includes("u1"));
});
