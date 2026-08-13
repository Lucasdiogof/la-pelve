import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_strings.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class ObstetricHistoryInfoSection extends StatelessWidget {
  const ObstetricHistoryInfoSection(this.obstetricHistory, {super.key});

  final ObstetricHistory obstetricHistory;

  @override
  Widget build(BuildContext context) {
    final h = obstetricHistory;
    final t = PatientsStrings(context.watch<LocaleCubit>().state);
    final l = t.language;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(t.sectionObstetricHistory),
        InfoRow(
          t.fieldCurrentlyPregnant,
          PatientDetailFormat.yesNo(h.currentlyPregnant, language: l),
          language: l,
        ),
        if (h.currentlyPregnant == true) ...[
          InfoRow(
            t.fieldDesiredDeliveryMethod,
            PatientDetailFormat.enumValue(
              h.desiredDeliveryMethod,
              (v) => v.label(l),
              language: l,
            ),
            language: l,
          ),
          InfoRow(
            t.fieldGestationWeeks,
            PatientDetailFormat.intValue(h.gestationWeeks, language: l),
            language: l,
          ),
          InfoRow(
            t.fieldEstimatedDeliveryDate,
            PatientDetailFormat.dateValue(h.estimatedDeliveryDate, language: l),
            language: l,
          ),
          InfoRow(
            t.fieldHighRiskPregnancy,
            PatientDetailFormat.yesNo(h.highRiskPregnancy, language: l),
            language: l,
          ),
          if (h.highRiskPregnancy == true)
            InfoRow(
              t.fieldHighRiskPregnancyDetail,
              PatientDetailFormat.text(
                h.highRiskPregnancyDescription,
                language: l,
              ),
              language: l,
            ),
        ],
        InfoRow(
          t.fieldHasBeenPregnant,
          PatientDetailFormat.yesNo(h.hasBeenPregnant, language: l),
          language: l,
        ),
        if (h.hasBeenPregnant == true) ...[
          InfoRow(
            t.fieldPregnancyCount,
            PatientDetailFormat.intValue(h.pregnancyCount, language: l),
            language: l,
          ),
          for (var i = 0; i < h.pregnancies.length; i++)
            PregnancyCard(index: i, pregnancy: h.pregnancies[i], language: l),
        ],
      ],
    );
  }
}
