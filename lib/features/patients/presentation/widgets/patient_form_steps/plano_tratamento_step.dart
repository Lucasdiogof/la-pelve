import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';

class PlanoTratamentoStep extends StatefulWidget {
  const PlanoTratamentoStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<PlanoTratamentoStep> createState() => _PlanoTratamentoStepState();
}

class _PlanoTratamentoStepState extends State<PlanoTratamentoStep> {
  late final _diagnosticoController = TextEditingController(
    text: widget.patient.planoTratamento.diagnosticoFisioterapeutico ?? '',
  );
  late final _objetivoController = TextEditingController(
    text: widget.patient.planoTratamento.objetivoTratamento ?? '',
  );
  late final _condutaController = TextEditingController(
    text: widget.patient.planoTratamento.condutaTratamento ?? '',
  );
  late final _frequenciaController = TextEditingController(
    text: widget.patient.planoTratamento.frequenciaSugerida ?? '',
  );

  @override
  void dispose() {
    _diagnosticoController.dispose();
    _objetivoController.dispose();
    _condutaController.dispose();
    _frequenciaController.dispose();
    super.dispose();
  }

  void _update(PlanoTratamento Function(PlanoTratamento) update) {
    widget.onChanged(
      widget.patient.copyWith(
        planoTratamento: update(widget.patient.planoTratamento),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _diagnosticoController,
          icon: Icons.fact_check_outlined,
          hintText: 'Diagnóstico fisioterapêutico',
          maxLines: 4,
          onChanged: (value) =>
              _update((p) => p.copyWith(diagnosticoFisioterapeutico: value)),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _objetivoController,
          icon: Icons.flag_outlined,
          hintText: 'Objetivo do tratamento',
          maxLines: 4,
          onChanged: (value) =>
              _update((p) => p.copyWith(objetivoTratamento: value)),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _condutaController,
          icon: Icons.checklist_outlined,
          hintText: 'Conduta / plano de tratamento',
          maxLines: 4,
          onChanged: (value) =>
              _update((p) => p.copyWith(condutaTratamento: value)),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _frequenciaController,
          icon: Icons.event_repeat_outlined,
          hintText: 'Frequência sugerida (opcional)',
          onChanged: (value) =>
              _update((p) => p.copyWith(frequenciaSugerida: value)),
        ),
      ],
    );
  }
}
