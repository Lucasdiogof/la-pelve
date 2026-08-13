import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/attachment_picker_sheet.dart';

class PatientFormState extends Equatable {
  const PatientFormState({
    required this.patient,
    this.stepIndex = 0,
    this.assessmentFiles = const [],
  });

  final Patient patient;
  final int stepIndex;

  final List<PickedAttachmentFile> assessmentFiles;

  PatientFormState copyWith({
    Patient? patient,
    int? stepIndex,
    List<PickedAttachmentFile>? assessmentFiles,
  }) {
    return PatientFormState(
      patient: patient ?? this.patient,
      stepIndex: stepIndex ?? this.stepIndex,
      assessmentFiles: assessmentFiles ?? this.assessmentFiles,
    );
  }

  @override
  List<Object?> get props => [patient, stepIndex, assessmentFiles];
}
