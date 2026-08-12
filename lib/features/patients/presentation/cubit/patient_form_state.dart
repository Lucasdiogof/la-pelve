import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/attachment_picker_sheet.dart';

class PatientFormState extends Equatable {
  const PatientFormState({
    required this.patient,
    this.stepIndex = 0,
    this.fichasAvaliacao = const [],
  });

  final Patient patient;
  final int stepIndex;

  final List<PickedAttachmentFile> fichasAvaliacao;

  PatientFormState copyWith({
    Patient? patient,
    int? stepIndex,
    List<PickedAttachmentFile>? fichasAvaliacao,
  }) {
    return PatientFormState(
      patient: patient ?? this.patient,
      stepIndex: stepIndex ?? this.stepIndex,
      fichasAvaliacao: fichasAvaliacao ?? this.fichasAvaliacao,
    );
  }

  @override
  List<Object?> get props => [patient, stepIndex, fichasAvaliacao];
}
