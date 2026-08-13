import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_strings.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class AnamneseInfoSection extends StatelessWidget {
  const AnamneseInfoSection(this.medicalHistory, {super.key});

  final MedicalHistory medicalHistory;

  @override
  Widget build(BuildContext context) {
    final t = PatientsStrings(context.watch<LocaleCubit>().state);
    final language = t.language;
    final a = medicalHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(t.sectionAnamnesis),
        InfoRow(
          t.fieldChiefComplaint,
          PatientDetailFormat.text(a.chiefComplaint, language: language),
          language: language,
        ),
        InfoRow(
          t.fieldSymptomsOnset,
          PatientDetailFormat.text(a.symptomsOnset, language: language),
          language: language,
        ),
        InfoRow(
          t.fieldHasMedicalDiagnosis,
          PatientDetailFormat.yesNo(a.hasMedicalDiagnosis, language: language),
          language: language,
        ),
        if (a.hasMedicalDiagnosis == true)
          InfoRow(
            t.fieldWhichDiagnosis,
            PatientDetailFormat.text(a.medicalDiagnosis, language: language),
            language: language,
          ),
        InfoRow(
          t.fieldHadPreviousTreatment,
          PatientDetailFormat.yesNo(a.hadPreviousTreatment, language: language),
          language: language,
        ),
        if (a.hadPreviousTreatment == true)
          InfoRow(
            t.fieldWhichTreatment,
            PatientDetailFormat.text(
              a.treatmentDescription,
              language: language,
            ),
            language: language,
          ),
        InfoRow(
          t.fieldChronicDiseases,
          PatientDetailFormat.yesNo(a.hasChronicDiseases, language: language),
          language: language,
        ),
        if (a.hasChronicDiseases == true)
          InfoRow(
            t.fieldWhichDiseases,
            PatientDetailFormat.text(
              a.chronicDiseasesDescription,
              language: language,
            ),
            language: language,
          ),
        InfoRow(
          t.fieldContinuousMedication,
          PatientDetailFormat.yesNo(
            a.takesContinuousMedication,
            language: language,
          ),
          language: language,
        ),
        if (a.takesContinuousMedication == true)
          InfoRow(
            t.fieldWhichMedications,
            PatientDetailFormat.text(
              a.medicationsDescription,
              language: language,
            ),
            language: language,
          ),
        InfoRow(
          t.fieldSmoking,
          PatientDetailFormat.yesNo(a.smoking, language: language),
          language: language,
        ),
        InfoRow(
          t.fieldConsumesAlcohol,
          PatientDetailFormat.yesNo(a.consumesAlcohol, language: language),
          language: language,
        ),
        InfoRow(
          t.fieldPhysicalActivity,
          PatientDetailFormat.yesNo(
            a.practicesPhysicalActivity,
            language: language,
          ),
          language: language,
        ),
        InfoRow(
          t.fieldImagingExams,
          PatientDetailFormat.text(a.imagingExams, language: language),
          language: language,
        ),
      ],
    );
  }
}
