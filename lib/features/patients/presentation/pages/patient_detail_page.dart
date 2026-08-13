import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/encerramento_sheet.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_attachments_tab.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/anamnese_info_section.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/funcao_intestinal_info_section.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/funcao_sexual_info_section.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/funcao_urinaria_info_section.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/historico_cirurgico_info_section.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/historico_ginecologico_info_section.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/historico_obstetrico_info_section.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_detail/plano_tratamento_info_section.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_bottom_action_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_confirm_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

class PatientDetailPage extends StatelessWidget {
  const PatientDetailPage({required this.patient, super.key});

  final Patient patient;

  Future<void> _confirmDelete(BuildContext context, Patient current) async {
    final confirmed = await AppConfirmSheet.show(
      context,
      title: 'Excluir paciente',
      description:
          'Tem certeza que deseja excluir ${current.personalInfo.name.isEmpty ? 'este paciente' : current.personalInfo.name}? '
          'Essa ação não pode ser desfeita e também apaga as evoluções registradas.',
      confirmLabel: 'Excluir',
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

  Future<void> _encerrarTratamento(
    BuildContext context,
    Patient current,
  ) async {
    final discharge = await showEncerramentoSheet(context);
    if (discharge == null || !context.mounted) return;
    await _saveEncerramento(
      context,
      current,
      discharge,
      successMessage: 'Tratamento encerrado com sucesso.',
    );
  }

  Future<void> _reabrirTratamento(BuildContext context, Patient current) async {
    final confirmed = await AppConfirmSheet.show(
      context,
      title: 'Reabrir tratamento',
      description:
          'Isso remove o encerramento atual e volta o tratamento para em andamento.',
      confirmLabel: 'Reabrir',
    );
    if (!confirmed || !context.mounted) return;
    await _saveEncerramento(
      context,
      current,
      null,
      successMessage: 'Tratamento reaberto com sucesso.',
    );
  }

  Future<void> _saveEncerramento(
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
            appBar: AppBar(
              title: Text(dados.name.isEmpty ? 'Paciente' : dados.name),
              actions: [
                AnimatedBuilder(
                  animation: tabController,
                  builder: (context, _) {
                    if (tabController.index != 0) {
                      return const SizedBox.shrink();
                    }
                    return Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar paciente',
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
                          tooltip: 'Excluir paciente',
                          onPressed: () => _confirmDelete(context, current),
                        ),
                      ],
                    );
                  },
                ),
              ],
              bottom: TabBar(
                labelColor: context.colors.textPrimary,
                unselectedLabelColor: context.colors.textSecondary,
                indicatorColor: context.colors.primaryButton,
                tabs: const [
                  Tab(text: 'Informações'),
                  Tab(text: 'Anexos'),
                ],
              ),
            ),
            body: Column(
              children: [
                if (current.discharge != null)
                  EncerramentoBanner(
                    discharge: current.discharge!,
                    onReabrir: () => _reabrirTratamento(context, current),
                    language: AppLanguage.portuguese,
                  ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                        children: [
                          const SectionTitle('Dados pessoais'),
                          InfoRow(
                            'Sexo',
                            PatientDetailFormat.enumValue(
                              dados.gender,
                              (v) => v.label,
                            ),
                          ),
                          InfoRow(
                            'Idade',
                            PatientDetailFormat.intValue(dados.age),
                          ),
                          InfoRow(
                            'Telefone',
                            PatientDetailFormat.text(dados.phone),
                          ),
                          InfoRow(
                            'Profissão',
                            PatientDetailFormat.text(dados.occupation),
                          ),
                          AnamneseInfoSection(current.medicalHistory),
                          if (isFeminino)
                            HistoricoGinecologicoInfoSection(
                              current.gynecologicalHistory,
                            ),
                          if (isFeminino)
                            HistoricoObstetricoInfoSection(
                              current.obstetricHistory,
                            ),
                          HistoricoCirurgicoInfoSection(
                            current.surgicalHistory,
                          ),
                          FuncaoUrinariaInfoSection(current.urinaryFunction),
                          FuncaoSexualInfoSection(current.sexualFunction),
                          FuncaoIntestinalInfoSection(current.bowelFunction),
                          PlanoTratamentoInfoSection(current.treatmentPlan),
                          const SectionTitle('Valor da consulta'),
                          InfoRow(
                            'Valor da 1ª consulta',
                            PatientDetailFormat.money(current.consultationFee),
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
                          onPressed: () =>
                              _encerrarTratamento(context, current),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.colors.primaryButton,
                            side: BorderSide(
                              color: context.colors.primaryButton,
                            ),
                            minimumSize: const Size.fromHeight(56),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.event_busy_outlined),
                          label: const Text('Encerrar tratamento'),
                        ),
                        const SizedBox(height: 12),
                      ],
                      PrimaryButton(
                        label: 'Ver evolução',
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
