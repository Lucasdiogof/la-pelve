import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/pregnancy.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_wizard_strings_a.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_yes_no_toggle.dart';

class ObstetricHistoryStep extends StatefulWidget {
  const ObstetricHistoryStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<ObstetricHistoryStep> createState() => _ObstetricHistoryStepState();
}

class _ObstetricHistoryStepState extends State<ObstetricHistoryStep> {
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

  void _setPregnancyCount(String value) {
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

  void _updatePregnancy(int index, Pregnancy pregnancy) {
    _update((h) {
      final pregnancies = List<Pregnancy>.from(h.pregnancies);
      pregnancies[index] = pregnancy;
      return h.copyWith(pregnancies: pregnancies);
    });
  }

  @override
  Widget build(BuildContext context) {
    final historico = widget.patient.obstetricHistory;
    final t = PatientsWizardStringsA(context.watch<LocaleCubit>().state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppYesNoToggle(
          label: t.currentlyPregnantLabel,
          value: historico.currentlyPregnant,
          onChanged: (value) =>
              _update((h) => h.copyWith(currentlyPregnant: value)),
        ),
        if (historico.currentlyPregnant == true) ...[
          const SizedBox(height: 16),
          Text(
            t.desiredDeliveryMethodSectionHeader,
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
            labelBuilder: (option) => option.label(t.language),
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
            hintText: t.gestationWeeksHint,
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
            hintText: t.estimatedDeliveryDateHint,
            value: historico.estimatedDeliveryDate,
            onChanged: (value) =>
                _update((h) => h.copyWith(estimatedDeliveryDate: value)),
          ),
          const SizedBox(height: 12),
          AppYesNoToggle(
            label: t.highRiskPregnancyLabel,
            value: historico.highRiskPregnancy,
            onChanged: (value) =>
                _update((h) => h.copyWith(highRiskPregnancy: value)),
          ),
          if (historico.highRiskPregnancy == true) ...[
            const SizedBox(height: 8),
            AppTextField(
              controller: _gestacaoRiscoController,
              icon: Icons.description_outlined,
              hintText: t.highRiskPregnancyDetailHint,
              onChanged: (value) => _update(
                (h) => h.copyWith(highRiskPregnancyDescription: value),
              ),
            ),
          ],
        ],
        const SizedBox(height: 20),
        AppYesNoToggle(
          label: t.hasBeenPregnantLabel,
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
            hintText: t.pregnancyCountHint,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: _setPregnancyCount,
          ),
          for (var i = 0; i < historico.pregnancies.length; i++) ...[
            const SizedBox(height: 20),
            _PregnancyCard(
              index: i,
              pregnancy: historico.pregnancies[i],
              onChanged: (pregnancy) => _updatePregnancy(i, pregnancy),
            ),
          ],
        ],
      ],
    );
  }
}

class _PregnancyCard extends StatefulWidget {
  const _PregnancyCard({
    required this.index,
    required this.pregnancy,
    required this.onChanged,
  });

  final int index;
  final Pregnancy pregnancy;
  final ValueChanged<Pregnancy> onChanged;

  @override
  State<_PregnancyCard> createState() => _PregnancyCardState();
}

class _PregnancyCardState extends State<_PregnancyCard> {
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
    final t = PatientsWizardStringsA(context.watch<LocaleCubit>().state);
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
            t.pregnancyCardTitle(widget.index + 1),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 12),
          AppYesNoToggle(
            label: t.pregnancyLossLabel,
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
              hintText: t.pregnancyLossDetailHint,
              onChanged: (value) => widget.onChanged(
                widget.pregnancy.copyWith(lossDescription: value),
              ),
            ),
          ] else if (pregnancy.pregnancyLoss == false) ...[
            const SizedBox(height: 12),
            AppChipSelect<DeliveryMethod>(
              options: DeliveryMethod.values,
              labelBuilder: (option) => option.label(t.language),
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
                labelBuilder: (option) => option.label(t.language),
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
                label: t.forcepsOrVacuumUseLabel,
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
              hintText: t.approximateBabyWeightHint,
              onChanged: (value) => widget.onChanged(
                widget.pregnancy.copyWith(approximateBabyWeight: value),
              ),
            ),
            const SizedBox(height: 12),
            AppYesNoToggle(
              label: t.hadComplicationsLabel,
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
                hintText: t.complicationsDetailHint,
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
