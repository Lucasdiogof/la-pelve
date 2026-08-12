import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';

class HistoricoCirurgicoStep extends StatefulWidget {
  const HistoricoCirurgicoStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<HistoricoCirurgicoStep> createState() => _HistoricoCirurgicoStepState();
}

class _HistoricoCirurgicoStepState extends State<HistoricoCirurgicoStep> {
  late final _outraController = TextEditingController(
    text: widget.patient.historicoCirurgico.descricaoOutraCirurgia ?? '',
  );

  @override
  void dispose() {
    _outraController.dispose();
    super.dispose();
  }

  void _update(HistoricoCirurgico Function(HistoricoCirurgico) update) {
    widget.onChanged(
      widget.patient.copyWith(
        historicoCirurgico: update(widget.patient.historicoCirurgico),
      ),
    );
  }

  static const _somenteFeminino = {
    CirurgiaGinecologica.histerectomia,
    CirurgiaGinecologica.laqueadura,
    CirurgiaGinecologica.perineoplastia,
  };

  @override
  Widget build(BuildContext context) {
    final historico = widget.patient.historicoCirurgico;
    final isFeminino = widget.patient.dadosPessoais.sexo == Sexo.feminino;
    final opcoes = isFeminino
        ? CirurgiaGinecologica.values
        : CirurgiaGinecologica.values
              .where((c) => !_somenteFeminino.contains(c))
              .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppChipSelect<CirurgiaGinecologica>(
          options: opcoes,
          labelBuilder: (option) => option.label,
          selected: historico.cirurgias,
          multiSelect: true,
          onChanged: (selected) {
            final tappedNenhum =
                selected.contains(CirurgiaGinecologica.nenhum) &&
                !historico.cirurgias.contains(CirurgiaGinecologica.nenhum);
            final cirurgias = tappedNenhum
                ? {CirurgiaGinecologica.nenhum}
                : (selected..remove(CirurgiaGinecologica.nenhum));
            _update((h) => h.copyWith(cirurgias: cirurgias));
          },
        ),
        if (historico.cirurgias.contains(CirurgiaGinecologica.outro)) ...[
          const SizedBox(height: 12),
          AppTextField(
            controller: _outraController,
            icon: Icons.description_outlined,
            hintText: 'Qual cirurgia?',
            onChanged: (value) =>
                _update((h) => h.copyWith(descricaoOutraCirurgia: value)),
          ),
        ],
      ],
    );
  }
}
