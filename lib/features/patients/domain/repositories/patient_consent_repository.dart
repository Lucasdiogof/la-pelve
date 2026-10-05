import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_consent.dart';

abstract class PatientConsentRepository {
  /// Consentimento ativo (revoked_at nulo) para o paciente/canal/finalidade.
  /// Retorna Success(null) quando nao ha nenhum.
  Future<Result<PatientConsent?>> getActive({
    required String patientId,
    required String channel,
    required String purpose,
  });

  Future<Result<PatientConsent>> grant({
    required String patientId,
    required String channel,
    required String purpose,
    required String contactValue,
    required String source,
  });

  Future<Result<void>> revoke(String consentId);
}
