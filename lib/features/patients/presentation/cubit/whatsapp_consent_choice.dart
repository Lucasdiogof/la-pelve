import 'package:la_pelve/features/patients/domain/entities/patient_consent.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patient_form_state.dart';

/// Resolve o valor do switch "Receber lembretes pelo WhatsApp" para o
/// telefone ATUAL do formulário.
///
/// A escolha é por número, nunca por "último valor visto": trocar o
/// telefone e voltar ao original não deve depender de qual foi o caminho
/// percorrido entre os dois, só do número final e de uma eventual escolha
/// manual já feita especificamente para esse número.
///
/// Prioridade:
/// 1. Telefone atual inválido (não é celular BR) -> sempre desligado.
/// 2. Escolha manual já feita para o telefone atual (`manualConsentChoices`)
///    -> vale, mesmo que o profissional tenha passado por outros números
///    entre a escolha e agora.
/// 3. Sem escolha manual para o telefone atual -> liga só se bate com o
///    número que já tinha consentimento ativo quando o formulário abriu.
bool resolveWhatsappConsentChoice({
  required PatientConsent? originalConsent,
  required PatientFormState formState,
}) {
  final phoneE164 = formState.patient.personalInfo.phoneE164;
  if (phoneE164 == null) return false;

  final manualChoice = formState.manualConsentChoices[phoneE164];
  if (manualChoice != null) return manualChoice;

  return originalConsent != null && originalConsent.contactValue == phoneE164;
}
