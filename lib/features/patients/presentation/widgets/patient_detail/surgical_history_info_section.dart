import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_strings.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';

class SurgicalHistoryInfoSection extends StatelessWidget {
  const SurgicalHistoryInfoSection(this.surgicalHistory, {super.key});

  final SurgicalHistory surgicalHistory;

  @override
  Widget build(BuildContext context) {
    final h = surgicalHistory;
    final t = PatientsStrings(context.watch<LocaleCubit>().state);
    final l = t.language;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(t.sectionSurgicalHistory),
        InfoRow(
          t.fieldSurgeries,
          h.surgeries.isEmpty
              ? PatientDetailFormat.naoInformado(language: l)
              : h.surgeries.map((c) => c.label(l)).join(', '),
          language: l,
        ),
        if (h.surgeries.contains(GynecologicalSurgery.other))
          InfoRow(
            t.fieldWhichSurgery,
            PatientDetailFormat.text(h.otherSurgeryDescription, language: l),
            language: l,
          ),
      ],
    );
  }
}
