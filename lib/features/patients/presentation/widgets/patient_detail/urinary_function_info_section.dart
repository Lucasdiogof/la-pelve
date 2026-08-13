import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_strings.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class UrinaryFunctionInfoSection extends StatelessWidget {
  const UrinaryFunctionInfoSection(this.urinaryFunction, {super.key});

  final UrinaryFunction urinaryFunction;

  @override
  Widget build(BuildContext context) {
    final f = urinaryFunction;
    final t = PatientsStrings(context.watch<LocaleCubit>().state);
    final l = t.language;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(t.sectionUrinaryFunction),
        InfoRow(
          t.fieldUrgency,
          PatientDetailFormat.yesNo(f.urgency, language: l),
          language: l,
        ),
        if (f.urgency == true)
          InfoRow(
            t.fieldUrgencyDetail,
            PatientDetailFormat.text(f.urgencyDescription, language: l),
            language: l,
          ),
        InfoRow(
          t.fieldUrgencyAssociatedLeakage,
          PatientDetailFormat.yesNo(f.urgencyAssociatedLeakage, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldStressIncontinence,
          PatientDetailFormat.yesNo(f.stressIncontinence, language: l),
          language: l,
        ),
        if (f.stressIncontinence == true) ...[
          InfoRow(
            t.fieldTriggers,
            f.incontinenceTriggers.isEmpty
                ? PatientDetailFormat.naoInformado(language: l)
                : f.incontinenceTriggers.map((g) => g.label(l)).join(', '),
            language: l,
          ),
          if (f.incontinenceTriggers.contains(IncontinenceTrigger.other))
            InfoRow(
              t.fieldWhichOtherTrigger,
              PatientDetailFormat.text(f.otherTriggerDescription, language: l),
              language: l,
            ),
        ],
        if (f.urgencyAssociatedLeakage == true || f.stressIncontinence == true)
          InfoRow(
            t.fieldLeakageAmount,
            PatientDetailFormat.enumValue(
              f.leakageAmount,
              (v) => v.label(l),
              language: l,
            ),
            language: l,
          ),
        InfoRow(
          t.fieldUsesPads,
          PatientDetailFormat.yesNo(f.usesPads, language: l),
          language: l,
        ),
        if (f.usesPads == true)
          InfoRow(
            t.fieldHowManyPerDay,
            PatientDetailFormat.intValue(f.padsPerDay, language: l),
            language: l,
          ),
        InfoRow(
          t.fieldPainOrBurningUrinating,
          PatientDetailFormat.yesNo(f.painOrBurningWhenUrinating, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldWeakStream,
          PatientDetailFormat.yesNo(f.weakUrinaryStream, language: l),
          language: l,
        ),
        InfoRow(
          t.fieldNocturnalEnuresis,
          PatientDetailFormat.yesNo(f.nocturnalEnuresis, language: l),
          language: l,
        ),
        if (f.nocturnalEnuresis == true)
          InfoRow(
            t.fieldEnuresisDetail,
            PatientDetailFormat.text(f.enuresisDescription, language: l),
            language: l,
          ),
        InfoRow(
          t.fieldHesitancy,
          PatientDetailFormat.yesNo(f.hesitancy, language: l),
          language: l,
        ),
        if (f.hesitancy == true)
          InfoRow(
            t.fieldHesitancyDetail,
            PatientDetailFormat.text(f.hesitancyDescription, language: l),
            language: l,
          ),
        InfoRow(
          t.fieldUrinaryStraining,
          PatientDetailFormat.yesNo(f.urinaryStraining, language: l),
          language: l,
        ),
        if (f.urinaryStraining == true)
          InfoRow(
            t.fieldUrinaryStrainingDetail,
            PatientDetailFormat.text(
              f.urinaryStrainingDescription,
              language: l,
            ),
            language: l,
          ),
        InfoRow(
          t.fieldPostVoidDribbling,
          PatientDetailFormat.yesNo(f.postVoidDribbling, language: l),
          language: l,
        ),
        if (f.postVoidDribbling == true)
          InfoRow(
            t.fieldDribblingDetail,
            PatientDetailFormat.text(f.dribblingDescription, language: l),
            language: l,
          ),
        InfoRow(
          t.fieldIncompleteEmptying,
          PatientDetailFormat.yesNo(f.incompleteEmptying, language: l),
          language: l,
        ),
        if (f.incompleteEmptying == true)
          InfoRow(
            t.fieldIncompleteEmptyingDetail,
            PatientDetailFormat.text(
              f.incompleteEmptyingDescription,
              language: l,
            ),
            language: l,
          ),
      ],
    );
  }
}
