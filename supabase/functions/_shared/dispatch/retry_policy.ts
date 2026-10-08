// Política de retry: resultado do provedor -> o que gravar. Pura.
//
//  - sent       -> sent (wamid).
//  - retryable  -> retry com espera crescente (1 min, 5 min, 15 min, 1 h; o
//                  Retry-After da Meta prevalece se for maior), até
//                  MAX_SEND_ATTEMPTS envios; depois, failed.
//  - rejected   -> failed (definitivo: 4xx, token inválido...).
//  - unknown    -> failed 'send_outcome_unknown' SEM retry: a Meta pode ter
//                  aceitado; reenviar arriscaria a paciente receber duas vezes.

import type { CompletionInput, DispatchError, ProviderSendResult } from "./types.ts";

export const MAX_SEND_ATTEMPTS = 5;
export const RETRY_DELAYS_SECONDS = [60, 300, 900, 3600] as const;

export function retryDelaySeconds(attemptCount: number, retryAfterSeconds?: number): number {
  const base = RETRY_DELAYS_SECONDS[Math.min(Math.max(attemptCount, 1), RETRY_DELAYS_SECONDS.length) - 1];
  return Math.max(base, retryAfterSeconds ?? 0);
}

function errorOf(result: Exclude<ProviderSendResult, { kind: "sent" }>): DispatchError {
  const error: DispatchError = { code: result.code };
  if (result.httpStatus !== undefined) error.http_status = result.httpStatus;
  if ("providerCode" in result && result.providerCode !== undefined) error.provider_code = result.providerCode;
  if ("providerSubcode" in result && result.providerSubcode !== undefined) {
    error.provider_subcode = result.providerSubcode;
  }
  return error;
}

export function decideCompletion(
  result: ProviderSendResult,
  attemptCount: number,
  templateName: string,
): CompletionInput {
  switch (result.kind) {
    case "sent":
      return { result: "sent", wamid: result.wamid, templateName };
    case "retryable":
      if (attemptCount >= MAX_SEND_ATTEMPTS) {
        return { result: "failed", templateName, error: { ...errorOf(result), code: "max_attempts_exceeded" } };
      }
      return {
        result: "retry",
        retryDelaySeconds: retryDelaySeconds(attemptCount, result.retryAfterSeconds),
        error: errorOf(result),
      };
    case "rejected":
      return { result: "failed", templateName, error: errorOf(result) };
    case "unknown":
      return {
        result: "failed",
        templateName,
        error: { ...errorOf(result), code: "send_outcome_unknown" },
      };
  }
}
