// FakeWhatsappProvider para testes: registra os envios e devolve respostas
// programadas. Nunca toca rede.

import type { ProviderSendRequest, ProviderSendResult, WhatsappProvider } from "./types.ts";

export interface FakeWhatsappProvider extends WhatsappProvider {
  readonly sent: ProviderSendRequest[];
}

export function createFakeWhatsappProvider(
  respond: (request: ProviderSendRequest, index: number) => ProviderSendResult | Promise<ProviderSendResult> =
    (_request, index) => ({ kind: "sent", wamid: `wamid.fake-${index + 1}` }),
): FakeWhatsappProvider {
  const sent: ProviderSendRequest[] = [];
  return {
    sent,
    async sendTemplate(request) {
      sent.push(request);
      return await respond(request, sent.length - 1);
    },
  };
}
