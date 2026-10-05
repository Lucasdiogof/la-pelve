import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/utils/app_loading.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/repositories/attachment_repository.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_consent_repository.dart';
import 'package:la_pelve/features/patients/l10n/patients_wizard_strings_b.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patient_consent_load_result.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patient_form_cubit.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patient_form_save_controller.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patient_form_state.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/features/patients/presentation/widgets/attachment_picker_sheet.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_form_steps/assessment_form_step.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_form_steps/bowel_function_step.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_form_steps/consultation_fee_step.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_form_steps/gynecological_history_step.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_form_steps/medical_history_step.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_form_steps/obstetric_history_step.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_form_steps/personal_info_step.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_form_steps/sexual_function_step.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_form_steps/surgical_history_step.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_form_steps/treatment_plan_step.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_form_steps/urinary_function_step.dart';
import 'package:la_pelve/shared/widgets/app_info_bottom_sheet.dart';
import 'package:la_pelve/shared/widgets/app_wizard_scaffold.dart';
import 'package:la_pelve/shared/widgets/primary_button.dart';

class PatientFormPage extends StatefulWidget {
  const PatientFormPage({this.patient, super.key});

  final Patient? patient;

  @override
  State<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends State<PatientFormPage> {
  PatientFormCubit? _formCubit;

  /// true = a leitura do consentimento ativo falhou (ou deu timeout); a UI
  /// mostra um estado de erro com "tentar novamente"/"voltar" em vez de
  /// montar o formulário com uma informação que pode estar errada.
  bool _consentLoadFailed = false;

  bool _isSaving = false;

  late final PatientFormSaveController _saveController = PatientFormSaveController(
    patientsCubit: context.read<PatientsCubit>(),
    attachmentRepository: sl<AttachmentRepository>(),
    consentRepository: sl<PatientConsentRepository>(),
  );

  @override
  void initState() {
    super.initState();
    _loadConsentAndInitCubit();
  }

  Future<void> _loadConsentAndInitCubit() async {
    setState(() {
      _consentLoadFailed = false;
      _formCubit = null;
    });

    if (widget.patient == null) {
      // Paciente novo: não existe consentimento prévio para carregar.
      setState(() {
        _formCubit = PatientFormCubit();
      });
      return;
    }

    final loadResult = await loadActiveWhatsappConsent(
      repository: sl<PatientConsentRepository>(),
      patientId: widget.patient!.id,
    );
    if (!mounted) return;

    switch (loadResult) {
      case PatientConsentLoadSucceeded(:final consent):
        setState(() {
          _formCubit = PatientFormCubit(
            existingPatient: widget.patient,
            existingConsent: consent,
          );
        });
      case PatientConsentLoadFailed():
        // Nunca trate uma falha de leitura como "não há consentimento": o
        // formulário só é montado com Success (consentimento ou null).
        setState(() => _consentLoadFailed = true);
    }
  }

  @override
  void dispose() {
    _formCubit?.close();
    super.dispose();
  }

  Future<void> _save(PatientFormCubit formCubit, PatientFormState state) async {
    // Guarda de UI: evita até disparar uma segunda chamada enquanto a
    // primeira está em andamento. O controller tem a mesma guarda por
    // dentro, então qualquer outro chamador (ou um teste) está protegido
    // mesmo sem passar por este widget.
    if (_isSaving) return;
    setState(() => _isSaving = true);
    showAppLoading();
    final outcome = await _saveController.save(formCubit: formCubit, state: state);
    hideAppLoading();
    if (mounted) setState(() => _isSaving = false);
    if (!mounted || outcome == null) return;

    final t = PatientsWizardStringsB(context.read<LocaleCubit>().state);
    switch (outcome) {
      case PatientSaveSucceeded(:final isEditing, :final consentFailed):
        context.pop();
        if (consentFailed) {
          // Componente de erro padronizado do app (não o "informativo"):
          // algo precisa de atenção, mesmo que o paciente já esteja salvo.
          await AppInfoBottomSheet.showError(
            context,
            title: t.whatsappConsentSaveErrorTitle,
            description: t.whatsappConsentSaveErrorMessage,
          );
        } else {
          await AppInfoBottomSheet.showSuccess(
            context,
            description: isEditing
                ? t.patientUpdatedSuccessMessage
                : t.patientCreatedSuccessMessage,
          );
        }
      case PatientSaveFailed(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = PatientsWizardStringsB(context.watch<LocaleCubit>().state);

    if (_consentLoadFailed) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: context.colors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  t.consentLoadErrorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: t.retryButton,
                    onPressed: _loadConsentAndInitCubit,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(t.backButton),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final formCubit = _formCubit;
    if (formCubit == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
      );
    }
    return BlocProvider.value(
      value: formCubit,
      child: BlocBuilder<PatientFormCubit, PatientFormState>(
        builder: (context, state) {
          return AppWizardScaffold(
            title: formCubit.currentStepTitle(t.language),
            stepIndex: state.stepIndex,
            stepCount: formCubit.stepCount,
            isLoading: _isSaving,
            nextLabel: formCubit.isLastStep
                ? (formCubit.isEditing ? t.saveChangesButton : t.saveButton)
                : t.nextButton,
            onBack: () {
              if (state.stepIndex == 0) {
                context.pop();
              } else {
                formCubit.previousStep();
              }
            },
            onNext: formCubit.canProceed
                ? () {
                    if (formCubit.isLastStep) {
                      _save(formCubit, state);
                    } else {
                      formCubit.nextStep();
                    }
                  }
                : null,
            showSaveButton: formCubit.isEditing && !formCubit.isLastStep,
            onSave: formCubit.canSave
                ? () => _save(formCubit, state)
                : null,
            body: _StepBody(
              step: formCubit.currentStep,
              state: state,
              onChanged: formCubit.updatePatient,
              onAssessmentFileAdd: formCubit.addAssessmentFile,
              onAssessmentFileRemove: formCubit.removeAssessmentFile,
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
