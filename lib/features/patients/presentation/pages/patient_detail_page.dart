import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
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
          'Tem certeza que deseja excluir ${current.dadosPessoais.nome.isEmpty ? 'este paciente' : current.dadosPessoais.nome}? '
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
    final encerramento = await showEncerramentoSheet(context);
    if (encerramento == null || !context.mounted) return;
    await _saveEncerramento(context, current, encerramento);
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
    await _saveEncerramento(context, current, null);
  }

  Future<void> _saveEncerramento(
    BuildContext context,
    Patient current,
    Encerramento? encerramento,
  ) async {
    showAppLoading();
    final result = await context.read<PatientsCubit>().updatePatient(
      current.copyWith(encerramento: encerramento),
    );
    hideAppLoading();
    if (!context.mounted) return;
    if (result case Error(:final failure)) {
      await AppInfoBottomSheet.showError(context, description: failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patients = context.watch<PatientsCubit>().state;
    final current = patients.firstWhere(
      (p) => p.id == patient.id,
      orElse: () => patient,
    );
    final dados = current.dadosPessoais;
    final isFeminino = dados.sexo == Sexo.feminino;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          title: Text(dados.nome.isEmpty ? 'Paciente' : dados.nome),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar paciente',
              onPressed: () => context.push(
                '/pacientes/${current.id}/editar',
                extra: current,
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: context.colors.error),
              tooltip: 'Excluir paciente',
              onPressed: () => _confirmDelete(context, current),
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
            current.encerramento == null
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: OutlinedButton.icon(
                      onPressed: () => _encerrarTratamento(context, current),
                      icon: const Icon(Icons.event_busy_outlined),
                      label: const Text('Encerrar tratamento'),
                    ),
                  )
                : EncerramentoBanner(
                    encerramento: current.encerramento!,
                    onReabrir: () => _reabrirTratamento(context, current),
                  ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SectionTitle('Dados pessoais'),
                      InfoRow(
                        'Sexo',
                        PatientDetailFormat.enumValue(
                          dados.sexo,
                          (v) => v.label,
                        ),
                      ),
                      InfoRow(
                        'Idade',
                        PatientDetailFormat.intValue(dados.idade),
                      ),
                      InfoRow(
                        'Telefone',
                        PatientDetailFormat.text(dados.telefone),
                      ),
                      InfoRow(
                        'Profissão',
                        PatientDetailFormat.text(dados.profissao),
                      ),
                      AnamneseInfoSection(current.anamnese),
                      if (isFeminino)
                        HistoricoGinecologicoInfoSection(
                          current.historicoGinecologico,
                        ),
                      if (isFeminino)
                        HistoricoObstetricoInfoSection(
                          current.historicoObstetrico,
                        ),
                      HistoricoCirurgicoInfoSection(current.historicoCirurgico),
                      FuncaoUrinariaInfoSection(current.funcaoUrinaria),
                      FuncaoSexualInfoSection(current.funcaoSexual),
                      FuncaoIntestinalInfoSection(current.funcaoIntestinal),
                      PlanoTratamentoInfoSection(current.planoTratamento),
                      const SectionTitle('Valor da consulta'),
                      InfoRow(
                        'Valor da 1ª consulta',
                        PatientDetailFormat.money(current.valorConsulta),
                      ),
                    ],
                  ),
                  PatientAttachmentsTab(patientId: current.id),
                ],
              ),
            ),
            AppBottomActionBar(
              child: PrimaryButton(
                label: 'Ver evolução',
                onPressed: () => context.push(
                  '/pacientes/${current.id}/evolucao',
                  extra: current,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
