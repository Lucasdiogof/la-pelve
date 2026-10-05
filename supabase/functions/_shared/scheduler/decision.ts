// Lógica pura que decide quais mensagens de WhatsApp deveriam existir para
// um agendamento, e quando. NÃO lê o banco, NÃO envia nada, NÃO persiste
// nada — só calcula, a partir de dados já carregados. É isto que o Edge
// Function do scheduler (ainda não criado) vai chamar depois de buscar os
// dados; a regra de negócio fica aqui, não dentro da function.

import {
  applySilencePostponement,
  zonedDateTimeStringToUtc,
} from "./timezone.ts";
import {
  checkPatientEligibility,
  type ConsentForEligibility,
  type IneligibleReason,
  type PatientForEligibility,
} from "./eligibility.ts";

export type MessageType =
  | "appointment_confirmation"
  | "appointment_12h"
  | "appointment_rescheduled";

/**
 * Por que uma mensagem não é (ou ainda não pode ser avaliada como) elegível.
 * Os 4 primeiros vêm da elegibilidade do paciente; os demais são
 * específicos do agendamento/horário.
 */
export type SchedulerReason =
  | IneligibleReason
  | "appointment_cancelled"
  | "appointment_already_occurred"
  | "less_than_or_equal_12h_notice"
  | "too_close_to_immediate_message"
  | "not_applicable_for_this_revision"
  | "stale_schedule_revision";

export interface SchedulerDecision {
  eligible: boolean;
  messageType: MessageType;
  appointmentId: string;
  scheduleRevision: number;
  /** ISO 8601 UTC, ou null quando não elegível. */
  scheduledFor: string | null;
  /** null só quando eligible=true. */
  reason: SchedulerReason | null;
}

export interface AppointmentForScheduling {
  id: string;
  fisioterapeutaId: string;
  date: string; // 'YYYY-MM-DD'
  time: string; // 'HH:MM:SS'
  status: string;
  patientId: string | null;
  scheduleRevision: number;
  /**
   * Instante (ISO UTC) em que a revisão ATUAL (scheduleRevision) nasceu —
   * fonte canônica ÚNICA para calcular antecedência, para QUALQUER
   * scheduleRevision (0 ou N). Desde as migrations 0021/0022 o banco
   * garante isto como NOT NULL e, para revision 0, exatamente igual a
   * appointments.created_at (mesma escrita, pelo mesmo trigger). O
   * scheduler não precisa de created_at para nenhuma decisão: created_at
   * continua existindo na tabela com sua própria semântica (quando a
   * linha foi criada), mas não é mais uma segunda fonte temporal usada
   * aqui — evita ambiguidade entre duas datas para a mesma decisão.
   */
  scheduleRevisionAt: string;
}

export interface SchedulingInput {
  appointment: AppointmentForScheduling;
  patient: PatientForEligibility | null;
  consent: ConsentForEligibility | null;
  /** profiles.timezone do fisioterapeuta (ex.: 'America/Sao_Paulo'). */
  timeZone: string;
  /** "agora", injetado (nunca lido internamente) para testes deterministas. */
  now: Date;
}

const TWELVE_HOURS_MS = 12 * 60 * 60 * 1000;
const TWO_HOURS_MS = 2 * 60 * 60 * 1000;

function decision(
  appointment: AppointmentForScheduling,
  messageType: MessageType,
  eligible: boolean,
  scheduledFor: Date | null,
  reason: SchedulerReason | null,
): SchedulerDecision {
  return {
    eligible,
    messageType,
    appointmentId: appointment.id,
    scheduleRevision: appointment.scheduleRevision,
    scheduledFor: eligible ? scheduledFor!.toISOString() : null,
    reason: eligible ? null : reason,
  };
}

function blockAllWith(
  appointment: AppointmentForScheduling,
  reason: SchedulerReason,
): SchedulerDecision[] {
  const immediateType: MessageType =
    appointment.scheduleRevision === 0
      ? "appointment_confirmation"
      : "appointment_rescheduled";
  return [
    decision(appointment, immediateType, false, null, reason),
    decision(appointment, "appointment_12h", false, null, reason),
  ];
}

/**
 * appointment.scheduleRevisionAt precisa ser uma string não-vazia por
 * contrato do tipo (AppointmentForScheduling.scheduleRevisionAt: string,
 * nunca string | null) — o schema do banco (migrations 0021 + 0022)
 * garante NOT NULL para toda linha de appointments. Se este valor chegar
 * ausente/vazio mesmo assim, isso NÃO é uma situação de negócio (não é
 * "paciente sem telefone" ou "consulta já cancelada"): é um bug de quem
 * montou o SchedulingInput antes de chamar esta função — nenhum dado real
 * do banco pode produzir isso. Por isso falha de forma explícita (throw),
 * em vez de devolver um `reason` como se fosse um cenário de negócio
 * normal, o que esconderia o bug real atrás de uma decisão "inelegível"
 * aparentemente legítima.
 */
function assertValidSchedulingInput(appointment: AppointmentForScheduling): void {
  if (!appointment.scheduleRevisionAt) {
    throw new TypeError(
      `decideMessagesForAppointment: appointment.scheduleRevisionAt ausente para appointment ${appointment.id} ` +
        `(scheduleRevision=${appointment.scheduleRevision}). O schema do banco garante NOT NULL; isto indica um ` +
        `bug em quem montou o SchedulingInput, não um caso de negócio.`,
    );
  }
}

/**
 * "Mensagem imediata" desta revisão: appointment_confirmation na revision 0,
 * appointment_rescheduled nas revisions >= 1. O horário nominal é sempre
 * appointment.scheduleRevisionAt (o instante em que esta revisão nasceu),
 * ajustado pelo silêncio 22:00–06:59.
 */
function computeImmediateMessageDecision(
  appointment: AppointmentForScheduling,
  appointmentStart: Date,
  timeZone: string,
): SchedulerDecision {
  const messageType: MessageType =
    appointment.scheduleRevision === 0
      ? "appointment_confirmation"
      : "appointment_rescheduled";

  const effective = applySilencePostponement(
    new Date(appointment.scheduleRevisionAt),
    timeZone,
  );
  if (effective.getTime() >= appointmentStart.getTime()) {
    return decision(appointment, messageType, false, null, "appointment_already_occurred");
  }
  return decision(appointment, messageType, true, effective, null);
}

/**
 * appointment_12h: só existe se, no momento em que a revisão atual nasceu
 * (scheduleRevisionAt), a antecedência for ESTRITAMENTE maior que 12h.
 * Depois aplica o silêncio e, por fim, a regra dos 2h contra a mensagem
 * imediata desta mesma revisão (que tem prioridade: appointment_confirmation
 * na revision 0, appointment_rescheduled nas demais).
 */
function computeAppointment12hDecision(
  appointment: AppointmentForScheduling,
  appointmentStart: Date,
  timeZone: string,
  immediateEffective: Date | null,
): SchedulerDecision {
  const referenceMoment = new Date(appointment.scheduleRevisionAt);
  const noticeMs = appointmentStart.getTime() - referenceMoment.getTime();
  if (noticeMs <= TWELVE_HOURS_MS) {
    return decision(appointment, "appointment_12h", false, null, "less_than_or_equal_12h_notice");
  }

  const nominal = new Date(appointmentStart.getTime() - TWELVE_HOURS_MS);
  const effective = applySilencePostponement(nominal, timeZone);

  if (effective.getTime() >= appointmentStart.getTime()) {
    return decision(appointment, "appointment_12h", false, null, "appointment_already_occurred");
  }

  if (
    immediateEffective !== null &&
    effective.getTime() - immediateEffective.getTime() < TWO_HOURS_MS
  ) {
    return decision(appointment, "appointment_12h", false, null, "too_close_to_immediate_message");
  }

  return decision(appointment, "appointment_12h", true, effective, null);
}

/**
 * Decide as mensagens desta revisão do agendamento. Sempre devolve 2
 * decisões: a "imediata" (confirmation na revision 0, rescheduled nas
 * demais) e a de appointment_12h — nunca omite uma mensagem inelegível,
 * sempre explica o motivo em `reason`.
 *
 * Pura: não lê o banco, não envia nada, não persiste nada. Não consulta
 * whatsapp_messages existentes — decide apenas "esta mensagem deveria
 * existir?"; "pode ser enviada pela Meta?" e "já existe/já foi enviada?"
 * são responsabilidades de camadas futuras (dispatch e persistência,
 * protegida pela UNIQUE appointment_id+reminder_type+schedule_revision).
 */
export function decideMessagesForAppointment(input: SchedulingInput): SchedulerDecision[] {
  const { appointment, patient, consent, timeZone, now } = input;

  assertValidSchedulingInput(appointment);

  if (appointment.status === "cancelled") {
    return blockAllWith(appointment, "appointment_cancelled");
  }

  const eligibility = checkPatientEligibility({
    appointmentPatientId: appointment.patientId,
    appointmentFisioterapeutaId: appointment.fisioterapeutaId,
    patient,
    consent,
  });
  if (!eligibility.eligible) {
    return blockAllWith(appointment, eligibility.reason);
  }

  const appointmentStart = zonedDateTimeStringToUtc(
    appointment.date,
    appointment.time,
    timeZone,
  );

  if (now.getTime() >= appointmentStart.getTime()) {
    return blockAllWith(appointment, "appointment_already_occurred");
  }

  const immediate = computeImmediateMessageDecision(appointment, appointmentStart, timeZone);
  const reminder12h = computeAppointment12hDecision(
    appointment,
    appointmentStart,
    timeZone,
    immediate.eligible ? new Date(immediate.scheduledFor!) : null,
  );

  return [immediate, reminder12h];
}

/**
 * appointment_confirmation só é válida na revision em que o agendamento foi
 * criado (0); appointment_rescheduled só é válida a partir da 1ª remarcação
 * (revision >= 1) — o mesmo que o CHECK de banco
 * whatsapp_messages_schedule_revision_matches_type já impõe. Útil para quem
 * for pedir uma decisão de um tipo específico fora do fluxo normal de
 * decideMessagesForAppointment (que já escolhe o tipo certo sozinho).
 */
export function isMessageTypeApplicableForRevision(
  messageType: MessageType,
  scheduleRevision: number,
): boolean {
  if (messageType === "appointment_confirmation") return scheduleRevision === 0;
  if (messageType === "appointment_rescheduled") return scheduleRevision >= 1;
  return true; // appointment_12h: qualquer revisão
}

/**
 * Uma mensagem ainda pendente (scheduled/processing) está desatualizada
 * (stale) se a revisão para a qual ela nasceu não é mais a revisão atual do
 * agendamento. O scheduler futuro NUNCA deve enviá-la nesse caso — deve
 * marcá-la como cancelled.
 *
 * Deliberadamente separada de decideMessagesForAppointment (que calcula a
 * revisão ATUAL): esta função serve à camada futura que varre
 * whatsapp_messages já persistidas, um conceito diferente de "quais
 * mensagens deveriam existir agora".
 */
export function isStaleRevision(
  messageScheduleRevision: number,
  currentAppointmentScheduleRevision: number,
): boolean {
  return messageScheduleRevision !== currentAppointmentScheduleRevision;
}

/** now >= appointmentStart. */
export function hasAppointmentAlreadyOccurred(appointmentStart: Date, now: Date): boolean {
  return now.getTime() >= appointmentStart.getTime();
}
