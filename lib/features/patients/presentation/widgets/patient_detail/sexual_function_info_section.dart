import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_strings.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class SexualFunctionInfoSection extends StatelessWidget {
  const SexualFunctionInfoSection(this.sexualFunction, {super.key});

  final SexualFunction sexualFunction;

  @override
  Widget build(BuildContext context) {
    final f = sexualFunction;
    final t = PatientsStrings(context.watch<LocaleCubit>().state);
    final l = t.language;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(t.sectionSexualFunction),
        InfoRow(
          t.fieldSexuallyActive,
          PatientDetailFormat.yesNo(f.sexuallyActive, language: l),
          language: l,
        ),
        if (f.sexuallyActive == true) ...[
          InfoRow(
            t.fieldSexualActivityFrequency,
            PatientDetailFormat.text(f.sexualActivityFrequency, language: l),
            language: l,
          ),
          InfoRow(
            t.fieldNeedsLubricant,
            PatientDetailFormat.yesNo(f.needsLubricant, language: l),
            language: l,
          ),
          InfoRow(
            t.fieldDryness,
            PatientDetailFormat.yesNo(f.dryness, language: l),
            language: l,
          ),
          InfoRow(
            t.fieldOrgasmDifficulty,
            PatientDetailFormat.yesNo(f.orgasmDifficulty, language: l),
            language: l,
          ),
          if (f.orgasmDifficulty == true)
            InfoRow(
              t.fieldDetailGeneric,
              PatientDetailFormat.text(
                f.orgasmDifficultyDescription,
                language: l,
              ),
              language: l,
            ),
          InfoRow(
            t.fieldPainDuringPenetration,
            PatientDetailFormat.yesNo(f.painDuringPenetration, language: l),
            language: l,
          ),
          if (f.painDuringPenetration == true)
            InfoRow(
              t.fieldPainType,
              PatientDetailFormat.enumValue(
                f.penetrationPainType,
                (v) => v.label(l),
                language: l,
              ),
              language: l,
            ),
          InfoRow(
            t.fieldPainDuringOrAfterIntercourse,
            PatientDetailFormat.yesNo(
              f.painDuringOrAfterIntercourse,
              language: l,
            ),
            language: l,
          ),
          if (f.painDuringPenetration == true ||
              f.painDuringOrAfterIntercourse == true)
            InfoRow(
              t.fieldPainIntensity0to10,
              PatientDetailFormat.intValue(f.painIntensity0to10, language: l),
              language: l,
            ),
          InfoRow(
            t.fieldSexualDesire,
            PatientDetailFormat.enumValue(
              f.sexualDesire,
              (v) => v.label(l),
              language: l,
            ),
            language: l,
          ),
        ],
      ],
    );
  }
}
