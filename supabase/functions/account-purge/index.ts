// Edge Function account-purge: apaga de vez as contas cujo prazo de arrependimento (30 dias) venceu.
// NÃO DEPLOYADA. Sem o cron (supabase/rollout-0039/05_schedule_account_purge.sql) nada a chama.
// Secrets: ACCOUNT_PURGE_TOKEN (>= 32 caracteres). SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY vêm do ambiente.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { createPurgeHandler } from "./handler.ts";
import { removeUserStorage, type PurgePorts, type StorageLike } from "./purge.ts";

function buildPorts(): PurgePorts {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) throw new Error("SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY ausentes");
  const client = createClient(url, key, { auth: { persistSession: false } });
  const storage: StorageLike = {
    async list(bucket, path, limit, offset) {
      const { data, error } = await client.storage.from(bucket).list(path, { limit, offset });
      if (error) throw new Error("storage_list");
      return (data ?? []).map((f) => ({ name: f.name, id: f.id ?? null }));
    },
    async remove(bucket, paths) {
      const { error } = await client.storage.from(bucket).remove(paths);
      if (error) throw new Error("storage_remove");
    },
  };
  return {
    async listDue(limit) {
      const { data, error } = await client.rpc("list_due_account_deletions", { p_limit: limit });
      if (error) throw new Error("list_due");
      return (data ?? []).map((r: { user_id: string }) => r.user_id);
    },
    removeStorage: (userId) => removeUserStorage(storage, userId),
    async finalize(userId) {
      const { error } = await client.rpc("finalize_account_deletion", { p_user: userId });
      if (error) throw new Error("finalize");
    },
  };
}

Deno.serve(createPurgeHandler({ token: Deno.env.get("ACCOUNT_PURGE_TOKEN"), ports: buildPorts }));
