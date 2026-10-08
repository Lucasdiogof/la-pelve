// Tipos do DISPATCH: envio real das mensagens de whatsapp_messages pela
// WhatsApp Cloud API. Nenhum I/O aqui -- só forma.

import type { MessageType } from "../scheduler/decision.ts";

/** Linha reservada por claim_whatsapp_messages_for_dispatch (migration 0026). */
export interface ClaimedMessage {
  messageId: string;
  leaseToken: string;
  reminderType: MessageType;
}

/**
 * Dados para 1 envio, devolvidos por prepare_whatsapp_message_send depois de
 * revalidar tudo. accessToken só existe em memória durante o envio: nunca é
 * logado, persistido ou devolvido em resumo.
 */
export interface PreparedSend {
  reminderType: MessageType;
  attemptCount: number;
  destinationPhoneE164: string;
  patientFirstName: string;
  /** 'YYYY-MM-DD' (data civil da consulta no fuso do profissional). */
  appointmentDate: string;
  /** 'HH:MM'. */
  appointmentTime: string;
  timeZone: string;
  phoneNumberId: string;
  accessToken: string;
}

export type PrepareResult =
  | { kind: "ready"; send: PreparedSend }
  /** Inválida para sempre (ex.: consentimento revogado): o banco já cancelou. */
  | { kind: "cancelled"; code: string }
  /** Bloqueio temporário (ex.: conexão inativa): o banco já devolveu à fila. */
  | { kind: "deferred"; code: string }
  /** Outra execução assumiu a linha ou a lease venceu. */
  | { kind: "lease_lost" };

/** Erro persistível: só códigos, nunca texto livre nem token. */
export interface DispatchError {
  code: string;
  http_status?: number;
  provider_code?: number;
  provider_subcode?: number;
}

export type CompletionInput =
  | { result: "sent"; wamid: string; templateName: string }
  | { result: "retry"; retryDelaySeconds: number; error: DispatchError }
  | { result: "failed"; templateName: string | null; error: DispatchError };

/**
 * Porta de persistência do dispatch (RPCs da migration 0026). Os métodos
 * podem lançar em falha de rede/banco; o dispatcher trata.
 */
export interface DispatchStore {
  claim(input: { limit: number; leaseSeconds: number; reminderTypes: MessageType[] }): Promise<ClaimedMessage[]>;
  prepare(messageId: string, leaseToken: string): Promise<PrepareResult>;
  complete(messageId: string, leaseToken: string, completion: CompletionInput): Promise<"ok" | "lease_lost">;
}

/** Payload JSON de envio de template da Cloud API (POST /{phone_number_id}/messages). */
export interface MetaTemplateMessage {
  messaging_product: "whatsapp";
  recipient_type: "individual";
  to: string;
  type: "template";
  template: {
    name: string;
    language: { code: string };
    components: Array<Record<string, unknown>>;
  };
}

export interface ProviderSendRequest {
  phoneNumberId: string;
  accessToken: string;
  message: MetaTemplateMessage;
}

/**
 * Resultado classificado de 1 envio. Sem texto livre do provedor.
 *  - sent:      aceito; wamid devolvido.
 *  - retryable: recusado de forma temporária (429/limite, 5xx): NÃO foi aceito.
 *  - rejected:  recusado de forma definitiva (4xx, token inválido...).
 *  - unknown:   não dá para saber se foi aceito (timeout, rede, 2xx inválido):
 *               NUNCA reenviar, senão a paciente pode receber duas vezes.
 */
export type ProviderSendResult =
  | { kind: "sent"; wamid: string }
  | { kind: "retryable"; code: string; httpStatus?: number; providerCode?: number; providerSubcode?: number; retryAfterSeconds?: number }
  | { kind: "rejected"; code: string; httpStatus?: number; providerCode?: number; providerSubcode?: number }
  | { kind: "unknown"; code: string; httpStatus?: number };

export interface WhatsappProvider {
  /** Nunca lança: toda falha vira um ProviderSendResult. */
  sendTemplate(request: ProviderSendRequest): Promise<ProviderSendResult>;
}

/** Nome do template aprovado na Meta, por tipo. Tipo sem template não é enviado. */
export type TemplateNames = Partial<Record<MessageType, string>>;

export interface TemplateConfig {
  names: TemplateNames;
  /** Ex.: 'pt_BR'. */
  languageCode: string;
}

/** Agregado público: só contagens. */
export interface DispatchSummary {
  claimed: number;
  sent: number;
  retried: number;
  failed: number;
  unknownOutcome: number;
  cancelled: number;
  deferred: number;
  leaseLost: number;
  errors: number;
}
