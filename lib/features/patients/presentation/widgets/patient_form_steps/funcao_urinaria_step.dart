import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_wizard_strings_b.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_yes_no_toggle.dart';

class FuncaoUrinariaStep extends StatefulWidget {
  const FuncaoUrinariaStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<FuncaoUrinariaStep> createState() => _FuncaoUrinariaStepState();
}

class _FuncaoUrinariaStepState extends State<FuncaoUrinariaStep> {
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _controllerFor(String key, String? initial) {
    return _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: initial ?? ''),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _update(UrinaryFunction Function(UrinaryFunction) update) {
    widget.onChanged(
      widget.patient.copyWith(
        urinaryFunction: update(widget.patient.urinaryFunction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = PatientsWizardStringsB(context.watch<LocaleCubit>().state);
    final funcao = widget.patient.urinaryFunction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _YesNoWithText(
          label: t.urinaryUrgencyLabel,
          detailHint: t.detailHint,
          value: funcao.urgency,
          controller: _controllerFor('urgencia', funcao.urgencyDescription),
          onToggle: (value) => _update((f) => f.copyWith(urgency: value)),
          onText: (value) =>
              _update((f) => f.copyWith(urgencyDescription: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.leakageAssociatedWithUrgencyLabel,
          value: funcao.urgencyAssociatedLeakage,
          onChanged: (value) =>
              _update((f) => f.copyWith(urgencyAssociatedLeakage: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.stressIncontinenceLabel,
          value: funcao.stressIncontinence,
          onChanged: (value) =>
              _update((f) => f.copyWith(stressIncontinence: value)),
        ),
        if (funcao.stressIncontinence == true) ...[
          const SizedBox(height: 8),
          AppChipSelect<IncontinenceTrigger>(
            options: IncontinenceTrigger.values,
            labelBuilder: (option) => option.label,
            selected: funcao.incontinenceTriggers,
            multiSelect: true,
            onChanged: (selected) =>
                _update((f) => f.copyWith(incontinenceTriggers: selected)),
          ),
          if (funcao.incontinenceTriggers.contains(
            IncontinenceTrigger.other,
          )) ...[
            const SizedBox(height: 8),
            AppTextField(
              controller: _controllerFor(
                'outroGatilho',
                funcao.otherTriggerDescription,
              ),
              icon: Icons.description_outlined,
              hintText: t.otherTriggerHint,
              onChanged: (value) =>
                  _update((f) => f.copyWith(otherTriggerDescription: value)),
            ),
          ],
        ],
        if (funcao.urgencyAssociatedLeakage == true ||
            funcao.stressIncontinence == true) ...[
          const SizedBox(height: 12),
          AppChipSelect<LeakageAmount>(
            options: LeakageAmount.values,
            labelBuilder: (option) => option.label,
            selected: funcao.leakageAmount == null
                ? {}
                : {funcao.leakageAmount!},
            onChanged: (selected) => _update(
              (f) => f.copyWith(
                leakageAmount: selected.isEmpty ? null : selected.first,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.usesPadsLabel,
          value: funcao.usesPads,
          onChanged: (value) => _update((f) => f.copyWith(usesPads: value)),
        ),
        if (funcao.usesPads == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _controllerFor(
              'quantosAbsorventes',
              funcao.padsPerDay?.toString(),
            ),
            icon: Icons.numbers_outlined,
            hintText: t.padsPerDayHint,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: (value) =>
                _update((f) => f.copyWith(padsPerDay: int.tryParse(value))),
          ),
        ],
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.painOrBurningWhenUrinatingLabel,
          value: funcao.painOrBurningWhenUrinating,
          onChanged: (value) =>
              _update((f) => f.copyWith(painOrBurningWhenUrinating: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.weakUrinaryStreamLabel,
          value: funcao.weakUrinaryStream,
          onChanged: (value) =>
              _update((f) => f.copyWith(weakUrinaryStream: value)),
        ),
        const SizedBox(height: 12),
        _YesNoWithText(
          label: t.nocturnalEnuresisLabel,
          detailHint: t.detailHint,
          value: funcao.nocturnalEnuresis,
          controller: _controllerFor('enurese', funcao.enuresisDescription),
          onToggle: (value) =>
              _update((f) => f.copyWith(nocturnalEnuresis: value)),
          onText: (value) =>
              _update((f) => f.copyWith(enuresisDescription: value)),
        ),
        const SizedBox(height: 12),
        _YesNoWithText(
          label: t.hesitancyLabel,
          detailHint: t.detailHint,
          value: funcao.hesitancy,
          controller: _controllerFor('hesitacao', funcao.hesitancyDescription),
          onToggle: (value) => _update((f) => f.copyWith(hesitancy: value)),
          onText: (value) =>
              _update((f) => f.copyWith(hesitancyDescription: value)),
        ),
        const SizedBox(height: 12),
        _YesNoWithText(
          label: t.urinaryStrainingLabel,
          detailHint: t.detailHint,
          value: funcao.urinaryStraining,
          controller: _controllerFor(
            'esforco',
            funcao.urinaryStrainingDescription,
          ),
          onToggle: (value) =>
              _update((f) => f.copyWith(urinaryStraining: value)),
          onText: (value) =>
              _update((f) => f.copyWith(urinaryStrainingDescription: value)),
        ),
        const SizedBox(height: 12),
        _YesNoWithText(
          label: t.postVoidDribblingLabel,
          detailHint: t.detailHint,
          value: funcao.postVoidDribbling,
          controller: _controllerFor(
            'gotejamento',
            funcao.dribblingDescription,
          ),
          onToggle: (value) =>
              _update((f) => f.copyWith(postVoidDribbling: value)),
          onText: (value) =>
              _update((f) => f.copyWith(dribblingDescription: value)),
        ),
        const SizedBox(height: 12),
        _YesNoWithText(
          label: t.incompleteEmptyingUrinaryLabel,
          detailHint: t.detailHint,
          value: funcao.incompleteEmptying,
          controller: _controllerFor(
            'esvaziamento',
            funcao.incompleteEmptyingDescription,
          ),
          onToggle: (value) =>
              _update((f) => f.copyWith(incompleteEmptying: value)),
          onText: (value) =>
              _update((f) => f.copyWith(incompleteEmptyingDescription: value)),
        ),
      ],
    );
  }
}

class _YesNoWithText extends StatelessWidget {
  const _YesNoWithText({
    required this.label,
    required this.detailHint,
    required this.value,
    required this.controller,
    required this.onToggle,
    required this.onText,
  });

  final String label;
  final String detailHint;
  final bool? value;
  final TextEditingController controller;
  final ValueChanged<bool?> onToggle;
  final ValueChanged<String> onText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppYesNoToggle(label: label, value: value, onChanged: onToggle),
        if (value == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: controller,
            icon: Icons.description_outlined,
            hintText: detailHint,
            onChanged: onText,
          ),
        ],
      ],
    );
  }
}
