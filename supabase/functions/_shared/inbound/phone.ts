// Remetente da Meta (wa_id, só dígitos) -> formas E.164 que identificam o
// MESMO número. Puro.
//
// Celular brasileiro: patients.phone_e164 / destination_phone_e164 sempre
// têm o 9 depois do DDD (+55 DD 9XXXX-XXXX, ver normalizeBrMobileToE164 no
// app). O WhatsApp ainda identifica muitas contas antigas SEM esse 9
// (55 DD XXXX-XXXX, 12 dígitos). Para essas, devolve também a forma com o 9,
// senão a resposta de uma paciente legítima nunca casaria com a solicitação.

const WA_ID_RE = /^[1-9][0-9]{7,14}$/;
/** 55 + DDD (2) + 8 dígitos começando em 6-9 (faixa de celular antes do 9). */
const BR_MOBILE_WITHOUT_NINE_RE = /^55([1-9][0-9])([6-9][0-9]{7})$/;

export function senderE164Candidates(fromWaId: string): string[] | null {
  if (!WA_ID_RE.test(fromWaId)) return null;
  const asIs = `+${fromWaId}`;
  const match = BR_MOBILE_WITHOUT_NINE_RE.exec(fromWaId);
  if (!match) return [asIs];
  return [asIs, `+55${match[1]}9${match[2]}`];
}
