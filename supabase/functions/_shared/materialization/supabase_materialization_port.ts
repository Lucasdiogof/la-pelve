// Implementação REAL de MaterializationPort usando o SupabaseClient
// (service_role). Deno-only (import de supabase-js por especificador
// jsr:), por isso nunca é importado pelos testes (que rodam em Node) --
// mesmo padrão já usado em whatsapp-scheduler-dry-run/supabase_data_port.ts.
//
// NÃO EXECUTADO contra produção nesta etapa. NÃO deployado.
//
// ---------------------------------------------------------------------
// POR QUE SELECT PRE-CHECK + INSERT ... ON CONFLICT DO NOTHING (não só
// o INSERT direto)
// ---------------------------------------------------------------------
// Confirmado contra a documentação oficial do Postgres (seção de INSERT
// ON CONFLICT): triggers BEFORE INSERT disparam para TODA linha
// candidata, ANTES da detecção de conflito -- e `DO NOTHING` só suprime
// o erro de violação de UNIQUE em si, nunca uma exceção INDEPENDENTE
// levantada por um trigger BEFORE. Ou seja: se tentássemos simplesmente
// re-inserir a MESMA tripla (appointment_id, reminder_type,
// schedule_revision) de uma linha que já existe, e o consentimento
// original tivesse sido revogado DEPOIS da criação da linha, o trigger
// whatsapp_messages_validate_and_protect dispararia e rejeitaria a
// tentativa com WA001 -- MESMO que a linha já existisse e o INSERT fosse,
// na prática, um no-op esperado. Isso classificaria erroneamente um
// "já existe, nada a fazer" como "consentimento inválido".
//
// Por isso a estratégia é em 2 passos:
//   1) SELECT só pela identidade (appointment_id, reminder_type,
//      schedule_revision). Se encontrar, retorna already_exists
//      IMEDIATAMENTE -- sem tentar INSERT, sem revalidar consentimento,
//      sem tocar a linha. A linha existente é o histórico original
//      daquela revision; nunca é comparada nem corrigida.
//   2) Se não encontrar, faz o INSERT com
//      ON CONFLICT (appointment_id, reminder_type, schedule_revision)
//      DO NOTHING -- ainda necessário por causa da corrida entre dois
//      schedulers concorrentes (A e B fazem o SELECT quase ao mesmo
//      tempo, ambos veem "não existe", A insere primeiro, B tenta
//      inserir e colide -- o ON CONFLICT garante que B não derruba nem
//      duplica, só não insere nada). A UNIQUE real continua sendo a
//      garantia FINAL de concorrência; o SELECT é só uma otimização de
//      caminho feliz que evita acionar o trigger de validação para
//      linhas que já existem.
//
// Resultado (ver supabase_materialization_port.test.ts):
//   A) pre-check encontra a tripla -> already_exists, nenhum INSERT.
//   B) pre-check vazio + consentimento ativo + INSERT cria -> inserted.
//   C) pre-check vazio + outra execução insere antes + DO NOTHING
//      -> already_exists.
//   D) pre-check vazio + consentimento revogado + WA001 + 2o SELECT vazio
//      -> consent_no_longer_valid.
//   E) pre-check vazio + outra execução insere + consentimento revogado
//      + WA001 + 2o SELECT encontra a tripla -> already_exists.
//   F) WA001 + 2o SELECT falha -> error (nunca consent_no_longer_valid).
// Os dois SELECTs são a mesma findExistingMessageIdentity: só a tripla,
// só o id. Linha encontrada nunca é comparada, corrigida nem atualizada.
//
// ---------------------------------------------------------------------
// EQUIVALÊNCIA upsert(ignoreDuplicates) <-> INSERT ... ON CONFLICT DO NOTHING
// ---------------------------------------------------------------------
// .upsert(row, {onConflict, ignoreDuplicates:true}) manda
// `Prefer: resolution=ignore-duplicates` ao PostgREST, que gera no
// servidor um INSERT ... ON CONFLICT (<onConflict>) DO NOTHING -- nunca
// DO UPDATE (documentado no PostgREST; confirmado nesta sessão via busca
// externa). Quando a linha é ignorada por conflito, ela não é
// representada na resposta -- por isso `.select("id")` + checar
// data.length distingue inserted de already_exists nesse passo 2.
//
// LIMITAÇÃO HONESTA (mantida desde a versão anterior): esta equivalência
// é a documentada do PostgREST em geral; não foi testada empiricamente
// contra este projeto Supabase nesta sessão (nenhuma escrita real foi
// autorizada). A primeira chamada real deste adapter é a primeira
// verificação empírica desta suposição.
//
// ---------------------------------------------------------------------
// SQLSTATE customizado (migration 0024)
// ---------------------------------------------------------------------
// error.code === 'P0001' foi abandonado de propósito: é o código
// GENÉRICO de qualquer RAISE EXCEPTION sem código customizado em
// PL/pgSQL, não específico desta validação. A migration 0024 troca a
// branch de validação de consentimento (nunca a de UPDATE, que esta
// camada nunca aciona) para `RAISE EXCEPTION USING ERRCODE = 'WA001'` --
// um código que não colide com nenhuma classe padrão do Postgres.
// Qualquer OUTRO código de erro (incluindo um eventual P0001 genérico de
// algum outro lugar) cai em {kind:'error'}, nunca em
// consent_no_longer_valid.
// ---------------------------------------------------------------------

// deno-lint-ignore no-explicit-any
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { toWhatsappMessageInsertRow, UPSERT_CONFLICT_TARGET } from "./row_mapping.ts";
import type { MaterializableMessage, MaterializationOutcome, MaterializationPort } from "./types.ts";

const CONSENT_VALIDATION_SQLSTATE = "WA001";

/** Log interno sanitizado -- NUNCA telefone/consentId/patientId/mensagem bruta do Postgres. */
function logPersistenceFailure(message: MaterializableMessage, context: string) {
  console.error(
    JSON.stringify({
      event: "whatsapp_message_materialization_failed",
      context,
      appointmentId: message.appointmentId,
      reminderType: message.reminderType,
      scheduleRevision: message.scheduleRevision,
    }),
  );
}

type IdentityLookup = "exists" | "not_found" | "error";

/**
 * Consulta SOMENTE a identidade da mensagem (appointment_id,
 * reminder_type, schedule_revision) e pede só o `id`. Nunca olha
 * patient_id, consent_id, destination_phone_e164, scheduled_for nem
 * status: se a tripla existe, a linha histórica venceu -- não se compara,
 * não se corrige, não se ressuscita uma cancelled. Nunca lança.
 */
async function findExistingMessageIdentity(
  // deno-lint-ignore no-explicit-any
  client: SupabaseClient,
  message: MaterializableMessage,
): Promise<IdentityLookup> {
  try {
    const { data, error } = await client
      .from("whatsapp_messages")
      .select("id")
      .eq("appointment_id", message.appointmentId)
      .eq("reminder_type", message.reminderType)
      .eq("schedule_revision", message.scheduleRevision)
      .limit(1);
    if (error || !Array.isArray(data)) return "error";
    return data.length > 0 ? "exists" : "not_found";
  } catch {
    return "error";
  }
}

export function createSupabaseMaterializationPort(
  // deno-lint-ignore no-explicit-any
  client: SupabaseClient,
): MaterializationPort {
  return {
    async insertIfAbsent(message: MaterializableMessage): Promise<MaterializationOutcome> {
      try {
        // Passo 1: pre-check só pela identidade (CASO A).
        const before = await findExistingMessageIdentity(client, message);
        if (before === "error") {
          logPersistenceFailure(message, "precheck_select_failed");
          return { kind: "error", code: "persistence_error" };
        }
        if (before === "exists") {
          return { kind: "already_exists" };
        }

        // Passo 2: não existia no pre-check -- tenta inserir, protegido
        // por ON CONFLICT DO NOTHING contra a corrida entre schedulers.
        const { data, error } = await client
          .from("whatsapp_messages")
          .upsert(toWhatsappMessageInsertRow(message), {
            onConflict: UPSERT_CONFLICT_TARGET,
            ignoreDuplicates: true,
          })
          .select("id");

        if (error) {
          if (error.code === CONSENT_VALIDATION_SQLSTATE) {
            // O trigger roda ANTES do ON CONFLICT: WA001 não prova que a
            // tripla está livre. Outra execução pode tê-la inserido entre
            // o pre-check e este INSERT, e o consentimento ter sido
            // revogado depois (CASO E). Segundo SELECT só pela identidade
            // decide: existe -> already_exists; não existe -> CASO D;
            // falhou -> error (nunca chuta consent_no_longer_valid).
            const after = await findExistingMessageIdentity(client, message);
            if (after === "exists") return { kind: "already_exists" };
            if (after === "not_found") return { kind: "consent_no_longer_valid" };
            logPersistenceFailure(message, "postconflict_select_failed");
            return { kind: "error", code: "persistence_error" };
          }
          logPersistenceFailure(message, "insert_failed");
          return { kind: "error", code: "persistence_error" };
        }

        // Insert de 1 linha: [linha] = inserida (CASO B); [] = ignorada
        // pelo ON CONFLICT DO NOTHING, outro scheduler venceu (CASO C).
        // Qualquer outra forma (null, não-array, >1 linha) é resposta
        // inesperada -- nunca assumida como sucesso nem como já-existente.
        if (Array.isArray(data) && data.length === 1) return { kind: "inserted" };
        if (Array.isArray(data) && data.length === 0) return { kind: "already_exists" };
        logPersistenceFailure(message, "unexpected_insert_response");
        return { kind: "error", code: "persistence_error" };
      } catch {
        // Falha de rede/fetch ou qualquer exceção inesperada -- o
        // contrato de MaterializationPort exige nunca lançar.
        logPersistenceFailure(message, "unexpected_exception");
        return { kind: "error", code: "persistence_error" };
      }
    },
  };
}
