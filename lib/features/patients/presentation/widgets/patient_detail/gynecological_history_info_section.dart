import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_strings.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class GynecologicalHistoryInfoSection extends StatelessWidget {
  const GynecologicalHistoryInfoSection(this.gynecologicalHistory, {super.key});

  final GynecologicalHistory gynecologicalHistory;

  @override
  Widget build(BuildContext context) {
    final h = gynecologicalHistory;
    final t = PatientsStrings(context.watch<LocaleCubit>().state);
    final l = t.language;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(t.sectionGynecologicalHistory),
        InfoRow(
          t.fieldAgeAtMenarche,
          PatientDetailFormat.intValue(h.ageAtMenarche, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldMenstrualFlow,
          PatientDetailFormat.enumValue(
            h.menstrualFlow,
            (v) => v.label(l),
            language: l,
          ),
          language: l,
        ),
        InfoRow(
          t.fieldCrampsScore,
          PatientDetailFormat.intValue(h.crampsScore0to10, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldCurrentlyMenstruating,
          PatientDetailFormat.yesNo(h.currentlyMenstruating, language: l),
          language: l,
        ),
        if (h.currentlyMenstruating == false) ...[
          InfoRow(
            t.fieldInMenopause,
            PatientDetailFormat.yesNo(h.isInMenopause, language: l),
            language: l,
          ),
          InfoRow(
            t.fieldApproxLastMenstruationDate,
            PatientDetailFormat.dateValue(
              h.approximateLastMenstruationDate,
              language: l,
            ),
            language: l,
          ),
        ],
        InfoRow(
          t.fieldRegularCycle,
          PatientDetailFormat.yesNo(h.regularCycle, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldMenopause,
          PatientDetailFormat.yesNo(h.menopause, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldHormoneReplacement,
          PatientDetailFormat.yesNo(h.hormoneReplacementTherapy, language: l),
          language: l,
        ),
        if (h.hormoneReplacementTherapy == true)
          InfoRow(
            t.fieldHormoneReplacementDetail,
            PatientDetailFormat.text(
              h.hormoneReplacementTherapyDescription,
              language: l,
            ),
            language: l,
          ),
        InfoRow(
          t.fieldContraceptiveMethod,
          PatientDetailFormat.enumValue(
            h.contraceptiveMethod,
            (v) => v.label(l),
            language: l,
          ),
          language: l,
        ),
        InfoRow(
          t.fieldPelvicPainOutsidePeriod,
          PatientDetailFormat.yesNo(h.pelvicPainOutsidePeriod, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldBleedingOutsidePeriod,
          PatientDetailFormat.yesNo(h.bleedingOutsidePeriod, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldEndometriosis,
          PatientDetailFormat.yesNo(h.endometriosis, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldPolycysticOvarySyndrome,
          PatientDetailFormat.yesNo(h.polycysticOvarySyndrome, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldRecurrentUrinaryInfections,
          PatientDetailFormat.yesNo(h.recurrentUrinaryInfections, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldRecurrentVaginalInfections,
          PatientDetailFormat.yesNo(h.recurrentVaginalInfections, language: l),
          language: l,
        ),
      ],
    );
  }
}
