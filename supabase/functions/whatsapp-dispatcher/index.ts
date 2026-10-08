// Edge Function do pipeline outbound do WhatsApp: materialização ->
// reconciliação -> envio pela Cloud API. Ver handler.ts (HTTP/autenticação),
// config.ts (variáveis) e _shared/pipeline/run_pipeline.ts (ordem).
//
// NÃO DEPLOYADA. Sem o cron (supabase/rollout-0026/05_schedule_cron.sql),
// nada a chama.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { createSupabaseSchedulerDataPort } from "../whatsapp-scheduler-dry-run/supabase_data_port.ts";
import { createSupabaseMaterializationPort } from "../_shared/materialization/supabase_materialization_port.ts";
import { createSupabaseReconciliationPort } from "../_shared/reconciliation/supabase_reconciliation_port.ts";
import { createSupabaseReconciliationDataPort } from "../_shared/pipeline/reconciliation_inputs.ts";
import { createSupabaseDispatchStore } from "../_shared/dispatch/supabase_dispatch_store.ts";
import { createMetaWhatsappProvider } from "../_shared/dispatch/meta_provider.ts";
import { runWhatsappPipeline } from "../_shared/pipeline/run_pipeline.ts";
import { readDispatcherConfig } from "./config.ts";
import { createDispatcherHandler } from "./handler.ts";

Deno.serve(
  createDispatcherHandler({
    config: readDispatcherConfig((name) => Deno.env.get(name)),
    runPipeline: (config) => {
      const url = Deno.env.get("SUPABASE_URL");
      const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
      if (!url || !serviceRoleKey) throw new Error("SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY ausentes");
      const client = createClient(url, serviceRoleKey, { auth: { persistSession: false } });
      return runWhatsappPipeline({
        schedulerData: createSupabaseSchedulerDataPort(client),
        materialization: createSupabaseMaterializationPort(client),
        reconciliationData: createSupabaseReconciliationDataPort(client),
        reconciliation: createSupabaseReconciliationPort(client),
        dispatch: {
          store: createSupabaseDispatchStore(client),
          provider: createMetaWhatsappProvider({ graphApiVersion: config.graphApiVersion, timeoutMs: 10_000 }),
          templates: config.templates,
          now: () => new Date(),
        },
        now: () => new Date(),
      });
    },
  }),
);
