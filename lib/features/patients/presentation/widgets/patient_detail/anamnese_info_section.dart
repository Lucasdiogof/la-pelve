import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class AnamneseInfoSection extends StatelessWidget {
  const AnamneseInfoSection(this.medicalHistory, {super.key});

  final MedicalHistory medicalHistory;

  @override
  Widget build(BuildContext context) {
    final a = medicalHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Anamnese'),
        InfoRow('Queixa principal', PatientDetailFormat.text(a.chiefComplaint)),
        InfoRow(
          'Início dos sintomas',
          PatientDetailFormat.text(a.symptomsOnset),
        ),
        InfoRow(
          'Tem diagnóstico médico',
          PatientDetailFormat.yesNo(a.hasMedicalDiagnosis),
        ),
        if (a.hasMedicalDiagnosis == true)
          InfoRow(
            'Qual diagnóstico',
            PatientDetailFormat.text(a.medicalDiagnosis),
          ),
        InfoRow(
          'Já realizou tratamento',
          PatientDetailFormat.yesNo(a.hadPreviousTreatment),
        ),
        if (a.hadPreviousTreatment == true)
          InfoRow(
            'Qual tratamento',
            PatientDetailFormat.text(a.treatmentDescription),
          ),
        InfoRow(
          'Doenças crônicas',
          PatientDetailFormat.yesNo(a.hasChronicDiseases),
        ),
        if (a.hasChronicDiseases == true)
          InfoRow(
            'Quais doenças',
            PatientDetailFormat.text(a.chronicDiseasesDescription),
          ),
        InfoRow(
          'Uso contínuo de medicamentos',
          PatientDetailFormat.yesNo(a.takesContinuousMedication),
        ),
        if (a.takesContinuousMedication == true)
          InfoRow(
            'Quais medicamentos',
            PatientDetailFormat.text(a.medicationsDescription),
          ),
        InfoRow('Tabagismo', PatientDetailFormat.yesNo(a.smoking)),
        InfoRow('Consome álcool', PatientDetailFormat.yesNo(a.consumesAlcohol)),
        InfoRow(
          'Pratica atividade física',
          PatientDetailFormat.yesNo(a.practicesPhysicalActivity),
        ),
        InfoRow('Exames de imagem', PatientDetailFormat.text(a.imagingExams)),
      ],
    );
  }
}
