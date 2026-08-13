import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patient_form_state.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/attachment_picker_sheet.dart';
import 'package:fisioterapia_pelvica/shared/utils/id_generator.dart';
import 'package:fisioterapia_pelvica/shared/utils/validators.dart';

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
  String get title => switch (this) {
    PatientFormStep.personalInfo => 'Dados pessoais',
    PatientFormStep.medicalHistory => 'Anamnese',
    PatientFormStep.gynecologicalHistory => 'Histórico ginecológico',
    PatientFormStep.obstetricHistory => 'Histórico obstétrico',
    PatientFormStep.surgicalHistory => 'Histórico cirúrgico',
    PatientFormStep.urinaryFunction => 'Função urinária',
    PatientFormStep.sexualFunction => 'Função sexual',
    PatientFormStep.bowelFunction => 'Função intestinal',
    PatientFormStep.treatmentPlan => 'Plano de tratamento',
    PatientFormStep.assessmentForm => 'Ficha de avaliação física',
    PatientFormStep.consultationFee => 'Valor da consulta',
  };
}

class PatientFormCubit extends Cubit<PatientFormState> {
  PatientFormCubit({Patient? existingPatient})
    : isEditing = existingPatient != null,
      super(
        PatientFormState(
          patient:
              existingPatient ??
              Patient(id: generateId(), createdAt: DateTime.now()),
        ),
      );

  final bool isEditing;

  List<PatientFormStep> get _visibleSteps {
    final isFemale = state.patient.personalInfo.gender == Gender.female;
    return [
      PatientFormStep.personalInfo,
      PatientFormStep.medicalHistory,
      if (isFemale) PatientFormStep.gynecologicalHistory,
      if (isFemale) PatientFormStep.obstetricHistory,
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

  String get currentStepTitle => currentStep.title;

  void updatePatient(Patient patient) => emit(state.copyWith(patient: patient));

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
