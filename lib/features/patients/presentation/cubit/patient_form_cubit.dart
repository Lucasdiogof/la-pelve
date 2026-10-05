import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/l10n/app_language.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_consent.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_enums.dart';
import 'package:la_pelve/features/patients/l10n/patients_strings.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patient_form_state.dart';
import 'package:la_pelve/features/patients/presentation/cubit/whatsapp_consent_choice.dart';
import 'package:la_pelve/features/patients/presentation/widgets/attachment_picker_sheet.dart';
import 'package:la_pelve/shared/utils/id_generator.dart';
import 'package:la_pelve/shared/utils/validators.dart';

enum PatientFormStep {
  personalInfo,
  medicalHistory,
  gynecologicalHistory,
  obstetricHistory,
  surgicalHistory,
  urinaryFunction,
  sexualFunction,
  bowelFunction,
  treatmentPlan,
  assessmentForm,
  consultationFee,
}

extension PatientFormStepTitle on PatientFormStep {
  String title(AppLanguage language) {
    final t = PatientsStrings(language);
    return switch (this) {
      PatientFormStep.personalInfo => t.sectionPersonalData,
      PatientFormStep.medicalHistory => t.sectionAnamnesis,
      PatientFormStep.gynecologicalHistory => t.sectionGynecologicalHistory,
      PatientFormStep.obstetricHistory => t.sectionObstetricHistory,
      PatientFormStep.surgicalHistory => t.sectionSurgicalHistory,
      PatientFormStep.urinaryFunction => t.sectionUrinaryFunction,
      PatientFormStep.sexualFunction => t.sectionSexualFunction,
      PatientFormStep.bowelFunction => t.sectionBowelFunction,
      PatientFormStep.treatmentPlan => t.sectionTreatmentPlan,
      PatientFormStep.assessmentForm => t.sectionAssessmentForm,
      PatientFormStep.consultationFee => t.sectionConsultationFee,
    };
  }
}

class PatientFormCubit extends Cubit<PatientFormState> {
  PatientFormCubit({Patient? existingPatient, PatientConsent? existingConsent})
    : isEditing = existingPatient != null,
      originalConsent = existingConsent,
      super(
        PatientFormState(
          patient:
              existingPatient ??
              Patient(id: generateId(), createdAt: DateTime.now()),
        ),
      );

  final bool isEditing;

  /// Consentimento ativo (whatsapp/appointment_reminder) que já existia
  /// quando o formulário foi aberto, carregado antes da criação deste cubit.
  /// Null quando o paciente é novo ou não havia consentimento ativo.
  final PatientConsent? originalConsent;

  List<PatientFormStep> get _visibleSteps {
    // "Outro" gets the full superset of anatomy-specific sections: better to
    // ask an extra question that doesn't apply than to silently skip one that
    // does, since gender identity alone doesn't tell us patient anatomy.
    final gender = state.patient.personalInfo.gender;
    final showFemaleSpecificSteps =
        gender == Gender.female || gender == Gender.other;
    return [
      PatientFormStep.personalInfo,
      PatientFormStep.medicalHistory,
      if (showFemaleSpecificSteps) PatientFormStep.gynecologicalHistory,
      if (showFemaleSpecificSteps) PatientFormStep.obstetricHistory,
      PatientFormStep.surgicalHistory,
      PatientFormStep.urinaryFunction,
      PatientFormStep.sexualFunction,
      PatientFormStep.bowelFunction,
      PatientFormStep.treatmentPlan,
      PatientFormStep.assessmentForm,
      PatientFormStep.consultationFee,
    ];
  }

  int get stepCount => _visibleSteps.length;

  PatientFormStep get currentStep => _visibleSteps[state.stepIndex];

  String currentStepTitle(AppLanguage language) => currentStep.title(language);

  void updatePatient(Patient patient) => emit(state.copyWith(patient: patient));

  /// Valor exibido do switch "Receber lembretes pelo WhatsApp" para o
  /// telefone atual. Nunca é guardado como um booleano solto: é sempre
  /// resolvido na hora a partir do telefone atual, de uma eventual escolha
  /// manual já feita para esse número (ver [PatientFormState.manualConsentChoices])
  /// e do consentimento que já existia quando o formulário abriu. Isso evita
  /// que trocar o telefone e voltar ao original (A -> B -> A) dependa do
  /// caminho percorrido.
  bool get whatsappReminderConsent => resolveWhatsappConsentChoice(
    originalConsent: originalConsent,
    formState: state,
  );

  /// true quando havia consentimento ativo para um número diferente do
  /// telefone atual do paciente (telefone foi trocado desde então).
  bool get whatsappConsentPhoneChanged =>
      originalConsent != null &&
      originalConsent!.contactValue != state.patient.personalInfo.phoneE164;

  /// Registra a escolha manual do profissional para o telefone atual. É
  /// um no-op quando o telefone atual não é um celular BR válido (nada para
  /// autorizar). A escolha fica associada a esse número especificamente:
  /// trocar de telefone não a apaga, só deixa de valer até, se for o caso,
  /// o profissional voltar para esse mesmo número.
  void setWhatsappConsent(bool value) {
    final phoneE164 = state.patient.personalInfo.phoneE164;
    if (phoneE164 == null) return;
    final updatedChoices = Map<String, bool>.from(state.manualConsentChoices)
      ..[phoneE164] = value;
    emit(state.copyWith(manualConsentChoices: updatedChoices));
  }

  void addAssessmentFile(PickedAttachmentFile file) {
    emit(state.copyWith(assessmentFiles: [...state.assessmentFiles, file]));
  }

  void removeAssessmentFile(int index) {
    final files = [...state.assessmentFiles]..removeAt(index);
    emit(state.copyWith(assessmentFiles: files));
  }

  void nextStep() {
    if (!canProceed || state.stepIndex >= stepCount - 1) return;
    emit(state.copyWith(stepIndex: state.stepIndex + 1));
  }

  void previousStep() {
    if (state.stepIndex > 0) {
      emit(state.copyWith(stepIndex: state.stepIndex - 1));
    }
  }

  bool get isLastStep => state.stepIndex == stepCount - 1;

  bool get _personalInfoValid {
    final personalInfo = state.patient.personalInfo;
    return personalInfo.name.trim().length > 2 &&
        personalInfo.gender != null &&
        isValidPhone(personalInfo.phone);
  }

  bool get canProceed {
    if (currentStep != PatientFormStep.personalInfo) return true;
    return _personalInfoValid;
  }

  bool get canSave => isEditing && _personalInfoValid;
}
