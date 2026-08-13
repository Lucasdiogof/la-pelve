import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_wizard_strings_a.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';

class SurgicalHistoryStep extends StatefulWidget {
  const SurgicalHistoryStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<SurgicalHistoryStep> createState() => _SurgicalHistoryStepState();
}

class _SurgicalHistoryStepState extends State<SurgicalHistoryStep> {
  late final _outraController = TextEditingController(
    text: widget.patient.surgicalHistory.otherSurgeryDescription ?? '',
  );

  @override
  void dispose() {
    _outraController.dispose();
    super.dispose();
  }

  void _update(SurgicalHistory Function(SurgicalHistory) update) {
    widget.onChanged(
      widget.patient.copyWith(
        surgicalHistory: update(widget.patient.surgicalHistory),
      ),
    );
  }

  static const _somenteFeminino = {
    GynecologicalSurgery.hysterectomy,
    GynecologicalSurgery.tubalLigation,
    GynecologicalSurgery.perineoplasty,
  };

  @override
  Widget build(BuildContext context) {
    final t = PatientsWizardStringsA(context.watch<LocaleCubit>().state);
    final historico = widget.patient.surgicalHistory;
    final isFeminino = widget.patient.personalInfo.gender == Gender.female;
    final opcoes = isFeminino
        ? GynecologicalSurgery.values
        : GynecologicalSurgery.values
              .where((c) => !_somenteFeminino.contains(c))
              .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppChipSelect<GynecologicalSurgery>(
          options: opcoes,
          labelBuilder: (option) => option.label(t.language),
          selected: historico.surgeries,
          multiSelect: true,
          onChanged: (selected) {
            final tappedNenhum =
                selected.contains(GynecologicalSurgery.none) &&
                !historico.surgeries.contains(GynecologicalSurgery.none);
            final cirurgias = tappedNenhum
                ? {GynecologicalSurgery.none}
                : (selected..remove(GynecologicalSurgery.none));
            _update((h) => h.copyWith(surgeries: cirurgias));
          },
        ),
        if (historico.surgeries.contains(GynecologicalSurgery.other)) ...[
          const SizedBox(height: 12),
          AppTextField(
            controller: _outraController,
            icon: Icons.description_outlined,
            hintText: t.otherSurgeryDetailHint,
            onChanged: (value) =>
                _update((h) => h.copyWith(otherSurgeryDescription: value)),
          ),
        ],
      ],
    );
  }
}
