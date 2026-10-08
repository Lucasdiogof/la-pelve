// Uma rodada do pipeline outbound, NESTA ordem:
//   1. materialização  (cria o que deveria existir agora; idempotente)
//   2. reconciliação   (cancela o que ficou inválido para sempre)
//   3. dispatch        (envia só o que continua válido, revalidando no banco)
// Cada etapa isola as próprias falhas: uma etapa que falha não impede as
// outras (o dispatch revalida tudo de novo antes de enviar).

import { reconcileAll } from "../reconciliation/reconcile.ts";
import type { ReconciliationPort, ReconciliationSummary } from "../reconciliation/types.ts";
import type { MaterializationPort } from "../materialization/types.ts";
import type { SchedulerDataPort } from "../../whatsapp-scheduler-dry-run/types.ts";
import { dispatchPendingWhatsappMessages, type DispatchDeps } from "../dispatch/dispatch.ts";
import type { DispatchSummary } from "../dispatch/types.ts";
import { materializeDueMessages, type MaterializationRunSummary } from "./run_materialization.ts";
import { loadReconciliationInputs, type ReconciliationDataPort } from "./reconciliation_inputs.ts";

export interface PipelineDeps {
  schedulerData: SchedulerDataPort;
  materialization: MaterializationPort;
  reconciliationData: ReconciliationDataPort;
  reconciliation: ReconciliationPort;
  dispatch: DispatchDeps;
  now: () => Date;
}

export interface PipelineSummary {
  materialization: MaterializationRunSummary | { error: true };
  reconciliation: ReconciliationSummary | { error: true };
  dispatch: DispatchSummary;
}

export async function runWhatsappPipeline(deps: PipelineDeps): Promise<PipelineSummary> {
  let materialization: PipelineSummary["materialization"];
  try {
    materialization = await materializeDueMessages(deps.schedulerData, deps.materialization, deps.now());
  } catch {
    materialization = { error: true };
  }

  let reconciliation: PipelineSummary["reconciliation"];
  try {
    reconciliation = await reconcileAll(deps.reconciliation, await loadReconciliationInputs(deps.reconciliationData));
  } catch {
    reconciliation = { error: true };
  }

  const dispatch = await dispatchPendingWhatsappMessages(deps.dispatch);
  return { materialization, reconciliation, dispatch };
}
