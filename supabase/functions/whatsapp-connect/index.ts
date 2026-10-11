// Edge Function do onboarding do WhatsApp (Embedded Signup). Ver handler.ts.
//
// verify_jwt = false no config.toml de propósito: `config` e `complete`
// são chamadas pela página de onboarding, que não tem a sessão do app e se
// autentica com o state de uso único. As ações do app (`start`, `status`,
// `disconnect`) validam o JWT aqui mesmo, via auth.getUser.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { readConnectConfig } from "./config.ts";
import { createConnectHandler, type ConnectStore } from "./handler.ts";
import { createMetaOnboarding } from "./meta_onboarding.ts";

const url = Deno.env.get("SUPABASE_URL") ?? "";
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const admin = createClient(url, serviceRoleKey, { auth: { persistSession: false } });

const store: ConnectStore = {
  async createAttempt(userId, stateHash, ttlSeconds) {
    const { error } = await admin.rpc("create_whatsapp_connect_attempt", {
      p_fisioterapeuta_id: userId,
      p_state_hash: stateHash,
      p_ttl_seconds: ttlSeconds,
    });
    if (!error) return "ok";
    return error.code === "WA006" ? "rate_limited" : "error";
  },
  async peekAttempt(stateHash) {
    const { data, error } = await admin.rpc("peek_whatsapp_connect_attempt", { p_state_hash: stateHash });
    return error || typeof data !== "string" ? null : data;
  },
  async consumeAttempt(stateHash) {
    const { data, error } = await admin.rpc("consume_whatsapp_connect_attempt", { p_state_hash: stateHash });
    return error || typeof data !== "string" ? null : data;
  },
  async upsertConnection(input) {
    const { data, error } = await admin.rpc("upsert_whatsapp_connection_from_signup", {
      p_fisioterapeuta_id: input.userId,
      p_waba_id: input.wabaId,
      p_phone_number_id: input.phoneNumberId,
      p_display_phone_number: input.displayPhoneNumber,
      p_status: input.status,
      p_last_error: input.lastError,
    });
    if (!error && typeof data === "string") return { ok: true, id: data };
    if (error?.code === "WA007") return { ok: false, code: "active_connection" };
    if (error?.code === "WA008") return { ok: false, code: "phone_in_use" };
    return { ok: false, code: "error" };
  },
  async setAccessToken(connectionId, token) {
    const { error } = await admin.rpc("set_whatsapp_connection_access_token", {
      p_connection_id: connectionId,
      p_access_token: token,
    });
    return !error;
  },
  async getAccessToken(userId) {
    const { data, error } = await admin.rpc("get_whatsapp_connection_access_token", {
      p_fisioterapeuta_id: userId,
    });
    return error || typeof data !== "string" ? null : data;
  },
  async getConnection(userId) {
    const { data, error } = await admin
      .from("whatsapp_connections")
      .select("id,status,waba_id,phone_number_id,display_phone_number")
      .eq("fisioterapeuta_id", userId)
      .maybeSingle();
    if (error || !data) return null;
    return {
      id: data.id,
      status: data.status,
      wabaId: data.waba_id,
      phoneNumberId: data.phone_number_id,
      displayPhoneNumber: data.display_phone_number,
    };
  },
  async disconnect(userId) {
    const { error } = await admin.rpc("disconnect_whatsapp_connection", { p_fisioterapeuta_id: userId });
    return !error;
  },
};

Deno.serve(
  createConnectHandler({
    config: readConnectConfig((name) => Deno.env.get(name)),
    store,
    meta: (config) => createMetaOnboarding({ config }),
    authenticate: async (authorization) => {
      const match = /^Bearer (.+)$/.exec(authorization ?? "");
      if (!match) return null;
      const { data, error } = await admin.auth.getUser(match[1]);
      return error || !data.user ? null : data.user.id;
    },
  }),
);
