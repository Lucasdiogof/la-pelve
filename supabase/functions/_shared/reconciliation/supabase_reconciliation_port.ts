// Implementação REAL de ReconciliationPort usando o SupabaseClient
// (service_role). Deno-only (import de supabase-js por especificador jsr:),
// por isso nunca é importado pelos testes de lógica pura -- o teste do
// adapter usa um client falso (import type é apagado pelo strip de tipos).
//
// NÃO EXECUTADO contra produção nesta etapa. NÃO deployado.
//
// ESCOPO: este adapter serve SÓ ao cancelamento PERMANENTE, ou seja, só é
// chamado para decision.action === 'cancel' (stale_schedule_revision e
// consent_revoked, ambas monotônicas -- ver decide.ts). appointment_cancelled
// é reversível e vira action='blocked': nenhuma chamada a este adapter, a
// linha segue scheduled. Como as condições que chegam aqui nunca voltam a
// ser falsas, uma leitura antiga delas não pode ficar inválida antes do
// UPDATE; sobra apenas a corrida com o dispatch, tratada abaixo. Não há
// operação de block/unblock no banco.
//
// ---------------------------------------------------------------------
// UPDATE CONDICIONAL (a proteção contra a corrida vive no banco)
// ---------------------------------------------------------------------
// Equivale a:
//   UPDATE whatsapp_messages
//      SET status = 'cancelled'
//    WHERE id = ? AND status = 'scheduled'
//   RETURNING id
// via PostgREST: .update({status:'cancelled'}).eq('id', id).eq('status',
// 'scheduled').select('id'). O filtro status='scheduled' é parte do WHERE,
// avaliado atomicamente pelo Postgres no momento do UPDATE -- não uma
// checagem em memória feita antes. Cenário da corrida:
//   A) o reconciliador leu a mensagem como scheduled;
//   B) o dispatch (futuro) mudou para processing;
//   C) o reconciliador chama cancelIfScheduled.
// O WHERE não casa -> 0 linhas -> já não é cancelável. NUNCA cancela
// processing. Se dois reconciliadores concorrerem, só um muda a linha; o
// outro vê 0 linhas.
//
// O payload é SÓ { status: 'cancelled' }: nada de error/failed_at/sent_at/
// wamid/destino/consentimento/revisão/scheduled_for. O trigger
// whatsapp_messages_validate_and_protect só barra mudança nos campos de
// identidade (não toca status) e o trigger de updated_at cuida do carimbo.
//
// ---------------------------------------------------------------------
// 0 linhas: por que um SELECT depois
// ---------------------------------------------------------------------
// O UPDATE condicional sozinho não distingue "linha existe mas não está
// mais scheduled" de "linha não existe". Com 0 linhas, um SELECT só de `id`
// (nunca status, nunca outro campo) desempata: achou -> already_not_scheduled;
// vazio -> not_found; falhou -> error (nunca chuta). Esse SELECT não é
// atômico com o UPDATE, mas só serve para CLASSIFICAR o resultado -- a
// decisão de não cancelar já foi tomada, de forma atômica, pelo WHERE.
// (Uma única ida ao banco exigiria uma função SQL/RPC, ou seja, uma
// migration, fora do escopo.)
//
// LIMITAÇÃO HONESTA: este adapter nunca falou com o projeto real; a forma
// do retorno de .update().select() (array das linhas atualizadas, vazio
// quando nenhuma casou) é a documentada do PostgREST, ainda não verificada
// empiricamente aqui -- a primeira chamada real será essa verificação.
// ---------------------------------------------------------------------

// deno-lint-ignore no-explicit-any
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type { CancelOutcome, ReconciliationPort } from "./types.ts";

/** Log interno sanitizado -- só ids técnicos e o contexto, NUNCA erro bruto do Postgres. */
function logPersistenceFailure(messageId: string, context: string) {
  console.error(
    JSON.stringify({
      event: "whatsapp_message_reconciliation_failed",
      context,
      messageId,
    }),
  );
}

const PERSISTENCE_ERROR: CancelOutcome = { kind: "error", code: "persistence_error" };

export function createSupabaseReconciliationPort(
  // deno-lint-ignore no-explicit-any
  client: SupabaseClient,
): ReconciliationPort {
  return {
    async cancelIfScheduled(messageId: string): Promise<CancelOutcome> {
      try {
        const { data, error } = await client
          .from("whatsapp_messages")
          .update({ status: "cancelled" })
          .eq("id", messageId)
          .eq("status", "scheduled")
          .select("id");

        if (error || !Array.isArray(data)) {
          logPersistenceFailure(messageId, "update_failed");
          return PERSISTENCE_ERROR;
        }
        if (data.length === 1) return { kind: "cancelled" };
        if (data.length > 1) {
          // Impossível com id como PK; qualquer coisa diferente de 0 ou 1
          // linha é resposta inesperada, nunca assumida como sucesso.
          logPersistenceFailure(messageId, "unexpected_update_response");
          return PERSISTENCE_ERROR;
        }

        // 0 linhas: classificar (só `id`, nunca outros campos).
        const lookup = await client
          .from("whatsapp_messages")
          .select("id")
          .eq("id", messageId)
          .limit(1);
        if (lookup.error || !Array.isArray(lookup.data)) {
          logPersistenceFailure(messageId, "classify_select_failed");
          return PERSISTENCE_ERROR;
        }
        return lookup.data.length > 0 ? { kind: "already_not_scheduled" } : { kind: "not_found" };
      } catch {
        // Falha de rede/fetch ou exceção inesperada -- o contrato da porta
        // exige nunca lançar.
        logPersistenceFailure(messageId, "unexpected_exception");
        return PERSISTENCE_ERROR;
      }
    },
  };
}
