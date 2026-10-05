// Orquestra a materialização de várias MaterializableMessage via uma
// MaterializationPort. Nenhum I/O direto aqui -- só chama o port.
//
// Estratégia: INSERÇÃO INDIVIDUAL, uma chamada por mensagem, nunca um
// único INSERT em lote com múltiplas linhas. Motivo (ver seção 11 do
// pedido): se 1 consentimento for revogado entre a leitura e o INSERT de
// um lote de, digamos, 100 candidatas, um UNICO INSERT multi-linha
// falharia a transação INTEIRA quando o trigger rejeitasse aquela 1
// linha (um erro de trigger aborta o statement completo, inclusive as
// outras 99 linhas válidas). Inserção individual isola cada candidata:
// a rejeição de uma nunca impede as demais. Processamento sequencial
// (não Promise.all) por simplicidade nesta fase -- não é o mais
// performático, mas evita qualquer surpresa de concorrência entre as
// próprias chamadas desta função; pode ser revisitado depois se virar
// gargalo real.

import type {
  MaterializableMessage,
  MaterializationPort,
  MaterializationSummary,
} from "./types.ts";

export async function materializeAll(
  port: MaterializationPort,
  messages: MaterializableMessage[],
): Promise<MaterializationSummary> {
  const summary: MaterializationSummary = {
    candidates: messages.length,
    inserted: 0,
    alreadyExisting: 0,
    rejected: 0,
    errors: 0,
  };

  for (const message of messages) {
    const outcome = await port.insertIfAbsent(message);
    switch (outcome.kind) {
      case "inserted":
        summary.inserted++;
        break;
      case "already_exists":
        summary.alreadyExisting++;
        break;
      case "consent_no_longer_valid":
        summary.rejected++;
        break;
      case "error":
        summary.errors++;
        break;
    }
  }

  return summary;
}
