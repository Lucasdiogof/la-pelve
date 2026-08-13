import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_strings.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class TreatmentPlanInfoSection extends StatelessWidget {
  const TreatmentPlanInfoSection(this.treatmentPlan, {super.key});

  final TreatmentPlan treatmentPlan;

  @override
  Widget build(BuildContext context) {
    final p = treatmentPlan;
    final t = PatientsStrings(context.watch<LocaleCubit>().state);
    final l = t.language;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(t.sectionTreatmentPlan),
        InfoRow(
          t.fieldPhysiotherapyDiagnosis,
          PatientDetailFormat.text(p.physiotherapyDiagnosis, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldTreatmentGoal,
          PatientDetailFormat.text(p.treatmentGoal, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldTreatmentApproach,
          PatientDetailFormat.text(p.treatmentApproach, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldSuggestedFrequency,
          PatientDetailFormat.text(p.suggestedFrequency, language: l),
          language: l,
        ),
      ],
    );
  }
}
