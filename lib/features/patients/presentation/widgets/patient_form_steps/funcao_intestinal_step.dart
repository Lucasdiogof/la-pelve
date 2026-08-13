import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_yes_no_toggle.dart';

class FuncaoIntestinalStep extends StatefulWidget {
  const FuncaoIntestinalStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<FuncaoIntestinalStep> createState() => _FuncaoIntestinalStepState();
}

class _FuncaoIntestinalStepState extends State<FuncaoIntestinalStep> {
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

  @override
  Widget build(BuildContext context) {
    final funcao = widget.patient.bowelFunction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FREQUÊNCIA EVACUATÓRIA',
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
          labelBuilder: (option) => option.label,
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
            hintText: 'Quantas vezes por semana?',
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
          label: 'Usa laxante?',
          value: funcao.usesLaxative,
          onChanged: (value) => _update((f) => f.copyWith(usesLaxative: value)),
        ),
        if (funcao.usesLaxative == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _laxanteController,
            icon: Icons.medication_outlined,
            hintText: 'Qual laxante e frequência?',
            onChanged: (value) =>
                _update((f) => f.copyWith(laxativeDescription: value)),
          ),
        ],
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Faz força para evacuar?',
          value: funcao.strainsToDefecate,
          onChanged: (value) =>
              _update((f) => f.copyWith(strainsToDefecate: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Sente dor para evacuar?',
          value: funcao.painToDefecate,
          onChanged: (value) =>
              _update((f) => f.copyWith(painToDefecate: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Sensação de esvaziamento incompleto?',
          value: funcao.incompleteEmptying,
          onChanged: (value) =>
              _update((f) => f.copyWith(incompleteEmptying: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Sensação de obstrução?',
          value: funcao.obstructionSensation,
          onChanged: (value) =>
              _update((f) => f.copyWith(obstructionSensation: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Urgência fecal?',
          value: funcao.fecalUrgency,
          onChanged: (value) => _update((f) => f.copyWith(fecalUrgency: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Presença de hemorroidas?',
          value: funcao.hemorrhoids,
          onChanged: (value) => _update((f) => f.copyWith(hemorrhoids: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Perde gases?',
          value: funcao.gasIncontinence,
          onChanged: (value) =>
              _update((f) => f.copyWith(gasIncontinence: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Perde fezes?',
          value: funcao.fecalIncontinence,
          onChanged: (value) =>
              _update((f) => f.copyWith(fecalIncontinence: value)),
        ),
        const SizedBox(height: 20),
        Text(
          'ESCALA DE BRISTOL',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        AppChipSelect<BristolScale>(
          options: BristolScale.values,
          labelBuilder: (option) => option.label,
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
