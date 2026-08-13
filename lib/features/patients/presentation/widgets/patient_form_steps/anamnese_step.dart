import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_wizard_strings_a.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_yes_no_toggle.dart';

class AnamneseStep extends StatefulWidget {
  const AnamneseStep({
    required this.patient,
    required this.onChanged,
    super.key,
  });

  final Patient patient;
  final ValueChanged<Patient> onChanged;

  @override
  State<AnamneseStep> createState() => _AnamneseStepState();
}

class _AnamneseStepState extends State<AnamneseStep> {
  late final _queixaController = TextEditingController(
    text: widget.patient.medicalHistory.chiefComplaint,
  );
  late final _diagnosticoController = TextEditingController(
    text: widget.patient.medicalHistory.medicalDiagnosis ?? '',
  );
  late final _inicioSintomasController = TextEditingController(
    text: widget.patient.medicalHistory.symptomsOnset,
  );
  late final _tratamentoController = TextEditingController(
    text: widget.patient.medicalHistory.treatmentDescription ?? '',
  );
  late final _doencasController = TextEditingController(
    text: widget.patient.medicalHistory.chronicDiseasesDescription ?? '',
  );
  late final _medicamentosController = TextEditingController(
    text: widget.patient.medicalHistory.medicationsDescription ?? '',
  );
  late final _examesImagemController = TextEditingController(
    text: widget.patient.medicalHistory.imagingExams ?? '',
  );

  @override
  void dispose() {
    _queixaController.dispose();
    _diagnosticoController.dispose();
    _inicioSintomasController.dispose();
    _tratamentoController.dispose();
    _doencasController.dispose();
    _medicamentosController.dispose();
    _examesImagemController.dispose();
    super.dispose();
  }

  void _update(MedicalHistory Function(MedicalHistory) update) {
    widget.onChanged(
      widget.patient.copyWith(
        medicalHistory: update(widget.patient.medicalHistory),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicalHistory = widget.patient.medicalHistory;
    final t = PatientsWizardStringsA(context.watch<LocaleCubit>().state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _queixaController,
          icon: Icons.chat_bubble_outline,
          hintText: t.chiefComplaintHint,
          maxLines: 3,
          onChanged: (value) =>
              _update((a) => a.copyWith(chiefComplaint: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.hasMedicalDiagnosisLabel,
          value: medicalHistory.hasMedicalDiagnosis,
          onChanged: (value) =>
              _update((a) => a.copyWith(hasMedicalDiagnosis: value)),
        ),
        if (medicalHistory.hasMedicalDiagnosis == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _diagnosticoController,
            icon: Icons.description_outlined,
            hintText: t.medicalDiagnosisDetailHint,
            onChanged: (value) =>
                _update((a) => a.copyWith(medicalDiagnosis: value)),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          t.presentIllnessHistorySectionHeader,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _inicioSintomasController,
          icon: Icons.event_outlined,
          hintText: t.symptomsOnsetHint,
          maxLines: 3,
          onChanged: (value) =>
              _update((a) => a.copyWith(symptomsOnset: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.hadPreviousTreatmentLabel,
          value: medicalHistory.hadPreviousTreatment,
          onChanged: (value) =>
              _update((a) => a.copyWith(hadPreviousTreatment: value)),
        ),
        if (medicalHistory.hadPreviousTreatment == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _tratamentoController,
            icon: Icons.healing_outlined,
            hintText: t.previousTreatmentDetailHint,
            onChanged: (value) =>
                _update((a) => a.copyWith(treatmentDescription: value)),
          ),
        ],
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.hasChronicDiseasesLabel,
          value: medicalHistory.hasChronicDiseases,
          onChanged: (value) =>
              _update((a) => a.copyWith(hasChronicDiseases: value)),
        ),
        if (medicalHistory.hasChronicDiseases == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _doencasController,
            icon: Icons.local_hospital_outlined,
            hintText: t.chronicDiseasesDetailHint,
            onChanged: (value) =>
                _update((a) => a.copyWith(chronicDiseasesDescription: value)),
          ),
        ],
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.takesContinuousMedicationLabel,
          value: medicalHistory.takesContinuousMedication,
          onChanged: (value) =>
              _update((a) => a.copyWith(takesContinuousMedication: value)),
        ),
        if (medicalHistory.takesContinuousMedication == true) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _medicamentosController,
            icon: Icons.medication_outlined,
            hintText: t.continuousMedicationDetailHint,
            onChanged: (value) =>
                _update((a) => a.copyWith(medicationsDescription: value)),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          t.habitsSectionHeader,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.smokingLabel,
          value: medicalHistory.smoking,
          onChanged: (value) => _update((a) => a.copyWith(smoking: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.consumesAlcoholLabel,
          value: medicalHistory.consumesAlcohol,
          onChanged: (value) =>
              _update((a) => a.copyWith(consumesAlcohol: value)),
        ),
        const SizedBox(height: 12),
        AppYesNoToggle(
          label: t.practicesPhysicalActivityLabel,
          value: medicalHistory.practicesPhysicalActivity,
          onChanged: (value) =>
              _update((a) => a.copyWith(practicesPhysicalActivity: value)),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _examesImagemController,
          icon: Icons.image_outlined,
          hintText: t.imagingExamsHint,
          maxLines: 3,
          onChanged: (value) => _update((a) => a.copyWith(imagingExams: value)),
        ),
      ],
    );
  }
}
