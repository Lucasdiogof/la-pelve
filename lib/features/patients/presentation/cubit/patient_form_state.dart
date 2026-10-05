import 'package:equatable/equatable.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/presentation/widgets/attachment_picker_sheet.dart';

class PatientFormState extends Equatable {
  const PatientFormState({
    required this.patient,
    this.stepIndex = 0,
    this.assessmentFiles = const [],
    this.manualConsentChoices = const {},
  });

  final Patient patient;
  final int stepIndex;

  final List<PickedAttachmentFile> assessmentFiles;

  /// Escolha explícita do profissional para o switch "Receber lembretes
  /// pelo WhatsApp", indexada pelo telefone (E.164) para o qual ela foi
  /// feita. Não é o valor exibido do switch: é só o histórico de toques
  /// manuais nesta sessão do formulário, por número. O valor exibido é
  /// resolvido por [resolveWhatsappConsentChoice] cruzando isto com o
  /// telefone atual e o consentimento que já existia ao abrir o formulário.
  final Map<String, bool> manualConsentChoices;

  PatientFormState copyWith({
    Patient? patient,
    int? stepIndex,
    List<PickedAttachmentFile>? assessmentFiles,
    Map<String, bool>? manualConsentChoices,
  }) {
    return PatientFormState(
      patient: patient ?? this.patient,
      stepIndex: stepIndex ?? this.stepIndex,
      assessmentFiles: assessmentFiles ?? this.assessmentFiles,
      manualConsentChoices: manualConsentChoices ?? this.manualConsentChoices,
    );
  }

  @override
  List<Object?> get props => [
    patient,
    stepIndex,
    assessmentFiles,
    manualConsentChoices,
  ];
}
