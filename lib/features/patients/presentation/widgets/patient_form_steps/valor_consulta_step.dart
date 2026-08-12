import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/shared/utils/currency_input_formatter.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';

class ValorConsultaStep extends StatefulWidget {
  const ValorConsultaStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<ValorConsultaStep> createState() => _ValorConsultaStepState();
}

class _ValorConsultaStepState extends State<ValorConsultaStep> {
  late final _valorController = TextEditingController(
    text: widget.patient.valorConsulta == null
        ? ''
        : CurrencyInputFormatter.format(widget.patient.valorConsulta!),
  );

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valor cobrado nesta primeira consulta. Campo apenas informativo — '
          'não entra no controle financeiro.',
          style: TextStyle(color: context.colors.textSecondary),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _valorController,
          icon: Icons.attach_money,
          hintText: 'Valor da consulta',
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          onChanged: (value) => widget.onChanged(
            widget.patient.copyWith(
              valorConsulta: CurrencyInputFormatter.parse(value),
            ),
          ),
        ),
      ],
    );
  }
}
