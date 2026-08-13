import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_scale_field.dart';
import 'package:fisioterapia_pelvica/shared/utils/validators.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_yes_no_toggle.dart';

class HistoricoGinecologicoStep extends StatefulWidget {
  const HistoricoGinecologicoStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<HistoricoGinecologicoStep> createState() =>
      _HistoricoGinecologicoStepState();
}

class _HistoricoGinecologicoStepState extends State<HistoricoGinecologicoStep> {
  late final _idadeMenstruacaoController = TextEditingController(
    text:
        widget.patient.historicoGinecologico.idadePrimeiraMenstruacao
            ?.toString() ??
        '',
  );
  late final _reposicaoHormonalController = TextEditingController(
    text: widget.patient.historicoGinecologico.descricaoReposicaoHormonal ?? '',
  );

  @override
  void dispose() {
    _idadeMenstruacaoController.dispose();
    _reposicaoHormonalController.dispose();
    super.dispose();
  }

  void _update(HistoricoGinecologico Function(HistoricoGinecologico) update) {
    widget.onChanged(
      widget.patient.copyWith(
        historicoGinecologico: update(widget.patient.historicoGinecologico),
      ),
    );
  }

  String? get _idadeMenstruacaoError =>
      ageErrorText(_idadeMenstruacaoController.text);

  @override
  Widget build(BuildContext context) {
    final historico = widget.patient.historicoGinecologico;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _idadeMenstruacaoController,
          icon: Icons.calendar_today_outlined,
          hintText: 'Idade da primeira menstruação',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          errorText: _idadeMenstruacaoError,
          onChanged: (value) => _update(
            (h) => h.copyWith(idadePrimeiraMenstruacao: int.tryParse(value)),
          ),
        ),
        const SizedBox(height: 16),
        AppChipSelect<FluxoMenstrual>(
          options: FluxoMenstrual.values,
          labelBuilder: (option) => option.label,
          selected: historico.fluxoMenstrual == null
              ? {}
              : {historico.fluxoMenstrual!},
          onChanged: (selected) => _update(
            (h) => h.copyWith(
              fluxoMenstrual: selected.isEmpty ? null : selected.first,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppScaleField(
          label: 'Presença de cólica',
          value: historico.colica0a10,
          onChanged: (value) => _update((h) => h.copyWith(colica0a10: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Menstrua atualmente?',
          value: historico.menstruaAtualmente,
          onChanged: (value) =>
              _update((h) => h.copyWith(menstruaAtualmente: value)),
        ),
        if (historico.menstruaAtualmente == false) ...[
          const SizedBox(height: 8),
          AppYesNoToggle(
            label: 'Está na menopausa?',
            value: historico.estaNaMenopausa,
            onChanged: (value) =>
                _update((h) => h.copyWith(estaNaMenopausa: value)),
          ),
          const SizedBox(height: 8),
          AppDateField(
            hintText: 'Data aproximada da última menstruação',
            value: historico.dataUltimaMenstruacaoAproximada,
            onChanged: (value) => _update(
              (h) => h.copyWith(dataUltimaMenstruacaoAproximada: value),
            ),
          ),
        ],
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Ciclo regular?',
          value: historico.cicloRegular,
          onChanged: (value) => _update((h) => h.copyWith(cicloRegular: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Menopausa?',
          value: historico.menopausa,
          onChanged: (value) => _update((h) => h.copyWith(menopausa: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Faz reposição hormonal?',
          value: historico.reposicaoHormonal,
          onChanged: (value) =>
              _update((h) => h.copyWith(reposicaoHormonal: value)),
        ),
        if (historico.reposicaoHormonal == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _reposicaoHormonalController,
            icon: Icons.medication_outlined,
            hintText: 'Detalhe a reposição hormonal',
            onChanged: (value) =>
                _update((h) => h.copyWith(descricaoReposicaoHormonal: value)),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'MÉTODO CONTRACEPTIVO',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        AppChipSelect<MetodoContraceptivo>(
          options: MetodoContraceptivo.values,
          labelBuilder: (option) => option.label,
          selected: historico.metodoContraceptivo == null
              ? {}
              : {historico.metodoContraceptivo!},
          onChanged: (selected) => _update(
            (h) => h.copyWith(
              metodoContraceptivo: selected.isEmpty ? null : selected.first,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'OUTROS SINTOMAS',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Dor pélvica fora do período menstrual?',
          value: historico.dorPelvicaForaPeriodo,
          onChanged: (value) =>
              _update((h) => h.copyWith(dorPelvicaForaPeriodo: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Sangramento fora do período menstrual?',
          value: historico.sangramentoForaPeriodo,
          onChanged: (value) =>
              _update((h) => h.copyWith(sangramentoForaPeriodo: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Endometriose?',
          value: historico.endometriose,
          onChanged: (value) => _update((h) => h.copyWith(endometriose: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Síndrome dos ovários policísticos?',
          value: historico.sindromeOvariosPolicisticos,
          onChanged: (value) =>
              _update((h) => h.copyWith(sindromeOvariosPolicisticos: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Infecções urinárias recorrentes?',
          value: historico.infeccoesUrinariasRecorrentes,
          onChanged: (value) =>
              _update((h) => h.copyWith(infeccoesUrinariasRecorrentes: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Infecções vaginais recorrentes?',
          value: historico.infeccoesVaginaisRecorrentes,
          onChanged: (value) =>
              _update((h) => h.copyWith(infeccoesVaginaisRecorrentes: value)),
        ),
      ],
    );
  }
}
