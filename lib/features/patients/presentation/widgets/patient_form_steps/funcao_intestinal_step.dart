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
    text:
        widget.patient.funcaoIntestinal.frequenciaPersonalizadaValor
            ?.toString() ??
        '',
  );
  late final _laxanteController = TextEditingController(
    text: widget.patient.funcaoIntestinal.descricaoLaxante ?? '',
  );

  @override
  void dispose() {
    _frequenciaPersonalizadaController.dispose();
    _laxanteController.dispose();
    super.dispose();
  }

  void _update(FuncaoIntestinal Function(FuncaoIntestinal) update) {
    widget.onChanged(
      widget.patient.copyWith(
        funcaoIntestinal: update(widget.patient.funcaoIntestinal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final funcao = widget.patient.funcaoIntestinal;
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
        AppChipSelect<FrequenciaEvacuatoria>(
          options: FrequenciaEvacuatoria.values,
          labelBuilder: (option) => option.label,
          selected: funcao.frequenciaEvacuatoria == null
              ? {}
              : {funcao.frequenciaEvacuatoria!},
          onChanged: (selected) => _update(
            (f) => f.copyWith(
              frequenciaEvacuatoria: selected.isEmpty ? null : selected.first,
            ),
          ),
        ),
        if (funcao.frequenciaEvacuatoria ==
            FrequenciaEvacuatoria.personalizado) ...[
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
              (f) =>
                  f.copyWith(frequenciaPersonalizadaValor: int.tryParse(value)),
            ),
          ),
        ],
        const SizedBox(height: 20),
        AppYesNoToggle(
          label: 'Usa laxante?',
          value: funcao.usaLaxante,
          onChanged: (value) => _update((f) => f.copyWith(usaLaxante: value)),
        ),
        if (funcao.usaLaxante == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _laxanteController,
            icon: Icons.medication_outlined,
            hintText: 'Qual laxante e frequência?',
            onChanged: (value) =>
                _update((f) => f.copyWith(descricaoLaxante: value)),
          ),
        ],
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Faz força para evacuar?',
          value: funcao.forcaParaEvacuar,
          onChanged: (value) =>
              _update((f) => f.copyWith(forcaParaEvacuar: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Sente dor para evacuar?',
          value: funcao.dorParaEvacuar,
          onChanged: (value) =>
              _update((f) => f.copyWith(dorParaEvacuar: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Sensação de esvaziamento incompleto?',
          value: funcao.esvaziamentoIncompleto,
          onChanged: (value) =>
              _update((f) => f.copyWith(esvaziamentoIncompleto: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Sensação de obstrução?',
          value: funcao.sensacaoObstrucao,
          onChanged: (value) =>
              _update((f) => f.copyWith(sensacaoObstrucao: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Urgência fecal?',
          value: funcao.urgenciaFecal,
          onChanged: (value) =>
              _update((f) => f.copyWith(urgenciaFecal: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Presença de hemorroidas?',
          value: funcao.presencaHemorroidas,
          onChanged: (value) =>
              _update((f) => f.copyWith(presencaHemorroidas: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Perde gases?',
          value: funcao.perdeGases,
          onChanged: (value) => _update((f) => f.copyWith(perdeGases: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Perde fezes?',
          value: funcao.perdeFezes,
          onChanged: (value) => _update((f) => f.copyWith(perdeFezes: value)),
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
        AppChipSelect<EscalaBristol>(
          options: EscalaBristol.values,
          labelBuilder: (option) => option.label,
          selected: funcao.escalaBristol == null ? {} : {funcao.escalaBristol!},
          onChanged: (selected) => _update(
            (f) => f.copyWith(
              escalaBristol: selected.isEmpty ? null : selected.first,
            ),
          ),
        ),
      ],
    );
  }
}
