import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/patients/domain/entities/attachment.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_consent.dart';
import 'package:la_pelve/features/patients/domain/patient_consent_decision.dart';
import 'package:la_pelve/features/patients/domain/repositories/attachment_repository.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_consent_repository.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patient_form_cubit.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patient_form_state.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/features/patients/presentation/cubit/whatsapp_consent_choice.dart';

/// Resultado de uma tentativa de salvar o formulário de paciente.
sealed class PatientSaveOutcome {
  const PatientSaveOutcome();
}

class PatientSaveSucceeded extends PatientSaveOutcome {
  const PatientSaveSucceeded({
    required this.isEditing,
    required this.consentFailed,
    this.savedOnlyOnDevice = false,
    this.onlineStepsSkipped = false,
  });

  /// O paciente só existe neste aparelho (ainda não chegou ao servidor).
  final bool savedOnlyOnDevice;

  /// Anexos/consentimento que dependiam de internet ficaram para depois.
  final bool onlineStepsSkipped;

  final bool isEditing;

  /// true quando o paciente foi salvo com sucesso, mas a reconciliação do
  /// consentimento de WhatsApp (revogar/criar) falhou. O cadastro do
  /// paciente NUNCA é desfeito por causa disso.
  final bool consentFailed;
}

class PatientSaveFailed extends PatientSaveOutcome {
  const PatientSaveFailed(this.failure);

  final Failure failure;
}

/// Orquestra salvar o paciente, subir os anexos da ficha de avaliação e
/// reconciliar o consentimento de WhatsApp, nesta ordem, com uma única
/// responsabilidade extra: nunca deixar duas chamadas a [save] rodarem em
/// paralelo. Uma segunda chamada enquanto a primeira ainda está em
/// andamento é ignorada (retorna null) em vez de disparar uma segunda
/// gravação.
///
/// É uma classe comum (não um Cubit) de propósito: não tem estado de UI,
/// só orquestra repositórios, o que a deixa testável sem widget nenhum.
class PatientFormSaveController {
  PatientFormSaveController({
    required this.patientsCubit,
    required this.attachmentRepository,
    required this.consentRepository,
    this.ensureOnServer,
  });

  /// Garante que o paciente já está no servidor antes de anexos e
  /// consentimento (que o referenciam). Null = gravação já foi direta.
  final Future<bool> Function(String patientId)? ensureOnServer;

  final PatientsCubit patientsCubit;
  final AttachmentRepository attachmentRepository;
  final PatientConsentRepository consentRepository;

  bool _isSaving = false;

  bool get isSaving => _isSaving;

  /// Retorna null quando uma gravação já estava em andamento: a chamada é
  /// ignorada, não enfileirada e não reiniciada.
  Future<PatientSaveOutcome?> save({
    required PatientFormCubit formCubit,
    required PatientFormState state,
  }) async {
    if (_isSaving) return null;
    _isSaving = true;
    try {
      final patientResult = formCubit.isEditing
          ? await patientsCubit.updatePatient(state.patient)
          : await patientsCubit.addPatient(state.patient);

      if (patientResult case Error(:final failure)) {
        return PatientSaveFailed(failure);
      }

      final ensure = ensureOnServer;
      final onServer = ensure == null || await ensure(state.patient.id);
      if (!onServer) {
        final consentPending =
            !formCubit.consentUnavailable &&
            _consentNeedsServer(formCubit, state);
        return PatientSaveSucceeded(
          isEditing: formCubit.isEditing,
          consentFailed: false,
          savedOnlyOnDevice: true,
          onlineStepsSkipped:
              state.assessmentFiles.isNotEmpty || consentPending,
        );
      }

      if (state.assessmentFiles.isNotEmpty) {
        for (final file in state.assessmentFiles) {
          await attachmentRepository.upload(
            patientId: state.patient.id,
            category: AttachmentCategory.assessmentForm,
            bytes: file.bytes,
            fileName: file.fileName,
            contentType: file.contentType,
          );
        }
      }

      var consentFailed = false;
      if (!formCubit.consentUnavailable) {
        try {
          await _reconcileWhatsappConsent(formCubit, state);
        } catch (_) {
          consentFailed = true;
        }
      }

      return PatientSaveSucceeded(
        isEditing: formCubit.isEditing,
        consentFailed: consentFailed,
      );
    } finally {
      _isSaving = false;
    }
  }

  bool _consentNeedsServer(PatientFormCubit formCubit, PatientFormState state) {
    final decision = PatientConsentDecision.compute(
      original: formCubit.originalConsent,
      newContactValue: state.patient.personalInfo.phoneE164,
      choice: resolveWhatsappConsentChoice(
        originalConsent: formCubit.originalConsent,
        formState: state,
      ),
    );
    return decision.mustRevokeOriginal || decision.mustGrantNew;
  }

  /// Nunca desfaz nem altera o cadastro do paciente: uma falha aqui só é
  /// relatada ao chamador (via exceção, traduzida em [PatientSaveSucceeded
  /// .consentFailed]), nunca propagada como falha de salvar o paciente.
  ///
  /// Ordem obrigatória: só tenta criar o consentimento novo se a revogação
  /// do antigo (quando necessária) tiver sucesso — por isso o `throw` sai
  /// da função antes de chegar ao bloco de criação.
  Future<void> _reconcileWhatsappConsent(
    PatientFormCubit formCubit,
    PatientFormState state,
  ) async {
    final original = formCubit.originalConsent;
    final newPhoneE164 = state.patient.personalInfo.phoneE164;
    final choice = resolveWhatsappConsentChoice(
      originalConsent: original,
      formState: state,
    );
    final decision = PatientConsentDecision.compute(
      original: original,
      newContactValue: newPhoneE164,
      choice: choice,
    );

    if (decision.mustRevokeOriginal) {
      final result = await consentRepository.revoke(original!.id);
      if (result is Error) throw StateError('revoke failed');
    }
    if (decision.mustGrantNew) {
      final result = await consentRepository.grant(
        patientId: state.patient.id,
        channel: kWhatsappChannel,
        purpose: kAppointmentReminderPurpose,
        contactValue: newPhoneE164!,
        source: kPatientFormConsentSource,
      );
      if (result is Error) throw StateError('grant failed');
    }
  }
}
