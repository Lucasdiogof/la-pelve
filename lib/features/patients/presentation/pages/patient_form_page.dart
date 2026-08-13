import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/attachment.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/attachment_repository.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_wizard_strings_b.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patient_form_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patient_form_state.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/attachment_picker_sheet.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/assessment_form_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/bowel_function_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/consultation_fee_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/gynecological_history_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/medical_history_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/obstetric_history_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/personal_info_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/sexual_function_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/surgical_history_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/treatment_plan_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/urinary_function_step.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_wizard_scaffold.dart';

class PatientFormPage extends StatefulWidget {
  const PatientFormPage({this.patient, super.key});

  final Patient? patient;

  @override
  State<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends State<PatientFormPage> {
  late final _formCubit = PatientFormCubit(existingPatient: widget.patient);

  @override
  void dispose() {
    _formCubit.close();
    super.dispose();
  }

  Future<void> _save(PatientFormState state) async {
    showAppLoading();
    final patientsCubit = context.read<PatientsCubit>();
    final result = _formCubit.isEditing
        ? await patientsCubit.updatePatient(state.patient)
        : await patientsCubit.addPatient(state.patient);
    if (result case Success() when state.assessmentFiles.isNotEmpty) {
      final attachmentRepository = sl<AttachmentRepository>();
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
    hideAppLoading();
    if (!mounted) return;
    final isEditing = _formCubit.isEditing;
    final t = PatientsWizardStringsB(context.read<LocaleCubit>().state);
    switch (result) {
      case Success():
        context.pop();
        await AppInfoBottomSheet.showSuccess(
          context,
          description: isEditing
              ? t.patientUpdatedSuccessMessage
              : t.patientCreatedSuccessMessage,
        );
      case Error(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = PatientsWizardStringsB(context.watch<LocaleCubit>().state);
    return BlocProvider.value(
      value: _formCubit,
      child: BlocBuilder<PatientFormCubit, PatientFormState>(
        builder: (context, state) {
          return AppWizardScaffold(
            title: _formCubit.currentStepTitle(t.language),
            stepIndex: state.stepIndex,
            stepCount: _formCubit.stepCount,
            nextLabel: _formCubit.isLastStep
                ? (_formCubit.isEditing ? t.saveChangesButton : t.saveButton)
                : t.nextButton,
            onBack: () {
              if (state.stepIndex == 0) {
                context.pop();
              } else {
                _formCubit.previousStep();
              }
            },
            onNext: _formCubit.canProceed
                ? () {
                    if (_formCubit.isLastStep) {
                      _save(state);
                    } else {
                      _formCubit.nextStep();
                    }
                  }
                : null,
            showSaveButton: _formCubit.isEditing && !_formCubit.isLastStep,
            onSave: _formCubit.canSave ? () => _save(state) : null,
            body: _StepBody(
              step: _formCubit.currentStep,
              state: state,
              onChanged: _formCubit.updatePatient,
              onAssessmentFileAdd: _formCubit.addAssessmentFile,
              onAssessmentFileRemove: _formCubit.removeAssessmentFile,
            ),
          );
        },
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.step,
    required this.state,
    required this.onChanged,
    required this.onAssessmentFileAdd,
    required this.onAssessmentFileRemove,
  });

  final PatientFormStep step;
  final PatientFormState state;
  final ValueChanged<Patient> onChanged;
  final ValueChanged<PickedAttachmentFile> onAssessmentFileAdd;
  final ValueChanged<int> onAssessmentFileRemove;

  @override
  Widget build(BuildContext context) {
    final patient = state.patient;
    return switch (step) {
      PatientFormStep.personalInfo => PersonalInfoStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.medicalHistory => MedicalHistoryStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.gynecologicalHistory => GynecologicalHistoryStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.obstetricHistory => ObstetricHistoryStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.surgicalHistory => SurgicalHistoryStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.urinaryFunction => UrinaryFunctionStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.sexualFunction => SexualFunctionStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.bowelFunction => BowelFunctionStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.treatmentPlan => TreatmentPlanStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.assessmentForm => AssessmentFormStep(
        files: state.assessmentFiles,
        onAdd: onAssessmentFileAdd,
        onRemove: onAssessmentFileRemove,
      ),
      PatientFormStep.consultationFee => ConsultationFeeStep(
        patient: patient,
        onChanged: onChanged,
      ),
    };
  }
}
