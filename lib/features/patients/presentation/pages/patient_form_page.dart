import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/attachment.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/attachment_repository.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patient_form_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patient_form_state.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/attachment_picker_sheet.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/anamnese_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/dados_pessoais_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/ficha_avaliacao_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/funcao_intestinal_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/funcao_sexual_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/funcao_urinaria_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/historico_cirurgico_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/historico_ginecologico_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/historico_obstetrico_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/plano_tratamento_step.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_form_steps/valor_consulta_step.dart';
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
    if (result case Success() when state.fichasAvaliacao.isNotEmpty) {
      final attachmentRepository = sl<AttachmentRepository>();
      for (final file in state.fichasAvaliacao) {
        await attachmentRepository.upload(
          patientId: state.patient.id,
          category: AttachmentCategory.fichaAvaliacao,
          bytes: file.bytes,
          fileName: file.fileName,
          contentType: file.contentType,
        );
      }
    }
    hideAppLoading();
    if (!mounted) return;
    switch (result) {
      case Success():
        context.pop();
      case Error(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _formCubit,
      child: BlocBuilder<PatientFormCubit, PatientFormState>(
        builder: (context, state) {
          return AppWizardScaffold(
            title: _formCubit.currentStepTitle,
            stepIndex: state.stepIndex,
            stepCount: _formCubit.stepCount,
            nextLabel: _formCubit.isLastStep
                ? (_formCubit.isEditing ? 'Salvar alterações' : 'Salvar')
                : 'Próximo',
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
              onFichaAvaliacaoAdd: _formCubit.addFichaAvaliacao,
              onFichaAvaliacaoRemove: _formCubit.removeFichaAvaliacao,
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
    required this.onFichaAvaliacaoAdd,
    required this.onFichaAvaliacaoRemove,
  });

  final PatientFormStep step;
  final PatientFormState state;
  final ValueChanged<Patient> onChanged;
  final ValueChanged<PickedAttachmentFile> onFichaAvaliacaoAdd;
  final ValueChanged<int> onFichaAvaliacaoRemove;

  @override
  Widget build(BuildContext context) {
    final patient = state.patient;
    return switch (step) {
      PatientFormStep.dadosPessoais => DadosPessoaisStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.anamnese => AnamneseStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.historicoGinecologico => HistoricoGinecologicoStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.historicoObstetrico => HistoricoObstetricoStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.historicoCirurgico => HistoricoCirurgicoStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.funcaoUrinaria => FuncaoUrinariaStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.funcaoSexual => FuncaoSexualStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.funcaoIntestinal => FuncaoIntestinalStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.planoTratamento => PlanoTratamentoStep(
        patient: patient,
        onChanged: onChanged,
      ),
      PatientFormStep.fichaAvaliacao => FichaAvaliacaoStep(
        files: state.fichasAvaliacao,
        onAdd: onFichaAvaliacaoAdd,
        onRemove: onFichaAvaliacaoRemove,
      ),
      PatientFormStep.valorConsulta => ValorConsultaStep(
        patient: patient,
        onChanged: onChanged,
      ),
    };
  }
}
