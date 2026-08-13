import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_wizard_strings_b.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';

class TreatmentPlanStep extends StatefulWidget {
  const TreatmentPlanStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<TreatmentPlanStep> createState() => _TreatmentPlanStepState();
}

class _TreatmentPlanStepState extends State<TreatmentPlanStep> {
  late final _diagnosticoController = TextEditingController(
    text: widget.patient.treatmentPlan.physiotherapyDiagnosis ?? '',
  );
  late final _objetivoController = TextEditingController(
    text: widget.patient.treatmentPlan.treatmentGoal ?? '',
  );
  late final _condutaController = TextEditingController(
    text: widget.patient.treatmentPlan.treatmentApproach ?? '',
  );
  late final _frequenciaController = TextEditingController(
    text: widget.patient.treatmentPlan.suggestedFrequency ?? '',
  );

  @override
  void dispose() {
    _diagnosticoController.dispose();
    _objetivoController.dispose();
    _condutaController.dispose();
    _frequenciaController.dispose();
    super.dispose();
  }

  void _update(TreatmentPlan Function(TreatmentPlan) update) {
    widget.onChanged(
      widget.patient.copyWith(
        treatmentPlan: update(widget.patient.treatmentPlan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = PatientsWizardStringsB(context.watch<LocaleCubit>().state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _diagnosticoController,
          icon: Icons.fact_check_outlined,
          hintText: t.physiotherapyDiagnosisHint,
          maxLines: 4,
          onChanged: (value) =>
              _update((p) => p.copyWith(physiotherapyDiagnosis: value)),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _objetivoController,
          icon: Icons.flag_outlined,
          hintText: t.treatmentGoalHint,
          maxLines: 4,
          onChanged: (value) =>
              _update((p) => p.copyWith(treatmentGoal: value)),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _condutaController,
          icon: Icons.checklist_outlined,
          hintText: t.treatmentApproachHint,
          maxLines: 4,
          onChanged: (value) =>
              _update((p) => p.copyWith(treatmentApproach: value)),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _frequenciaController,
          icon: Icons.event_repeat_outlined,
          hintText: t.suggestedFrequencyHint,
          onChanged: (value) =>
              _update((p) => p.copyWith(suggestedFrequency: value)),
        ),
      ],
    );
  }
}
