import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patient_form_state.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/attachment_picker_sheet.dart';
import 'package:fisioterapia_pelvica/shared/utils/id_generator.dart';
import 'package:fisioterapia_pelvica/shared/utils/validators.dart';

enum PatientFormStep {
  dadosPessoais,
  anamnese,
  historicoGinecologico,
  historicoObstetrico,
  historicoCirurgico,
  funcaoUrinaria,
  funcaoSexual,
  funcaoIntestinal,
  planoTratamento,
  fichaAvaliacao,
  valorConsulta,
}

extension PatientFormStepTitle on PatientFormStep {
  String get title => switch (this) {
    PatientFormStep.dadosPessoais => 'Dados pessoais',
    PatientFormStep.anamnese => 'Anamnese',
    PatientFormStep.historicoGinecologico => 'Histórico ginecológico',
    PatientFormStep.historicoObstetrico => 'Histórico obstétrico',
    PatientFormStep.historicoCirurgico => 'Histórico cirúrgico',
    PatientFormStep.funcaoUrinaria => 'Função urinária',
    PatientFormStep.funcaoSexual => 'Função sexual',
    PatientFormStep.funcaoIntestinal => 'Função intestinal',
    PatientFormStep.planoTratamento => 'Plano de tratamento',
    PatientFormStep.fichaAvaliacao => 'Ficha de avaliação física',
    PatientFormStep.valorConsulta => 'Valor da consulta',
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
    final isFeminino = state.patient.dadosPessoais.sexo == Sexo.feminino;
    return [
      PatientFormStep.dadosPessoais,
      PatientFormStep.anamnese,
      if (isFeminino) PatientFormStep.historicoGinecologico,
      if (isFeminino) PatientFormStep.historicoObstetrico,
      PatientFormStep.historicoCirurgico,
      PatientFormStep.funcaoUrinaria,
      PatientFormStep.funcaoSexual,
      PatientFormStep.funcaoIntestinal,
      PatientFormStep.planoTratamento,
      PatientFormStep.fichaAvaliacao,
      PatientFormStep.valorConsulta,
    ];
  }

  int get stepCount => _visibleSteps.length;

  PatientFormStep get currentStep => _visibleSteps[state.stepIndex];

  String get currentStepTitle => currentStep.title;

  void updatePatient(Patient patient) => emit(state.copyWith(patient: patient));

  void addFichaAvaliacao(PickedAttachmentFile file) {
    emit(state.copyWith(fichasAvaliacao: [...state.fichasAvaliacao, file]));
  }

  void removeFichaAvaliacao(int index) {
    final files = [...state.fichasAvaliacao]..removeAt(index);
    emit(state.copyWith(fichasAvaliacao: files));
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

  bool get canProceed {
    if (currentStep != PatientFormStep.dadosPessoais) return true;
    final dados = state.patient.dadosPessoais;
    return dados.nome.trim().length > 2 &&
        dados.sexo != null &&
        isValidPhone(dados.telefone);
  }
}
