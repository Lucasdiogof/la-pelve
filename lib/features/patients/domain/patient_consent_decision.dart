import 'package:equatable/equatable.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_consent.dart';

/// O que fazer com o consentimento de WhatsApp ao salvar o formulário,
/// dado o consentimento ativo que já existia (se algum), o telefone atual
/// do paciente e a escolha atual do profissional no switch.
///
/// Trocar o telefone invalida o consentimento antigo para o número novo:
/// o histórico sempre fica como "número A -> revoked_at" seguido, se o
/// profissional reativar, de "número B -> ativo".
class PatientConsentDecision extends Equatable {
  const PatientConsentDecision({
    required this.mustRevokeOriginal,
    required this.mustGrantNew,
  });

  factory PatientConsentDecision.compute({
    required PatientConsent? original,
    required String? newContactValue,
    required bool choice,
  }) {
    final numberChanged =
        original != null && original.contactValue != newContactValue;
    return PatientConsentDecision(
      mustRevokeOriginal: original != null && (numberChanged || !choice),
      mustGrantNew: choice && (original == null || numberChanged),
    );
  }

  final bool mustRevokeOriginal;
  final bool mustGrantNew;

  @override
  List<Object?> get props => [mustRevokeOriginal, mustGrantNew];
}
