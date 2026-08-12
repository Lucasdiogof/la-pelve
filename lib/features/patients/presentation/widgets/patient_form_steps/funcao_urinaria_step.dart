import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
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

  void _update(FuncaoUrinaria Function(FuncaoUrinaria) update) {
    widget.onChanged(
      widget.patient.copyWith(
        funcaoUrinaria: update(widget.patient.funcaoUrinaria),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final funcao = widget.patient.funcaoUrinaria;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _YesNoWithText(
          label: 'Urgência?',
          value: funcao.urgencia,
          controller: _controllerFor('urgencia', funcao.descricaoUrgencia),
          onToggle: (value) => _update((f) => f.copyWith(urgencia: value)),
          onText: (value) =>
              _update((f) => f.copyWith(descricaoUrgencia: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Perda associada à urgência?',
          value: funcao.perdaAssociadaUrgencia,
          onChanged: (value) =>
              _update((f) => f.copyWith(perdaAssociadaUrgencia: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Incontinência de esforço?',
          value: funcao.incontinenciaEsforco,
          onChanged: (value) =>
              _update((f) => f.copyWith(incontinenciaEsforco: value)),
        ),
        if (funcao.incontinenciaEsforco == true) ...[
          const SizedBox(height: 8),
          AppChipSelect<GatilhoIncontinencia>(
            options: GatilhoIncontinencia.values,
            labelBuilder: (option) => option.label,
            selected: funcao.gatilhosIncontinencia,
            multiSelect: true,
            onChanged: (selected) =>
                _update((f) => f.copyWith(gatilhosIncontinencia: selected)),
          ),
          if (funcao.gatilhosIncontinencia.contains(
            GatilhoIncontinencia.outros,
          )) ...[
            const SizedBox(height: 8),
            AppTextField(
              controller: _controllerFor(
                'outroGatilho',
                funcao.descricaoOutroGatilho,
              ),
              icon: Icons.description_outlined,
              hintText: 'Qual outro gatilho?',
              onChanged: (value) =>
                  _update((f) => f.copyWith(descricaoOutroGatilho: value)),
            ),
          ],
        ],
        if (funcao.perdaAssociadaUrgencia == true ||
            funcao.incontinenciaEsforco == true) ...[
          const SizedBox(height: 12),
          AppChipSelect<QuantidadePerda>(
            options: QuantidadePerda.values,
            labelBuilder: (option) => option.label,
            selected: funcao.quantidadePerda == null
                ? {}
                : {funcao.quantidadePerda!},
            onChanged: (selected) => _update(
              (f) => f.copyWith(
                quantidadePerda: selected.isEmpty ? null : selected.first,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Utiliza absorvente ou protetor?',
          value: funcao.utilizaAbsorvente,
          onChanged: (value) =>
              _update((f) => f.copyWith(utilizaAbsorvente: value)),
        ),
        if (funcao.utilizaAbsorvente == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _controllerFor(
              'quantosAbsorventes',
              funcao.quantosAbsorventes?.toString(),
            ),
            icon: Icons.numbers_outlined,
            hintText: 'Quantos por dia?',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: (value) => _update(
              (f) => f.copyWith(quantosAbsorventes: int.tryParse(value)),
            ),
          ),
        ],
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Dor ou ardência ao urinar?',
          value: funcao.dorArdenciaAoUrinar,
          onChanged: (value) =>
              _update((f) => f.copyWith(dorArdenciaAoUrinar: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Jato urinário fraco?',
          value: funcao.jatoUrinarioFraco,
          onChanged: (value) =>
              _update((f) => f.copyWith(jatoUrinarioFraco: value)),
        ),
        const SizedBox(height: 12),
        _YesNoWithText(
          label: 'Enurese noturna?',
          value: funcao.enureseNoturna,
          controller: _controllerFor('enurese', funcao.descricaoEnurese),
          onToggle: (value) =>
              _update((f) => f.copyWith(enureseNoturna: value)),
          onText: (value) =>
              _update((f) => f.copyWith(descricaoEnurese: value)),
        ),
        const SizedBox(height: 12),
        _YesNoWithText(
          label: 'Hesitação?',
          value: funcao.hesitacao,
          controller: _controllerFor('hesitacao', funcao.descricaoHesitacao),
          onToggle: (value) => _update((f) => f.copyWith(hesitacao: value)),
          onText: (value) =>
              _update((f) => f.copyWith(descricaoHesitacao: value)),
        ),
        const SizedBox(height: 12),
        _YesNoWithText(
          label: 'Esforço miccional?',
          value: funcao.esforcoMiccional,
          controller: _controllerFor(
            'esforco',
            funcao.descricaoEsforcoMiccional,
          ),
          onToggle: (value) =>
              _update((f) => f.copyWith(esforcoMiccional: value)),
          onText: (value) =>
              _update((f) => f.copyWith(descricaoEsforcoMiccional: value)),
        ),
        const SizedBox(height: 12),
        _YesNoWithText(
          label: 'Gotejamento pós miccional?',
          value: funcao.gotejamentoPosMiccional,
          controller: _controllerFor(
            'gotejamento',
            funcao.descricaoGotejamento,
          ),
          onToggle: (value) =>
              _update((f) => f.copyWith(gotejamentoPosMiccional: value)),
          onText: (value) =>
              _update((f) => f.copyWith(descricaoGotejamento: value)),
        ),
        const SizedBox(height: 12),
        _YesNoWithText(
          label: 'Esvaziamento incompleto?',
          value: funcao.esvaziamentoIncompleto,
          controller: _controllerFor(
            'esvaziamento',
            funcao.descricaoEsvaziamentoIncompleto,
          ),
          onToggle: (value) =>
              _update((f) => f.copyWith(esvaziamentoIncompleto: value)),
          onText: (value) => _update(
            (f) => f.copyWith(descricaoEsvaziamentoIncompleto: value),
          ),
        ),
      ],
    );
  }
}

class _YesNoWithText extends StatelessWidget {
  const _YesNoWithText({
    required this.label,
    required this.value,
    required this.controller,
    required this.onToggle,
    required this.onText,
  });

  final String label;
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
            hintText: 'Detalhe',
            onChanged: onText,
          ),
        ],
      ],
    );
  }
}
