import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_wizard_strings_b.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_scale_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_yes_no_toggle.dart';

class FuncaoSexualStep extends StatefulWidget {
  const FuncaoSexualStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<FuncaoSexualStep> createState() => _FuncaoSexualStepState();
}

class _FuncaoSexualStepState extends State<FuncaoSexualStep> {
  late final _dificuldadeController = TextEditingController(
    text: widget.patient.sexualFunction.orgasmDifficultyDescription ?? '',
  );
  late final _frequenciaController = TextEditingController(
    text: widget.patient.sexualFunction.sexualActivityFrequency ?? '',
  );

  @override
  void dispose() {
    _dificuldadeController.dispose();
    _frequenciaController.dispose();
    super.dispose();
  }

  void _update(SexualFunction Function(SexualFunction) update) {
    widget.onChanged(
      widget.patient.copyWith(
        sexualFunction: update(widget.patient.sexualFunction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = PatientsWizardStringsB(context.watch<LocaleCubit>().state);
    final funcao = widget.patient.sexualFunction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppYesNoToggle(
          label: t.sexuallyActiveLabel,
          value: funcao.sexuallyActive,
          onChanged: (value) =>
              _update((f) => f.copyWith(sexuallyActive: value)),
        ),
        if (funcao.sexuallyActive == true) ...[
          const SizedBox(height: 12),
          AppTextField(
            controller: _frequenciaController,
            icon: Icons.calendar_today_outlined,
            hintText: t.sexualActivityFrequencyHint,
            onChanged: (value) =>
                _update((f) => f.copyWith(sexualActivityFrequency: value)),
          ),
          const SizedBox(height: 12),
          AppYesNoToggle(
            label: t.needsLubricantLabel,
            value: funcao.needsLubricant,
            onChanged: (value) =>
                _update((f) => f.copyWith(needsLubricant: value)),
          ),
          const SizedBox(height: 12),
          AppYesNoToggle(
            label: t.drynessLabel,
            value: funcao.dryness,
            onChanged: (value) => _update((f) => f.copyWith(dryness: value)),
          ),
          const SizedBox(height: 12),
          AppYesNoToggle(
            label: t.orgasmDifficultyLabel,
            value: funcao.orgasmDifficulty,
            onChanged: (value) =>
                _update((f) => f.copyWith(orgasmDifficulty: value)),
          ),
          if (funcao.orgasmDifficulty == true) ...[
            const SizedBox(height: 8),
            AppTextField(
              controller: _dificuldadeController,
              icon: Icons.description_outlined,
              hintText: t.detailHint,
              onChanged: (value) => _update(
                (f) => f.copyWith(orgasmDifficultyDescription: value),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            t.painSectionHeader,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          AppYesNoToggle(
            label: t.painDuringPenetrationLabel,
            value: funcao.painDuringPenetration,
            onChanged: (value) =>
                _update((f) => f.copyWith(painDuringPenetration: value)),
          ),
          if (funcao.painDuringPenetration == true) ...[
            const SizedBox(height: 8),
            AppChipSelect<PenetrationPainType>(
              options: PenetrationPainType.values,
              labelBuilder: (option) => option.label,
              selected: funcao.penetrationPainType == null
                  ? {}
                  : {funcao.penetrationPainType!},
              onChanged: (selected) => _update(
                (f) => f.copyWith(
                  penetrationPainType: selected.isEmpty ? null : selected.first,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppYesNoToggle(
            label: t.painDuringOrAfterIntercourseLabel,
            value: funcao.painDuringOrAfterIntercourse,
            onChanged: (value) =>
                _update((f) => f.copyWith(painDuringOrAfterIntercourse: value)),
          ),
          if (funcao.painDuringPenetration == true ||
              funcao.painDuringOrAfterIntercourse == true) ...[
            const SizedBox(height: 12),
            AppScaleField(
              label: t.painIntensityLabel,
              value: funcao.painIntensity0to10,
              onChanged: (value) =>
                  _update((f) => f.copyWith(painIntensity0to10: value)),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            t.sexualDesireSectionHeader,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          AppChipSelect<SexualDesire>(
            options: SexualDesire.values,
            labelBuilder: (option) => option.label,
            selected: funcao.sexualDesire == null ? {} : {funcao.sexualDesire!},
            onChanged: (selected) => _update(
              (f) => f.copyWith(
                sexualDesire: selected.isEmpty ? null : selected.first,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
