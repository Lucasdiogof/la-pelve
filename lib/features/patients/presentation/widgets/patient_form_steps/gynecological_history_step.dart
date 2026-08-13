import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_wizard_strings_a.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_chip_select.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_scale_field.dart';
import 'package:fisioterapia_pelvica/shared/utils/validators.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_yes_no_toggle.dart';

class GynecologicalHistoryStep extends StatefulWidget {
  const GynecologicalHistoryStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<GynecologicalHistoryStep> createState() =>
      _GynecologicalHistoryStepState();
}

class _GynecologicalHistoryStepState extends State<GynecologicalHistoryStep> {
  late final _idadeMenstruacaoController = TextEditingController(
    text: widget.patient.gynecologicalHistory.ageAtMenarche?.toString() ?? '',
  );
  late final _reposicaoHormonalController = TextEditingController(
    text:
        widget
            .patient
            .gynecologicalHistory
            .hormoneReplacementTherapyDescription ??
        '',
  );

  @override
  void dispose() {
    _idadeMenstruacaoController.dispose();
    _reposicaoHormonalController.dispose();
    super.dispose();
  }

  void _update(GynecologicalHistory Function(GynecologicalHistory) update) {
    widget.onChanged(
      widget.patient.copyWith(
        gynecologicalHistory: update(widget.patient.gynecologicalHistory),
      ),
    );
  }

  String? get _idadeMenstruacaoError =>
      ageErrorText(_idadeMenstruacaoController.text);

  @override
  Widget build(BuildContext context) {
    final historico = widget.patient.gynecologicalHistory;
    final t = PatientsWizardStringsA(context.watch<LocaleCubit>().state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _idadeMenstruacaoController,
          icon: Icons.calendar_today_outlined,
          hintText: t.ageAtMenarcheHint,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          errorText: _idadeMenstruacaoError,
          onChanged: (value) =>
              _update((h) => h.copyWith(ageAtMenarche: int.tryParse(value))),
        ),
        const SizedBox(height: 16),
        AppChipSelect<MenstrualFlow>(
          options: MenstrualFlow.values,
          labelBuilder: (option) => option.label(t.language),
          selected: historico.menstrualFlow == null
              ? {}
              : {historico.menstrualFlow!},
          onChanged: (selected) => _update(
            (h) => h.copyWith(
              menstrualFlow: selected.isEmpty ? null : selected.first,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppScaleField(
          label: t.crampsLabel,
          value: historico.crampsScore0to10,
          onChanged: (value) =>
              _update((h) => h.copyWith(crampsScore0to10: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.currentlyMenstruatingLabel,
          value: historico.currentlyMenstruating,
          onChanged: (value) =>
              _update((h) => h.copyWith(currentlyMenstruating: value)),
        ),
        if (historico.currentlyMenstruating == false) ...[
          const SizedBox(height: 8),
          AppYesNoToggle(
            label: t.isInMenopauseLabel,
            value: historico.isInMenopause,
            onChanged: (value) =>
                _update((h) => h.copyWith(isInMenopause: value)),
          ),
          const SizedBox(height: 8),
          AppDateField(
            hintText: t.approximateLastMenstruationDateHint,
            value: historico.approximateLastMenstruationDate,
            onChanged: (value) => _update(
              (h) => h.copyWith(approximateLastMenstruationDate: value),
            ),
          ),
        ],
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.regularCycleLabel,
          value: historico.regularCycle,
          onChanged: (value) => _update((h) => h.copyWith(regularCycle: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.menopauseLabel,
          value: historico.menopause,
          onChanged: (value) => _update((h) => h.copyWith(menopause: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.hormoneReplacementTherapyLabel,
          value: historico.hormoneReplacementTherapy,
          onChanged: (value) =>
              _update((h) => h.copyWith(hormoneReplacementTherapy: value)),
        ),
        if (historico.hormoneReplacementTherapy == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _reposicaoHormonalController,
            icon: Icons.medication_outlined,
            hintText: t.hormoneReplacementTherapyDetailHint,
            onChanged: (value) => _update(
              (h) => h.copyWith(hormoneReplacementTherapyDescription: value),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          t.contraceptiveMethodSectionHeader,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        AppChipSelect<ContraceptiveMethod>(
          options: ContraceptiveMethod.values,
          labelBuilder: (option) => option.label(t.language),
          selected: historico.contraceptiveMethod == null
              ? {}
              : {historico.contraceptiveMethod!},
          onChanged: (selected) => _update(
            (h) => h.copyWith(
              contraceptiveMethod: selected.isEmpty ? null : selected.first,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          t.otherSymptomsSectionHeader,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.pelvicPainOutsidePeriodLabel,
          value: historico.pelvicPainOutsidePeriod,
          onChanged: (value) =>
              _update((h) => h.copyWith(pelvicPainOutsidePeriod: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.bleedingOutsidePeriodLabel,
          value: historico.bleedingOutsidePeriod,
          onChanged: (value) =>
              _update((h) => h.copyWith(bleedingOutsidePeriod: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.endometriosisLabel,
          value: historico.endometriosis,
          onChanged: (value) =>
              _update((h) => h.copyWith(endometriosis: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.polycysticOvarySyndromeLabel,
          value: historico.polycysticOvarySyndrome,
          onChanged: (value) =>
              _update((h) => h.copyWith(polycysticOvarySyndrome: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.recurrentUrinaryInfectionsLabel,
          value: historico.recurrentUrinaryInfections,
          onChanged: (value) =>
              _update((h) => h.copyWith(recurrentUrinaryInfections: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.recurrentVaginalInfectionsLabel,
          value: historico.recurrentVaginalInfections,
          onChanged: (value) =>
              _update((h) => h.copyWith(recurrentVaginalInfections: value)),
        ),
      ],
    );
  }
}
