import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_wizard_strings_b.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/pages/image_viewer_page.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_yes_no_toggle.dart';

class BowelFunctionStep extends StatefulWidget {
  const BowelFunctionStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<BowelFunctionStep> createState() => _BowelFunctionStepState();
}

class _BowelFunctionStepState extends State<BowelFunctionStep> {
  late final _frequenciaPersonalizadaController = TextEditingController(
    text: widget.patient.bowelFunction.customFrequencyValue?.toString() ?? '',
  );
  late final _laxanteController = TextEditingController(
    text: widget.patient.bowelFunction.laxativeDescription ?? '',
  );

  @override
  void dispose() {
    _frequenciaPersonalizadaController.dispose();
    _laxanteController.dispose();
    super.dispose();
  }

  void _update(BowelFunction Function(BowelFunction) update) {
    widget.onChanged(
      widget.patient.copyWith(
        bowelFunction: update(widget.patient.bowelFunction),
      ),
    );
  }

  void _showBristolScale(PatientsWizardStringsB t) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImageViewerPage(
          assetPath: 'lib/assets/escala_bristol.png',
          title: t.bristolScaleImageTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = PatientsWizardStringsB(context.watch<LocaleCubit>().state);
    final funcao = widget.patient.bowelFunction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.bowelFrequencySectionHeader,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        AppChipSelect<BowelFrequency>(
          options: BowelFrequency.values,
          labelBuilder: (option) => option.label(t.language),
          selected: funcao.bowelFrequency == null
              ? {}
              : {funcao.bowelFrequency!},
          onChanged: (selected) => _update(
            (f) => f.copyWith(
              bowelFrequency: selected.isEmpty ? null : selected.first,
            ),
          ),
        ),
        if (funcao.bowelFrequency == BowelFrequency.custom) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _frequenciaPersonalizadaController,
            icon: Icons.numbers_outlined,
            hintText: t.timesPerWeekHint,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: (value) => _update(
              (f) => f.copyWith(customFrequencyValue: int.tryParse(value)),
            ),
          ),
        ],
        const SizedBox(height: 20),
        AppYesNoToggle(
          label: t.usesLaxativeLabel,
          value: funcao.usesLaxative,
          onChanged: (value) => _update((f) => f.copyWith(usesLaxative: value)),
        ),
        if (funcao.usesLaxative == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _laxanteController,
            icon: Icons.medication_outlined,
            hintText: t.laxativeDescriptionHint,
            onChanged: (value) =>
                _update((f) => f.copyWith(laxativeDescription: value)),
          ),
        ],
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.strainsToDefecateLabel,
          value: funcao.strainsToDefecate,
          onChanged: (value) =>
              _update((f) => f.copyWith(strainsToDefecate: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.painToDefecateLabel,
          value: funcao.painToDefecate,
          onChanged: (value) =>
              _update((f) => f.copyWith(painToDefecate: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.incompleteEmptyingBowelLabel,
          value: funcao.incompleteEmptying,
          onChanged: (value) =>
              _update((f) => f.copyWith(incompleteEmptying: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.obstructionSensationLabel,
          value: funcao.obstructionSensation,
          onChanged: (value) =>
              _update((f) => f.copyWith(obstructionSensation: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.fecalUrgencyLabel,
          value: funcao.fecalUrgency,
          onChanged: (value) => _update((f) => f.copyWith(fecalUrgency: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.hemorrhoidsLabel,
          value: funcao.hemorrhoids,
          onChanged: (value) => _update((f) => f.copyWith(hemorrhoids: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.gasIncontinenceLabel,
          value: funcao.gasIncontinence,
          onChanged: (value) =>
              _update((f) => f.copyWith(gasIncontinence: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.fecalIncontinenceLabel,
          value: funcao.fecalIncontinence,
          onChanged: (value) =>
              _update((f) => f.copyWith(fecalIncontinence: value)),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              t.bristolScaleSectionHeader,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: t.bristolScaleInfoTooltip,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showBristolScale(t),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: context.colors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppChipSelect<BristolScale>(
          options: BristolScale.values,
          labelBuilder: (option) => option.label(t.language),
          selected: funcao.bristolScale == null ? {} : {funcao.bristolScale!},
          onChanged: (selected) => _update(
            (f) => f.copyWith(
              bristolScale: selected.isEmpty ? null : selected.first,
            ),
          ),
        ),
      ],
    );
  }
}
