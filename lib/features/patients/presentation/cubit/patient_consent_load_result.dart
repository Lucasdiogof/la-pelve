import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_consent.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_consent_repository.dart';

/// Resultado de carregar o consentimento ativo de WhatsApp ao abrir o
/// formulário. Existem só dois casos válidos: achou um consentimento ativo,
/// ou confirmou que não existe nenhum. Uma falha de leitura NUNCA é tratada
/// como "não existe consentimento" — ela tem seu próprio caso, para que a
/// UI nunca monte o formulário com uma informação potencialmente falsa.
sealed class PatientConsentLoadResult {
  const PatientConsentLoadResult();
}

class PatientConsentLoadSucceeded extends PatientConsentLoadResult {
  const PatientConsentLoadSucceeded(this.consent);

  /// null significa, de fato, que não há consentimento ativo.
  final PatientConsent? consent;
}

class PatientConsentLoadFailed extends PatientConsentLoadResult {
  const PatientConsentLoadFailed(this.failure);

  final Failure failure;
}

/// Busca o consentimento ativo de WhatsApp (appointment_reminder) do
/// paciente. O [repository] já é responsável por nunca deixar a chamada
/// pendente para sempre (timeout próprio) e por nunca lançar uma exceção
/// não tratada — esta função só traduz o [Result] dele num resultado que
/// distingue "sem consentimento" de "não consegui saber".
Future<PatientConsentLoadResult> loadActiveWhatsappConsent({
  required PatientConsentRepository repository,
  required String patientId,
}) async {
  final result = await repository.getActive(
    patientId: patientId,
    channel: kWhatsappChannel,
    purpose: kAppointmentReminderPurpose,
  );
  return switch (result) {
    Success(:final data) => PatientConsentLoadSucceeded(data),
    Error(:final failure) => PatientConsentLoadFailed(failure),
  };
}
