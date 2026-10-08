import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/core/utils/app_loading.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_enums.dart';
import 'package:la_pelve/features/patients/l10n/patients_strings.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/features/patients/presentation/widgets/discharge_sheet.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_attachments_tab.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_detail/bowel_function_info_section.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_detail/gynecological_history_info_section.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_detail/medical_history_info_section.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_detail/obstetric_history_info_section.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_detail/sexual_function_info_section.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_detail/surgical_history_info_section.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_detail/treatment_plan_info_section.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_detail/urinary_function_info_section.dart';
import 'package:la_pelve/shared/widgets/app_bottom_action_bar.dart';
import 'package:la_pelve/shared/widgets/app_confirm_sheet.dart';
import 'package:la_pelve/shared/widgets/app_date_field.dart';
import 'package:la_pelve/shared/widgets/app_info_bottom_sheet.dart';
import 'package:la_pelve/shared/widgets/app_list_row.dart';
import 'package:la_pelve/shared/widgets/app_segmented_tab_bar.dart';
import 'package:la_pelve/shared/widgets/modern_app_bar.dart';
import 'package:la_pelve/shared/widgets/primary_button.dart';

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

  /// Tratamento fica no fim da ficha (ação administrativa, sem destaque):
  /// sem alta, só a ação de encerrar; com alta, status/motivo/data/observação
  /// e a ação de reabrir.
  InfoSection _treatmentSection(
    BuildContext context,
    PatientsStrings t,
    Patient current,
  ) {
    const rowPadding = EdgeInsets.symmetric(horizontal: AppSpacing.s16);
    final discharge = current.discharge;
    if (discharge == null) {
      return InfoSection(
        title: t.sectionTreatmentStatus,
        children: [
          AppListRow(
            title: t.closeTreatmentButton,
            trailing: const Icon(Icons.chevron_right),
            padding: rowPadding,
            showDivider: false,
            onTap: () => _closeTreatment(context, current),
          ),
        ],
      );
    }
    return InfoSection(
      title: t.sectionTreatmentStatus,
      children: [
        InfoRow(
          t.fieldTreatmentStatus,
          t.dischargedSectionTitle,
          language: t.language,
        ),
        InfoRow(
          t.fieldDischargeReason,
          discharge.reason.label(t.language),
          language: t.language,
        ),
        InfoRow(
          t.dateHint,
          AppDateField.format(discharge.date),
          language: t.language,
        ),
        if ((discharge.finalNote ?? '').isNotEmpty)
          InfoRow(
            t.fieldFinalNote,
            discharge.finalNote!,
            language: t.language,
            vertical: true,
          ),
        AppListRow(
          title: t.reopenTreatmentTitle,
          trailing: const Icon(Icons.chevron_right),
          padding: rowPadding,
          showDivider: false,
          onTap: () => _reopenTreatment(context, current),
        ),
      ],
    );
  }

  Widget _informationTab(
    BuildContext context,
    PatientsStrings t,
    Patient current,
  ) {
    final dados = current.personalInfo;
    final showFemaleSpecificSections =
        dados.gender == Gender.female || dados.gender == Gender.other;
    final sections = <Widget>[
      InfoSection(
        title: t.sectionPersonalData,
        children: [
          if (dados.socialName.isNotEmpty)
            InfoRow(
              t.fieldSocialName,
              PatientDetailFormat.text(dados.socialName, language: t.language),
              language: t.language,
            ),
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
            PatientDetailFormat.intValue(dados.age, language: t.language),
            language: t.language,
          ),
          WhatsappReminderStatusRow(
            patientId: current.id,
            language: t.language,
          ),
          InfoRow(
            t.fieldOccupation,
            PatientDetailFormat.text(dados.occupation, language: t.language),
            language: t.language,
            vertical: true,
          ),
        ],
      ),
      MedicalHistoryInfoSection(current.medicalHistory),
      if (showFemaleSpecificSections)
        GynecologicalHistoryInfoSection(current.gynecologicalHistory),
      if (showFemaleSpecificSections)
        ObstetricHistoryInfoSection(current.obstetricHistory),
      SurgicalHistoryInfoSection(current.surgicalHistory),
      UrinaryFunctionInfoSection(current.urinaryFunction),
      SexualFunctionInfoSection(current.sexualFunction),
      BowelFunctionInfoSection(current.bowelFunction),
      TreatmentPlanInfoSection(current.treatmentPlan),
      InfoSection(
        title: t.sectionConsultationFee,
        children: [
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
      _treatmentSection(context, t, current),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.s16,
        AppSpacing.gutter,
        AppSpacing.s32,
      ),
      itemCount: sections.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s24),
      itemBuilder: (context, index) {
        if (index < sections.length) return sections[index];
        // Ação destrutiva por último e sem destaque: texto em danger.
        return Center(
          child: TextButton(
            style: TextButton.styleFrom(foregroundColor: context.colors.danger),
            onPressed: () => _confirmDelete(context, current),
            child: Text(t.deletePatientTitle),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = PatientsStrings(context.watch<LocaleCubit>().state);
    final patients =
        context.watch<PatientsCubit>().state.data ?? const <Patient>[];
    final current = patients.firstWhere(
      (p) => p.id == patient.id,
      orElse: () => patient,
    );

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
                  title: t.patientFallbackTitle,
                  showBackButton: true,
                  trailing: AnimatedBuilder(
                    animation: tabController,
                    builder: (context, _) {
                      if (tabController.index != 0) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: t.editPatientTooltip,
                        onPressed: () => context.push(
                          '/pacientes/${current.id}/editar',
                          extra: current,
                        ),
                      );
                    },
                  ),
                ),
                PatientHeader(patient: current, language: t.language),
                AppSegmentedTabBar(
                  tabs: [
                    Tab(text: t.tabInformation),
                    Tab(text: t.tabAttachments),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _informationTab(context, t, current),
                      PatientAttachmentsTab(patientId: current.id),
                    ],
                  ),
                ),
                // "Ver evolução" é a ação principal só da aba Informações; a
                // aba Anexos tem o próprio contexto e ações.
                AnimatedBuilder(
                  animation: tabController,
                  builder: (context, _) {
                    if (tabController.index != 0) {
                      return const SizedBox.shrink();
                    }
                    return AppBottomActionBar(
                      child: PrimaryButton(
                        label: t.viewEvolutionButton,
                        onPressed: () => context.push(
                          '/pacientes/${current.id}/evolucao',
                          extra: current,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
