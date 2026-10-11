import type { AccountEvent } from "./parse_account_update.ts";

/** Aplica um evento de conta da Meta às conexões da WABA. Idempotente. */
export interface AccountEventPort {
  /** Quantas conexões mudaram, ou null em falha de persistência (a Meta reenvia). */
  applyAccountEvent(event: AccountEvent): Promise<number | null>;
}
