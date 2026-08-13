import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_strings.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class BowelFunctionInfoSection extends StatelessWidget {
  const BowelFunctionInfoSection(this.bowelFunction, {super.key});

  final BowelFunction bowelFunction;

  @override
  Widget build(BuildContext context) {
    final f = bowelFunction;
    final t = PatientsStrings(context.watch<LocaleCubit>().state);
    final l = t.language;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(t.sectionBowelFunction),
        InfoRow(
          t.fieldBowelFrequency,
          PatientDetailFormat.enumValue(
            f.bowelFrequency,
            (v) => v.label(l),
            language: l,
          ),
          language: l,
        ),
        if (f.bowelFrequency == BowelFrequency.custom)
          InfoRow(
            t.fieldTimesPerWeek,
            PatientDetailFormat.intValue(f.customFrequencyValue, language: l),
            language: l,
          ),
        InfoRow(
          t.fieldUsesLaxative,
          PatientDetailFormat.yesNo(f.usesLaxative, language: l),
          language: l,
        ),
        if (f.usesLaxative == true)
          InfoRow(
            t.fieldWhichLaxative,
            PatientDetailFormat.text(f.laxativeDescription, language: l),
            language: l,
          ),
        InfoRow(
          t.fieldStrainsToDefecate,
          PatientDetailFormat.yesNo(f.strainsToDefecate, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldPainToDefecate,
          PatientDetailFormat.yesNo(f.painToDefecate, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldIncompleteEmptying,
          PatientDetailFormat.yesNo(f.incompleteEmptying, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldObstructionSensation,
          PatientDetailFormat.yesNo(f.obstructionSensation, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldFecalUrgency,
          PatientDetailFormat.yesNo(f.fecalUrgency, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldHemorrhoids,
          PatientDetailFormat.yesNo(f.hemorrhoids, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldGasIncontinence,
          PatientDetailFormat.yesNo(f.gasIncontinence, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldFecalIncontinence,
          PatientDetailFormat.yesNo(f.fecalIncontinence, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldBristolScale,
          PatientDetailFormat.enumValue(
            f.bristolScale,
            (v) => v.label(l),
            language: l,
          ),
          language: l,
        ),
      ],
    );
  }
}
