import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/pregnancy.dart';
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
    text: widget.patient.obstetricHistory.pregnancyCount?.toString() ?? '',
  );
  late final _semanasController = TextEditingController(
    text: widget.patient.obstetricHistory.gestationWeeks?.toString() ?? '',
  );
  late final _gestacaoRiscoController = TextEditingController(
    text: widget.patient.obstetricHistory.highRiskPregnancyDescription ?? '',
  );

  @override
  void dispose() {
    _numeroController.dispose();
    _semanasController.dispose();
    _gestacaoRiscoController.dispose();
    super.dispose();
  }

  void _update(ObstetricHistory Function(ObstetricHistory) update) {
    widget.onChanged(
      widget.patient.copyWith(
        obstetricHistory: update(widget.patient.obstetricHistory),
      ),
    );
  }

  void _setNumeroGestacoes(String value) {
    final numero = int.tryParse(value);
    _update((h) {
      if (numero == null || numero < 1) {
        return h.copyWith(pregnancyCount: numero, pregnancies: const []);
      }
      final pregnancies = List<Pregnancy>.generate(
        numero,
        (index) => index < h.pregnancies.length
            ? h.pregnancies[index]
            : const Pregnancy(),
      );
      return h.copyWith(pregnancyCount: numero, pregnancies: pregnancies);
    });
  }

  void _updateGestacao(int index, Pregnancy pregnancy) {
    _update((h) {
      final pregnancies = List<Pregnancy>.from(h.pregnancies);
      pregnancies[index] = pregnancy;
      return h.copyWith(pregnancies: pregnancies);
    });
  }

  @override
  Widget build(BuildContext context) {
    final historico = widget.patient.obstetricHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppYesNoToggle(
          label: 'Está gestante atualmente?',
          value: historico.currentlyPregnant,
          onChanged: (value) =>
              _update((h) => h.copyWith(currentlyPregnant: value)),
        ),
        if (historico.currentlyPregnant == true) ...[
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
          AppChipSelect<DeliveryMethod>(
            options: DeliveryMethod.values,
            labelBuilder: (option) => option.label,
            selected: historico.desiredDeliveryMethod == null
                ? {}
                : {historico.desiredDeliveryMethod!},
            onChanged: (selected) => _update(
              (h) => h.copyWith(
                desiredDeliveryMethod: selected.isEmpty ? null : selected.first,
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
            onChanged: (value) =>
                _update((h) => h.copyWith(gestationWeeks: int.tryParse(value))),
          ),
          const SizedBox(height: 12),
          AppDateField(
            hintText: 'Data provável do parto',
            value: historico.estimatedDeliveryDate,
            onChanged: (value) =>
                _update((h) => h.copyWith(estimatedDeliveryDate: value)),
          ),
          const SizedBox(height: 12),
          AppYesNoToggle(
            label: 'Gestação de risco?',
            value: historico.highRiskPregnancy,
            onChanged: (value) =>
                _update((h) => h.copyWith(highRiskPregnancy: value)),
          ),
          if (historico.highRiskPregnancy == true) ...[
            const SizedBox(height: 8),
            AppTextField(
              controller: _gestacaoRiscoController,
              icon: Icons.description_outlined,
              hintText: 'Detalhe a gestação de risco',
              onChanged: (value) => _update(
                (h) => h.copyWith(highRiskPregnancyDescription: value),
              ),
            ),
          ],
        ],
        const SizedBox(height: 20),
        AppYesNoToggle(
          label: 'Já engravidou?',
          value: historico.hasBeenPregnant,
          onChanged: (value) => _update(
            (h) => h.copyWith(
              hasBeenPregnant: value,
              pregnancyCount: value == true ? h.pregnancyCount : null,
              pregnancies: value == true ? h.pregnancies : const [],
            ),
          ),
        ),
        if (historico.hasBeenPregnant == true) ...[
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
          for (var i = 0; i < historico.pregnancies.length; i++) ...[
            const SizedBox(height: 20),
            _GestacaoCard(
              index: i,
              pregnancy: historico.pregnancies[i],
              onChanged: (pregnancy) => _updateGestacao(i, pregnancy),
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
    required this.pregnancy,
    required this.onChanged,
  });

  final int index;
  final Pregnancy pregnancy;
  final ValueChanged<Pregnancy> onChanged;

  @override
  State<_GestacaoCard> createState() => _GestacaoCardState();
}

class _GestacaoCardState extends State<_GestacaoCard> {
  late final _perdaController = TextEditingController(
    text: widget.pregnancy.lossDescription ?? '',
  );
  late final _complicacaoController = TextEditingController(
    text: widget.pregnancy.complicationDescription ?? '',
  );
  late final _pesoBebeController = TextEditingController(
    text: widget.pregnancy.approximateBabyWeight ?? '',
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
    final pregnancy = widget.pregnancy;
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
            value: pregnancy.pregnancyLoss,
            onChanged: (value) => widget.onChanged(
              widget.pregnancy.copyWith(pregnancyLoss: value),
            ),
          ),
          if (pregnancy.pregnancyLoss == true) ...[
            const SizedBox(height: 8),
            AppTextField(
              controller: _perdaController,
              icon: Icons.description_outlined,
              hintText: 'Detalhe a perda gestacional',
              onChanged: (value) => widget.onChanged(
                widget.pregnancy.copyWith(lossDescription: value),
              ),
            ),
          ] else if (pregnancy.pregnancyLoss == false) ...[
            const SizedBox(height: 12),
            AppChipSelect<DeliveryMethod>(
              options: DeliveryMethod.values,
              labelBuilder: (option) => option.label,
              selected: pregnancy.deliveryMethod == null
                  ? {}
                  : {pregnancy.deliveryMethod!},
              onChanged: (selected) => widget.onChanged(
                widget.pregnancy.copyWith(
                  deliveryMethod: selected.isEmpty ? null : selected.first,
                ),
              ),
            ),
            if (pregnancy.deliveryMethod == DeliveryMethod.vaginal) ...[
              const SizedBox(height: 12),
              AppChipSelect<DeliveryComplication>(
                options: DeliveryComplication.values,
                labelBuilder: (option) => option.label,
                selected: pregnancy.deliveryComplication == null
                    ? {}
                    : {pregnancy.deliveryComplication!},
                onChanged: (selected) => widget.onChanged(
                  widget.pregnancy.copyWith(
                    deliveryComplication: selected.isEmpty
                        ? null
                        : selected.first,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppYesNoToggle(
                label: 'Uso de fórceps ou vácuo?',
                value: pregnancy.forcepsOrVacuumUse,
                onChanged: (value) => widget.onChanged(
                  widget.pregnancy.copyWith(forcepsOrVacuumUse: value),
                ),
              ),
            ],
            const SizedBox(height: 12),
            AppTextField(
              controller: _pesoBebeController,
              icon: Icons.monitor_weight_outlined,
              hintText: 'Peso aproximado do bebê',
              onChanged: (value) => widget.onChanged(
                widget.pregnancy.copyWith(approximateBabyWeight: value),
              ),
            ),
            const SizedBox(height: 12),
            AppYesNoToggle(
              label: 'Teve complicações?',
              value: pregnancy.hadComplications,
              onChanged: (value) => widget.onChanged(
                widget.pregnancy.copyWith(hadComplications: value),
              ),
            ),
            if (pregnancy.hadComplications == true) ...[
              const SizedBox(height: 8),
              AppTextField(
                controller: _complicacaoController,
                icon: Icons.description_outlined,
                hintText: 'Detalhe as complicações',
                onChanged: (value) => widget.onChanged(
                  widget.pregnancy.copyWith(complicationDescription: value),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
