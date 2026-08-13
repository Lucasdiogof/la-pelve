import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_strings.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/discharge_sheet.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_attachments_tab.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/bowel_function_info_section.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/gynecological_history_info_section.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/medical_history_info_section.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/obstetric_history_info_section.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/sexual_function_info_section.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/surgical_history_info_section.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/treatment_plan_info_section.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/urinary_function_info_section.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_bottom_action_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_confirm_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_segmented_tab_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

class PatientDetailPage extends StatelessWidget {
  const PatientDetailPage({required this.patient, super.key});

  final Patient patient;

  Future<void> _confirmDelete(BuildContext context, Patient current) async {
    final t = PatientsStrings(context.read<LocaleCubit>().state);
    final confirmed = await AppConfirmSheet.show(
      context,
      title: t.deletePatientTitle,
      description: t.deletePatientDescription(
        current.personalInfo.name.isEmpty
            ? t.patientFallbackTitle
            : current.personalInfo.name,
      ),
      confirmLabel: t.deleteLabel,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    showAppLoading();
    final result = await context.read<PatientsCubit>().deletePatient(
      current.id,
    );
    hideAppLoading();
    if (!context.mounted) return;
    switch (result) {
      case Success():
        context.pop();
      case Error(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  Future<void> _closeTreatment(BuildContext context, Patient current) async {
    final t = PatientsStrings(context.read<LocaleCubit>().state);
    final discharge = await showDischargeSheet(context);
    if (discharge == null || !context.mounted) return;
    await _saveDischarge(
      context,
      current,
      discharge,
      successMessage: t.treatmentClosedSuccess,
    );
  }

  Future<void> _reopenTreatment(BuildContext context, Patient current) async {
    final t = PatientsStrings(context.read<LocaleCubit>().state);
    final confirmed = await AppConfirmSheet.show(
      context,
      title: t.reopenTreatmentTitle,
      description: t.reopenTreatmentDescription,
      confirmLabel: t.reopenLabel,
    );
    if (!confirmed || !context.mounted) return;
    await _saveDischarge(
      context,
      current,
      null,
      successMessage: t.treatmentReopenedSuccess,
    );
  }

  Future<void> _saveDischarge(
    BuildContext context,
    Patient current,
    Discharge? discharge, {
    required String successMessage,
  }) async {
    showAppLoading();
    final result = await context.read<PatientsCubit>().updatePatient(
      current.copyWith(discharge: discharge),
    );
    hideAppLoading();
    if (!context.mounted) return;
    switch (result) {
      case Success():
        await AppInfoBottomSheet.showSuccess(
          context,
          description: successMessage,
        );
      case Error(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = PatientsStrings(context.watch<LocaleCubit>().state);
    final patients = context.watch<PatientsCubit>().state;
    final current = patients.firstWhere(
      (p) => p.id == patient.id,
      orElse: () => patient,
    );
    final dados = current.personalInfo;
    final isFeminino = dados.gender == Gender.female;

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          return Scaffold(
            backgroundColor: context.colors.background,
            body: Column(
              children: [
                ModernAppBar(
                  title: dados.name.isEmpty
                      ? t.patientFallbackTitle
                      : dados.name,
                  showBackButton: true,
                  trailing: AnimatedBuilder(
                    animation: tabController,
                    builder: (context, _) {
                      if (tabController.index != 0) {
                        return const SizedBox.shrink();
                      }
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: t.editPatientTooltip,
                            onPressed: () => context.push(
                              '/pacientes/${current.id}/editar',
                              extra: current,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: context.colors.error,
                            ),
                            tooltip: t.deletePatientTooltip,
                            onPressed: () => _confirmDelete(context, current),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                AppSegmentedTabBar(
                  tabs: [
                    Tab(text: t.tabInformation),
                    Tab(text: t.tabAttachments),
                  ],
                ),
                if (current.discharge != null)
                  DischargeBanner(
                    discharge: current.discharge!,
                    onReopen: () => _reopenTreatment(context, current),
                    language: t.language,
                  ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                        children: [
                          SectionTitle(t.sectionPersonalData),
                          InfoRow(
                            t.fieldSex,
                            PatientDetailFormat.enumValue(
                              dados.gender,
                              (v) => v.label(t.language),
                              language: t.language,
                            ),
                            language: t.language,
                          ),
                          InfoRow(
                            t.fieldAge,
                            PatientDetailFormat.intValue(
                              dados.age,
                              language: t.language,
                            ),
                            language: t.language,
                          ),
                          InfoRow(
                            t.fieldPhone,
                            PatientDetailFormat.text(
                              dados.phone,
                              language: t.language,
                            ),
                            language: t.language,
                          ),
                          InfoRow(
                            t.fieldOccupation,
                            PatientDetailFormat.text(
                              dados.occupation,
                              language: t.language,
                            ),
                            language: t.language,
                          ),
                          MedicalHistoryInfoSection(current.medicalHistory),
                          if (isFeminino)
                            GynecologicalHistoryInfoSection(
                              current.gynecologicalHistory,
                            ),
                          if (isFeminino)
                            ObstetricHistoryInfoSection(
                              current.obstetricHistory,
                            ),
                          SurgicalHistoryInfoSection(current.surgicalHistory),
                          UrinaryFunctionInfoSection(current.urinaryFunction),
                          SexualFunctionInfoSection(current.sexualFunction),
                          BowelFunctionInfoSection(current.bowelFunction),
                          TreatmentPlanInfoSection(current.treatmentPlan),
                          SectionTitle(t.sectionConsultationFee),
                          InfoRow(
                            t.fieldFirstConsultationFee,
                            PatientDetailFormat.money(
                              current.consultationFee,
                              language: t.language,
                            ),
                            language: t.language,
                          ),
                        ],
                      ),
                      PatientAttachmentsTab(patientId: current.id),
                    ],
                  ),
                ),
                AppBottomActionBar(
                  child: Column(
                    children: [
                      if (current.discharge == null) ...[
                        OutlinedButton.icon(
                          onPressed: () => _closeTreatment(context, current),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.colors.primaryButton,
                            side: BorderSide(
                              color: context.colors.primaryButton,
                            ),
                            minimumSize: const Size.fromHeight(56),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.event_busy_outlined),
                          label: Text(t.closeTreatmentButton),
                        ),
                        const SizedBox(height: 12),
                      ],
                      PrimaryButton(
                        label: t.viewEvolutionButton,
                        onPressed: () => context.push(
                          '/pacientes/${current.id}/evolucao',
                          extra: current,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
