// Tipos da camada INBOUND do WhatsApp: mensagens que a paciente envia para o
// número do profissional (resposta à solicitação de confirmação). Nenhum
// I/O aqui -- só forma.

/** Tipos de mensagem recebida que a camada sabe ler. Outros são ignorados. */
export type InboundMessageType = "text" | "button" | "interactive";

/**
 * Uma mensagem recebida, já extraída de forma defensiva do payload da Meta.
 * Carrega o texto/payload só em memória, para classificar a intenção;
 * nada disto (texto, telefone) é logado nem persistido.
 */
export interface InboundMessage {
  /** messages[].id (wamid da mensagem recebida). */
  wamid: string;
  /** value.metadata.phone_number_id: o número do profissional que recebeu. */
  phoneNumberId: string;
  /** messages[].from (wa_id, só dígitos, sem "+"). */
  fromWaId: string;
  /** messages[].timestamp convertido para ISO 8601 UTC. */
  receivedAt: string;
  type: InboundMessageType;
  /** text.body, button.text ou interactive.button_reply.title. */
  text: string | null;
  /** button.payload ou interactive.button_reply.id. */
  buttonPayload: string | null;
  /** messages[].context.id: a mensagem NOSSA que a paciente citou. */
  contextWamid: string | null;
}

export interface ParsedWebhook {
  messages: InboundMessage[];
  /** statuses[] (sent/delivered/read/failed): não são mensagens da paciente. */
  ignoredStatuses: number;
  /** Mensagens com campo essencial ausente/inválido ou de tipo não suportado. */
  ignoredMessages: number;
}

/** Resultados possíveis de process_whatsapp_confirmation_reply (migration 0025). */
export type ConfirmationReplyResult =
  | "confirmed"
  | "already_confirmed"
  | "duplicate"
  | "no_pending_request"
  | "ambiguous"
  | "request_expired"
  | "request_stale"
  | "consent_revoked"
  | "appointment_status_incompatible";

export interface ConfirmationReplyInput {
  wamid: string;
  phoneNumberId: string;
  /** 1 ou 2 formas E.164 do MESMO remetente (ver phone.ts). */
  fromE164Candidates: string[];
  receivedAt: string;
  messageType: InboundMessageType;
  contextWamid: string | null;
}

/**
 * error.code é interno e genérico: nunca o texto bruto do PostgREST, que
 * poderia conter dados da linha.
 */
export type ConfirmationReplyOutcome =
  | { kind: "processed"; result: ConfirmationReplyResult }
  | { kind: "error"; code: "persistence_error" };

/**
 * Porta de persistência. NUNCA lança: qualquer falha vira
 * { kind: 'error' }. Toda a decisão (correlação, status, idempotência)
 * acontece numa única transação no banco.
 */
export interface ConfirmationReplyPort {
  processConfirmationReply(input: ConfirmationReplyInput): Promise<ConfirmationReplyOutcome>;
}

/** Agregado para log/resposta: só contagens, nunca ids, telefone ou texto. */
export interface InboundSummary {
  messages: number;
  ignoredStatuses: number;
  ignoredMessages: number;
  /** Mensagens que não são confirmação inequívoca (negativa, ambígua, outra). */
  notConfirmation: number;
  results: Partial<Record<ConfirmationReplyResult, number>>;
  errors: number;
}
