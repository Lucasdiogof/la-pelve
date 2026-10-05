// Validação de parâmetros HTTP e autenticação administrativa -- PURO, sem
// Deno.* (index.ts é quem lê Deno.env e chama estas funções), para ser
// testável em Node sem precisar de Deno instalado.

import type { DryRunWindow } from "./types.ts";

export const MAX_WINDOW_DAYS = 31;

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

export interface ParsedWindowResult {
  window?: DryRunWindow;
  error?: string;
}

/**
 * Valida from/to/fisioterapeuta_id vindos da querystring. NUNCA aceita
 * filtro/SQL cru -- só os 3 parâmetros nomeados, cada um validado por
 * formato antes de qualquer uso.
 *
 * from E to são OBRIGATÓRIOS, sem default. Motivo: appointments.date é
 * uma data CIVIL ("de parede") no timezone de CADA profissional -- com
 * vários profissionais em timezones diferentes, não existe uma única
 * "data atual" universal derivável de UTC que sirva de default correto
 * para todos ao mesmo tempo. Esta function é administrativa/dry-run:
 * prefere-se comportamento explícito e determinístico a inferir uma data
 * que poderia estar certa para um profissional e errada para outro.
 * (O scheduler automático futuro, via cron, vai precisar de uma
 * estratégia própria de janela — ver nota em index.ts; não é resolvida
 * aqui.)
 *
 * IMPORTANTE sobre o significado do filtro: `from`/`to` comparam
 * appointments.date (a data civil armazenada no agendamento), não um
 * instante UTC. Este filtro é só a primeira triagem de candidatos (reduz
 * quantas linhas buscar); a interpretação timezone-aware do horário
 * completo (appointment.date + appointment.time + profile.timezone)
 * acontece depois, dentro de decideMessagesForAppointment
 * (_shared/scheduler/decision.ts via zonedDateTimeStringToUtc).
 */
export function parseWindow(url: URL): ParsedWindowResult {
  const fromParam = url.searchParams.get("from");
  const toParam = url.searchParams.get("to");
  const fisioParam = url.searchParams.get("fisioterapeuta_id");

  if (!fromParam) return { error: "from é obrigatório (YYYY-MM-DD)" };
  if (!toParam) return { error: "to é obrigatório (YYYY-MM-DD)" };

  const fromDate = fromParam;
  if (!DATE_RE.test(fromDate)) return { error: "from inválido (esperado YYYY-MM-DD)" };

  const toDate = toParam;
  if (!DATE_RE.test(toDate)) return { error: "to inválido (esperado YYYY-MM-DD)" };

  if (toDate < fromDate) return { error: "to não pode ser anterior a from" };

  const spanDays = (Date.parse(toDate) - Date.parse(fromDate)) / 86_400_000;
  if (spanDays > MAX_WINDOW_DAYS) {
    return { error: `janela máxima é de ${MAX_WINDOW_DAYS} dias (pedida: ${spanDays})` };
  }

  let fisioterapeutaId: string | null = null;
  if (fisioParam !== null) {
    if (!UUID_RE.test(fisioParam)) return { error: "fisioterapeuta_id inválido (esperado UUID)" };
    fisioterapeutaId = fisioParam;
  }

  return { window: { fromDate, toDate, fisioterapeutaId } };
}

const encoder = new TextEncoder();

/** Comparação em tempo constante, mesmo padrão já usado em whatsapp-webhook. */
export function safeEqual(a: string, b: string): boolean {
  const ab = encoder.encode(a);
  const bb = encoder.encode(b);
  let diff = ab.length ^ bb.length;
  for (let i = 0; i < Math.max(ab.length, bb.length); i++) {
    diff |= (ab[i] ?? 0) ^ (bb[i] ?? 0);
  }
  return diff === 0;
}

/**
 * Autorização administrativa PRÓPRIA desta function -- não o JWT de
 * usuário final do Supabase. `adminToken` é o valor configurado
 * (Deno.env.get("SCHEDULER_DRY_RUN_ADMIN_TOKEN"), lido 1x pelo index.ts e
 * passado aqui por parâmetro -- este arquivo nunca lê Deno.env
 * diretamente, por isso é testável em Node).
 *
 * Regras, todas obrigatórias:
 * - sem adminToken configurado -> NUNCA autoriza (mesmo que o header
 *   pareça certo) -- evita "modo aberto" por function mal configurada;
 * - header ausente -> não autoriza;
 * - header sem o prefixo EXATO "Bearer " -> não autoriza;
 * - token vazio após "Bearer " -> não autoriza;
 * - token presente mas diferente do configurado -> não autoriza (um JWT
 *   válido de usuário comum do Supabase NUNCA bate aqui, porque isto
 *   nunca decodifica/valida JWT -- só compara bytes com o segredo
 *   administrativo);
 * - comparação em tempo constante (safeEqual), nunca `===`.
 */
export function isAuthorizedRequest(
  authorizationHeader: string | null,
  adminToken: string | undefined,
): boolean {
  if (!adminToken) return false;
  const header = authorizationHeader ?? "";
  if (!header.startsWith("Bearer ")) return false;
  const token = header.slice("Bearer ".length);
  return token.length > 0 && safeEqual(token, adminToken);
}
