// Reavaliação automática depois de um evento de APROVAÇÃO de template.
//
// O evento do webhook sozinho NUNCA conecta: ele só dispara esta checagem,
// que consulta a Meta (somente leitura) com a credencial da própria conexão e
// só promove se TUDO estiver pronto -- número CONNECTED, os dois templates
// aprovados e conta disponível. A gravação passa pelo mesmo upsert do
// whatsapp-connect (migration 0034), que recusa 'connected' se outro evento
// negativo de template chegou depois do início desta avaliação.
//
// Candidatas: só conexões 'pending' cujo motivo é template (templates_pending /
// templates_rejected), ou seja, que já tinham passado por inscrição do webhook
// e registro do número. Nada é criado na Meta (sem templates, sem registro,
// sem inscrição). Nunca lança; logs só com contagens.

import type { AccountHealth, Fail, Ok, PhoneInfo, TemplatesReport } from "../../whatsapp-connect/meta_onboarding.ts";

export interface ReevaluationCandidate {
  fisioterapeutaId: string;
  phoneNumberId: string;
  displayPhoneNumber: string | null;
  setupState: Record<string, unknown>;
}

export type PromoteResult = "connected" | "stale" | "error";

export interface ReevaluationPort {
  /** null = falha de leitura. */
  candidates(wabaId: string): Promise<ReevaluationCandidate[] | null>;
  accessToken(fisioterapeutaId: string): Promise<string | null>;
  promote(
    candidate: ReevaluationCandidate,
    input: { wabaId: string; displayPhoneNumber: string | null; evaluatedAt: string },
  ): Promise<PromoteResult>;
}

/** Só as leituras da Meta usadas aqui (subconjunto de MetaOnboarding). */
export interface ReadinessReader {
  getPhoneInfo(token: string, phoneNumberId: string): Promise<Ok<{ info: PhoneInfo }> | Fail>;
  getTemplatesReport(token: string, wabaId: string): Promise<Ok<{ report: TemplatesReport }> | Fail>;
  getAccountHealth(token: string, wabaId: string): Promise<Ok<{ health: AccountHealth }> | Fail>;
}

export interface ReevaluationSummary {
  candidates: number;
  promoted: number;
  notReady: number;
  stale: number;
  errors: number;
}

export async function reevaluateAfterApproval(
  wabaId: string,
  port: ReevaluationPort,
  meta: ReadinessReader,
  now: () => Date = () => new Date(),
): Promise<ReevaluationSummary> {
  const summary: ReevaluationSummary = { candidates: 0, promoted: 0, notReady: 0, stale: 0, errors: 0 };
  let candidates: ReevaluationCandidate[] | null;
  try {
    candidates = await port.candidates(wabaId);
  } catch {
    candidates = null;
  }
  if (candidates === null) {
    summary.errors++;
    return summary;
  }
  summary.candidates = candidates.length;
  for (const candidate of candidates) {
    try {
      // Início da avaliação ANTES das leituras: o banco compara com os eventos.
      const evaluatedAt = now().toISOString();
      const token = await port.accessToken(candidate.fisioterapeutaId);
      if (!token) {
        summary.notReady++;
        continue;
      }
      const phone = await meta.getPhoneInfo(token, candidate.phoneNumberId);
      const templates = await meta.getTemplatesReport(token, wabaId);
      const health = await meta.getAccountHealth(token, wabaId);
      const ready =
        phone.ok && phone.info.status === "CONNECTED" &&
        templates.ok && templates.report.confirmation === "approved" && templates.report.reminder === "approved" &&
        health.ok && health.health === "available";
      if (!ready) {
        summary.notReady++;
        continue;
      }
      const result = await port.promote(candidate, {
        wabaId,
        displayPhoneNumber: phone.ok ? phone.info.displayPhoneNumber : null,
        evaluatedAt,
      });
      if (result === "connected") summary.promoted++;
      else if (result === "stale") summary.stale++;
      else summary.errors++;
    } catch {
      summary.errors++;
    }
  }
  return summary;
}
