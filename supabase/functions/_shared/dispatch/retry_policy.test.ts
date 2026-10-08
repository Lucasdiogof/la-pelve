import { test } from "node:test";
import assert from "node:assert/strict";
import { decideCompletion, MAX_SEND_ATTEMPTS, retryDelaySeconds } from "./retry_policy.ts";

test("sent -> grava wamid e template", () => {
  assert.deepEqual(decideCompletion({ kind: "sent", wamid: "wamid.1" }, 1, "tpl"), {
    result: "sent",
    wamid: "wamid.1",
    templateName: "tpl",
  });
});

test("retryable -> retry com espera crescente", () => {
  assert.deepEqual(
    [1, 2, 3, 4].map((n) => retryDelaySeconds(n)),
    [60, 300, 900, 3600],
  );
  const decision = decideCompletion({ kind: "retryable", code: "provider_unavailable", httpStatus: 503 }, 2, "tpl");
  assert.deepEqual(decision, {
    result: "retry",
    retryDelaySeconds: 300,
    error: { code: "provider_unavailable", http_status: 503 },
  });
});

test("Retry-After maior que a política prevalece", () => {
  const decision = decideCompletion({ kind: "retryable", code: "rate_limited", httpStatus: 429, retryAfterSeconds: 600 }, 1, "tpl");
  assert.equal(decision.result === "retry" && decision.retryDelaySeconds, 600);
});

test("retryable na última tentativa -> failed max_attempts_exceeded", () => {
  const decision = decideCompletion({ kind: "retryable", code: "rate_limited", httpStatus: 429 }, MAX_SEND_ATTEMPTS, "tpl");
  assert.equal(decision.result, "failed");
  assert.equal(decision.result === "failed" && decision.error.code, "max_attempts_exceeded");
});

test("rejected -> failed definitivo, com códigos", () => {
  assert.deepEqual(
    decideCompletion({ kind: "rejected", code: "auth_error", httpStatus: 401, providerCode: 190 }, 1, "tpl"),
    { result: "failed", templateName: "tpl", error: { code: "auth_error", http_status: 401, provider_code: 190 } },
  );
});

test("unknown (timeout/rede) -> failed send_outcome_unknown, NUNCA retry", () => {
  for (const code of ["timeout", "network_error", "invalid_provider_response"]) {
    const decision = decideCompletion({ kind: "unknown", code }, 1, "tpl");
    assert.equal(decision.result, "failed");
    assert.equal(decision.result === "failed" && decision.error.code, "send_outcome_unknown");
  }
});
