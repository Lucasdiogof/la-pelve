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
          onChanged: (value) =>
              _update((h) => h.copyWith(ageAtMenarche: int.tryParse(value))),
        ),
        const SizedBox(height: 16),
        AppChipSelect<MenstrualFlow>(
          options: MenstrualFlow.values,
          labelBuilder: (option) => option.label,
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
          label: 'Presença de cólica',
          value: historico.crampsScore0to10,
          onChanged: (value) =>
              _update((h) => h.copyWith(crampsScore0to10: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Menstrua atualmente?',
          value: historico.currentlyMenstruating,
          onChanged: (value) =>
              _update((h) => h.copyWith(currentlyMenstruating: value)),
        ),
        if (historico.currentlyMenstruating == false) ...[
          const SizedBox(height: 8),
          AppYesNoToggle(
            label: 'Está na menopausa?',
            value: historico.isInMenopause,
            onChanged: (value) =>
                _update((h) => h.copyWith(isInMenopause: value)),
          ),
          const SizedBox(height: 8),
          AppDateField(
            hintText: 'Data aproximada da última menstruação',
            value: historico.approximateLastMenstruationDate,
            onChanged: (value) => _update(
              (h) => h.copyWith(approximateLastMenstruationDate: value),
            ),
          ),
        ],
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Ciclo regular?',
          value: historico.regularCycle,
          onChanged: (value) => _update((h) => h.copyWith(regularCycle: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Menopausa?',
          value: historico.menopause,
          onChanged: (value) => _update((h) => h.copyWith(menopause: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Faz reposição hormonal?',
          value: historico.hormoneReplacementTherapy,
          onChanged: (value) =>
              _update((h) => h.copyWith(hormoneReplacementTherapy: value)),
        ),
        if (historico.hormoneReplacementTherapy == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _reposicaoHormonalController,
            icon: Icons.medication_outlined,
            hintText: 'Detalhe a reposição hormonal',
            onChanged: (value) => _update(
              (h) => h.copyWith(hormoneReplacementTherapyDescription: value),
            ),
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
        AppChipSelect<ContraceptiveMethod>(
          options: ContraceptiveMethod.values,
          labelBuilder: (option) => option.label,
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
          value: historico.pelvicPainOutsidePeriod,
          onChanged: (value) =>
              _update((h) => h.copyWith(pelvicPainOutsidePeriod: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Sangramento fora do período menstrual?',
          value: historico.bleedingOutsidePeriod,
          onChanged: (value) =>
              _update((h) => h.copyWith(bleedingOutsidePeriod: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Endometriose?',
          value: historico.endometriosis,
          onChanged: (value) =>
              _update((h) => h.copyWith(endometriosis: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Síndrome dos ovários policísticos?',
          value: historico.polycysticOvarySyndrome,
          onChanged: (value) =>
              _update((h) => h.copyWith(polycysticOvarySyndrome: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Infecções urinárias recorrentes?',
          value: historico.recurrentUrinaryInfections,
          onChanged: (value) =>
              _update((h) => h.copyWith(recurrentUrinaryInfections: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: 'Infecções vaginais recorrentes?',
          value: historico.recurrentVaginalInfections,
          onChanged: (value) =>
              _update((h) => h.copyWith(recurrentVaginalInfections: value)),
        ),
      ],
    );
  }
}
