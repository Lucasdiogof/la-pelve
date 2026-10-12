import { test } from "node:test";
import assert from "node:assert/strict";
import { parseAccountUpdates } from "./parse_account_update.ts";

const wrap = (entryId: string, value: unknown, field = "account_update") => ({
  object: "whatsapp_business_account",
  entry: [{ id: entryId, time: 1, changes: [{ field, value }] }],
});

test("PARTNER_REMOVED usa waba_info.waba_id", () => {
  assert.deepEqual(
    parseAccountUpdates(wrap("2949482758682047", { event: "PARTNER_REMOVED", waba_info: { waba_id: "980198427658004", owner_business_id: "1" } })),
    [{ wabaId: "980198427658004", event: "PARTNER_REMOVED", detail: "" }],
  );
});

test("ACCOUNT_DELETED (sem waba_info) usa entry.id; DISABLED_UPDATE leva o estado de banimento", () => {
  assert.deepEqual(parseAccountUpdates(wrap("102290129340398", { event: "ACCOUNT_DELETED" })), [
    { wabaId: "102290129340398", event: "ACCOUNT_DELETED", detail: "" },
  ]);
  assert.deepEqual(
    parseAccountUpdates(wrap("102290129340398", { event: "DISABLED_UPDATE", ban_info: { waba_ban_state: "REINSTATE" } })),
    [{ wabaId: "102290129340398", event: "DISABLED_UPDATE", detail: "REINSTATE" }],
  );
});

test("ignora outros campos, ids/eventos malformados e lixo, sem lançar", () => {
  assert.deepEqual(parseAccountUpdates(wrap("102290129340398", { event: "x" }, "messages")), []);
  assert.deepEqual(parseAccountUpdates(wrap("abc", { event: "ACCOUNT_DELETED" })), []);
  assert.deepEqual(parseAccountUpdates(wrap("102290129340398", { event: "drop table" })), []);
  for (const junk of [null, undefined, 1, "x", [], { entry: "x" }, { entry: [null, { changes: 3 }] }]) {
    assert.deepEqual(parseAccountUpdates(junk), []);
  }
});
