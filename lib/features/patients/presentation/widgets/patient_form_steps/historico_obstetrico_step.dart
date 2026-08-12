import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/gestacao.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_yes_no_toggle.dart';

class HistoricoObstetricoStep extends StatefulWidget {
  const HistoricoObstetricoStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<HistoricoObstetricoStep> createState() =>
      _HistoricoObstetricoStepState();
}

class _HistoricoObstetricoStepState extends State<HistoricoObstetricoStep> {
  late final _numeroController = TextEditingController(
    text: widget.patient.historicoObstetrico.numeroGestacoes?.toString() ?? '',
  );
  late final _semanasController = TextEditingController(
    text: widget.patient.historicoObstetrico.semanasGestacao?.toString() ?? '',
  );
  late final _gestacaoRiscoController = TextEditingController(
    text: widget.patient.historicoObstetrico.descricaoGestacaoRisco ?? '',
  );

  @override
  void dispose() {
    _numeroController.dispose();
    _semanasController.dispose();
    _gestacaoRiscoController.dispose();
    super.dispose();
  }

  void _update(HistoricoObstetrico Function(HistoricoObstetrico) update) {
    widget.onChanged(
      widget.patient.copyWith(
        historicoObstetrico: update(widget.patient.historicoObstetrico),
      ),
    );
  }

  void _setNumeroGestacoes(String value) {
    final numero = int.tryParse(value);
    _update((h) {
      if (numero == null || numero < 1) {
        return h.copyWith(numeroGestacoes: numero, gestacoes: const []);
      }
      final gestacoes = List<Gestacao>.generate(
        numero,
        (index) =>
            index < h.gestacoes.length ? h.gestacoes[index] : const Gestacao(),
      );
      return h.copyWith(numeroGestacoes: numero, gestacoes: gestacoes);
    });
  }

  void _updateGestacao(int index, Gestacao gestacao) {
    _update((h) {
      final gestacoes = List<Gestacao>.from(h.gestacoes);
      gestacoes[index] = gestacao;
      return h.copyWith(gestacoes: gestacoes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final historico = widget.patient.historicoObstetrico;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppYesNoToggle(
          label: 'Está gestante atualmente?',
          value: historico.estaGestanteAtualmente,
          onChanged: (value) =>
              _update((h) => h.copyWith(estaGestanteAtualmente: value)),
        ),
        if (historico.estaGestanteAtualmente == true) ...[
          const SizedBox(height: 16),
          Text(
            'VIA DE PARTO DESEJADO',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          AppChipSelect<ViaDeParto>(
            options: ViaDeParto.values,
            labelBuilder: (option) => option.label,
            selected: historico.viaDePartoDesejado == null
                ? {}
                : {historico.viaDePartoDesejado!},
            onChanged: (selected) => _update(
              (h) => h.copyWith(
                viaDePartoDesejado: selected.isEmpty ? null : selected.first,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _semanasController,
            icon: Icons.numbers_outlined,
            hintText: 'Quantas semanas',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: (value) => _update(
              (h) => h.copyWith(semanasGestacao: int.tryParse(value)),
            ),
          ),
          const SizedBox(height: 12),
          AppDateField(
            hintText: 'Data provável do parto',
            value: historico.dataProvavelParto,
            onChanged: (value) =>
                _update((h) => h.copyWith(dataProvavelParto: value)),
          ),
          const SizedBox(height: 12),
          AppYesNoToggle(
            label: 'Gestação de risco?',
            value: historico.gestacaoDeRisco,
            onChanged: (value) =>
                _update((h) => h.copyWith(gestacaoDeRisco: value)),
          ),
          if (historico.gestacaoDeRisco == true) ...[
            const SizedBox(height: 8),
            AppTextField(
              controller: _gestacaoRiscoController,
              icon: Icons.description_outlined,
              hintText: 'Detalhe a gestação de risco',
              onChanged: (value) =>
                  _update((h) => h.copyWith(descricaoGestacaoRisco: value)),
            ),
          ],
        ],
        const SizedBox(height: 20),
        AppYesNoToggle(
          label: 'Já engravidou?',
          value: historico.jaEngravidou,
          onChanged: (value) => _update(
            (h) => h.copyWith(
              jaEngravidou: value,
              numeroGestacoes: value == true ? h.numeroGestacoes : null,
              gestacoes: value == true ? h.gestacoes : const [],
            ),
          ),
        ),
        if (historico.jaEngravidou == true) ...[
          const SizedBox(height: 12),
          AppTextField(
            controller: _numeroController,
            icon: Icons.numbers_outlined,
            hintText: 'Quantas gestações?',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: _setNumeroGestacoes,
          ),
          for (var i = 0; i < historico.gestacoes.length; i++) ...[
            const SizedBox(height: 20),
            _GestacaoCard(
              index: i,
              gestacao: historico.gestacoes[i],
              onChanged: (gestacao) => _updateGestacao(i, gestacao),
            ),
          ],
        ],
      ],
    );
  }
}

class _GestacaoCard extends StatefulWidget {
  const _GestacaoCard({
    required this.index,
    required this.gestacao,
    required this.onChanged,
  });

  final int index;
  final Gestacao gestacao;
  final ValueChanged<Gestacao> onChanged;

  @override
  State<_GestacaoCard> createState() => _GestacaoCardState();
}

class _GestacaoCardState extends State<_GestacaoCard> {
  late final _perdaController = TextEditingController(
    text: widget.gestacao.descricaoPerda ?? '',
  );
  late final _complicacaoController = TextEditingController(
    text: widget.gestacao.descricaoComplicacao ?? '',
  );
  late final _pesoBebeController = TextEditingController(
    text: widget.gestacao.pesoAproximadoBebe ?? '',
  );

  @override
  void dispose() {
    _perdaController.dispose();
    _complicacaoController.dispose();
    _pesoBebeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gestacao = widget.gestacao;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestação ${widget.index + 1}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 12),
          AppYesNoToggle(
            label: 'Perda gestacional?',
            value: gestacao.perdaGestacional,
            onChanged: (value) => widget.onChanged(
              widget.gestacao.copyWith(perdaGestacional: value),
            ),
          ),
          if (gestacao.perdaGestacional == true) ...[
            const SizedBox(height: 8),
            AppTextField(
              controller: _perdaController,
              icon: Icons.description_outlined,
              hintText: 'Detalhe a perda gestacional',
              onChanged: (value) => widget.onChanged(
                widget.gestacao.copyWith(descricaoPerda: value),
              ),
            ),
          ] else if (gestacao.perdaGestacional == false) ...[
            const SizedBox(height: 12),
            AppChipSelect<ViaDeParto>(
              options: ViaDeParto.values,
              labelBuilder: (option) => option.label,
              selected: gestacao.viaDeParto == null
                  ? {}
                  : {gestacao.viaDeParto!},
              onChanged: (selected) => widget.onChanged(
                widget.gestacao.copyWith(
                  viaDeParto: selected.isEmpty ? null : selected.first,
                ),
              ),
            ),
            if (gestacao.viaDeParto == ViaDeParto.normal) ...[
              const SizedBox(height: 12),
              AppChipSelect<ComplicacaoParto>(
                options: ComplicacaoParto.values,
                labelBuilder: (option) => option.label,
                selected: gestacao.complicacaoParto == null
                    ? {}
                    : {gestacao.complicacaoParto!},
                onChanged: (selected) => widget.onChanged(
                  widget.gestacao.copyWith(
                    complicacaoParto: selected.isEmpty ? null : selected.first,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppYesNoToggle(
                label: 'Uso de fórceps ou vácuo?',
                value: gestacao.usoForcepsOuVacuo,
                onChanged: (value) => widget.onChanged(
                  widget.gestacao.copyWith(usoForcepsOuVacuo: value),
                ),
              ),
            ],
            const SizedBox(height: 12),
            AppTextField(
              controller: _pesoBebeController,
              icon: Icons.monitor_weight_outlined,
              hintText: 'Peso aproximado do bebê',
              onChanged: (value) => widget.onChanged(
                widget.gestacao.copyWith(pesoAproximadoBebe: value),
              ),
            ),
            const SizedBox(height: 12),
            AppYesNoToggle(
              label: 'Teve complicações?',
              value: gestacao.teveComplicacoes,
              onChanged: (value) => widget.onChanged(
                widget.gestacao.copyWith(teveComplicacoes: value),
              ),
            ),
            if (gestacao.teveComplicacoes == true) ...[
              const SizedBox(height: 8),
              AppTextField(
                controller: _complicacaoController,
                icon: Icons.description_outlined,
                hintText: 'Detalhe as complicações',
                onChanged: (value) => widget.onChanged(
                  widget.gestacao.copyWith(descricaoComplicacao: value),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
