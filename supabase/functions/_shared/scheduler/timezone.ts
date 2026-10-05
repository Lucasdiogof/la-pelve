// Conversão entre horário civil (data+hora "de parede") e instante absoluto
// UTC, usando só Intl.DateTimeFormat com timeZone IANA — nativo em Deno e em
// Node, sem nenhuma dependência externa. Isso é o que permite respeitar
// corretamente o fuso do profissional (profiles.timezone, ex.:
// America/Sao_Paulo) sem jamais assumir um offset fixo como -03:00: o offset
// real da timezone IANA naquele instante específico é lido do banco de dados
// de fusos horários (ICU) embutido no runtime, então mudanças de DST (em
// fusos que as têm) são respeitadas automaticamente.

export interface LocalParts {
  year: number;
  month: number; // 1-12
  day: number;
  hour: number; // 0-23
  minute: number;
  second: number;
}

/** Componentes locais (ano/mês/dia/hora/min/seg) de um instante UTC, numa timezone IANA. */
export function getLocalParts(instantUtc: Date, timeZone: string): LocalParts {
  const dtf = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
  const parts = dtf.formatToParts(instantUtc);
  const map: Record<string, string> = {};
  for (const p of parts) map[p.type] = p.value;
  return {
    year: Number(map.year),
    month: Number(map.month),
    day: Number(map.day),
    hour: Number(map.hour === "24" ? "0" : map.hour),
    minute: Number(map.minute),
    second: Number(map.second),
  };
}

function offsetMinutesAt(timeZone: string, instantUtc: Date): number {
  const local = getLocalParts(instantUtc, timeZone);
  const asIfUtc = Date.UTC(
    local.year,
    local.month - 1,
    local.day,
    local.hour,
    local.minute,
    local.second,
  );
  // Se o relogio local esta "na frente" do UTC (ex.: UTC+2), asIfUtc > instantUtc.
  return (asIfUtc - instantUtc.getTime()) / 60000;
}

/**
 * Converte um horário civil (ano/mês/dia/hora/min/seg, "de parede") numa
 * timezone IANA para o instante UTC absoluto correspondente. Faz 1 iteração
 * extra para ficar correto mesmo perto de uma transição de DST (o offset no
 * instante final pode diferir do offset no palpite inicial).
 */
export function zonedTimeToUtc(
  year: number,
  month: number,
  day: number,
  hour: number,
  minute: number,
  second: number,
  timeZone: string,
): Date {
  const guessUtcMillis = Date.UTC(year, month - 1, day, hour, minute, second);
  const offset1 = offsetMinutesAt(timeZone, new Date(guessUtcMillis));
  const candidateMillis = guessUtcMillis - offset1 * 60000;
  const offset2 = offsetMinutesAt(timeZone, new Date(candidateMillis));
  if (offset2 !== offset1) {
    return new Date(guessUtcMillis - offset2 * 60000);
  }
  return new Date(candidateMillis);
}

/** Variante que recebe date 'YYYY-MM-DD' e time 'HH:MM:SS' (formato do Postgres). */
export function zonedDateTimeStringToUtc(
  dateStr: string,
  timeStr: string,
  timeZone: string,
): Date {
  const [year, month, day] = dateStr.split("-").map(Number);
  const [hour, minute, second] = timeStr.split(":").map(Number);
  return zonedTimeToUtc(year, month, day, hour, minute, second ?? 0, timeZone);
}

/** 22:00 até 06:59 (inclusive) no horário local da timezone dada. */
export function isInSilentHours(instantUtc: Date, timeZone: string): boolean {
  const { hour } = getLocalParts(instantUtc, timeZone);
  return hour >= 22 || hour < 7;
}

/**
 * Se o instante cair no silêncio (22:00–06:59 local), devolve 07:00 local
 * do dia certo: mesmo dia civil se a hora local for 00:00–06:59; dia civil
 * seguinte se for 22:00–23:59. Fora do silêncio, devolve o instante
 * inalterado.
 */
export function applySilencePostponement(instantUtc: Date, timeZone: string): Date {
  const local = getLocalParts(instantUtc, timeZone);
  if (local.hour >= 7 && local.hour < 22) {
    return instantUtc;
  }
  const dayOffset = local.hour >= 22 ? 1 : 0;
  // Date.UTC normaliza o overflow do dia (ex.: day 32 -> vira o mês seguinte),
  // então somar 1 ao "day" civil antes de re-converter é seguro mesmo no
  // último dia do mês/ano.
  const nextCivilDayAsUtc = new Date(
    Date.UTC(local.year, local.month - 1, local.day + dayOffset),
  );
  return zonedTimeToUtc(
    nextCivilDayAsUtc.getUTCFullYear(),
    nextCivilDayAsUtc.getUTCMonth() + 1,
    nextCivilDayAsUtc.getUTCDate(),
    7,
    0,
    0,
    timeZone,
  );
}
