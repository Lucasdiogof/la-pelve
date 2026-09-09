import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_enums.dart';
import 'package:la_pelve/features/patients/l10n/patients_wizard_strings_a.dart';
import 'package:la_pelve/shared/widgets/app_chip_select.dart';
import 'package:la_pelve/shared/widgets/app_text_field.dart';

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

  static const _somenteMasculino = {GynecologicalSurgery.prostatectomy};

  @override
  Widget build(BuildContext context) {
    final t = PatientsWizardStringsA(context.watch<LocaleCubit>().state);
    final historico = widget.patient.surgicalHistory;
    final gender = widget.patient.personalInfo.gender;
    final excluidas = switch (gender) {
      Gender.female => _somenteMasculino,
      Gender.male => _somenteFeminino,
      // "Outro" and "not yet chosen" get every option: better to show a
      // surgery that doesn't apply than to hide one that could.
      Gender.other || null => const <GynecologicalSurgery>{},
    };
    final opcoes = GynecologicalSurgery.values
        .where((c) => !excluidas.contains(c))
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
