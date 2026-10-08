import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/state/data_state.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_enums.dart';
import 'package:la_pelve/features/patients/l10n/patients_strings.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/shared/widgets/app_date_field.dart';
import 'package:la_pelve/shared/widgets/app_empty_state.dart';
import 'package:la_pelve/shared/widgets/app_list_row.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';
import 'package:la_pelve/shared/widgets/data_state_view.dart';
import 'package:la_pelve/shared/widgets/modern_app_bar.dart';

class PatientsListPage extends StatelessWidget {
  const PatientsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = PatientsStrings(context.watch<LocaleCubit>().state);
    void create() => context.push('/pacientes/novo');
    return BlocBuilder<PatientsCubit, DataState<List<Patient>>>(
      builder: (context, state) {
        // Regra existente, preservada: ativos primeiro e pacientes com alta
        // depois; dentro de cada grupo vale a ordem original do repositório.
        final patients = state.data ?? const <Patient>[];
        final active = patients.where((p) => p.discharge == null).toList();
        final discharged = patients.where((p) => p.discharge != null).toList();
        return Scaffold(
          backgroundColor: context.colors.background,
          body: Column(
            children: [
              ModernAppBar(
                title: t.listTitle,
                subtitle: state.hasData
                    ? _subtitle(
                        t,
                        total: patients.length,
                        discharged: discharged.length,
                      )
                    : t.listSubtitle,
                actionIcon: Icons.add,
                actionTooltip: t.newPatientButton,
                onAction: create,
              ),
              Expanded(
                child: DataStateView<List<Patient>>(
                  state: state,
                  onRetry: () => context.read<PatientsCubit>().refresh(),
                  builder: (context, patients) => RefreshIndicator(
                    onRefresh: () => refreshKeepingData(
                      context,
                      context.read<PatientsCubit>(),
                    ),
                    child: patients.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              AppEmptyState(
                                icon: Icons.people_outline,
                                title: t.emptyPatientsTitle,
                                message: t.emptyPatientsMessage,
                                actionLabel: t.newPatientButton,
                                onAction: create,
                              ),
                            ],
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.gutter,
                              AppSpacing.s8,
                              AppSpacing.gutter,
                              AppSpacing.s32,
                            ),
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              // Um painel por bloco (ativos / com alta), nunca
                              // um card por paciente. Só o bloco histórico leva
                              // overline; a lista principal não.
                              if (active.isNotEmpty) _PatientsPanel(active, t),
                              if (active.isNotEmpty && discharged.isNotEmpty)
                                const SizedBox(height: AppSpacing.s24),
                              if (discharged.isNotEmpty)
                                _PatientsPanel(
                                  discharged,
                                  t,
                                  title: t.dischargedSectionTitle,
                                ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Lista realmente vazia mantém o subtítulo fixo ("0 pacientes" não
  /// ajuda). Sem dados carregados o subtítulo também é o fixo.
  String _subtitle(
    PatientsStrings t, {
    required int total,
    required int discharged,
  }) {
    if (total == 0) return t.listSubtitle;
    if (discharged == 0) return t.patientCount(total);
    return t.patientCountWithDischarged(total, discharged);
  }
}

/// Um bloco de pacientes dentro de um painel (surface + borda, sem sombra),
/// com divisores entre as linhas e nenhum depois da última.
class _PatientsPanel extends StatelessWidget {
  const _PatientsPanel(this.patients, this.t, {this.title});

  final List<Patient> patients;
  final PatientsStrings t;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return AppSection(
      title: title,
      children: [
        for (var i = 0; i < patients.length; i++)
          _PatientRow(
            patient: patients[i],
            t: t,
            showDivider: i != patients.length - 1,
          ),
      ],
    );
  }
}

class _PatientRow extends StatelessWidget {
  const _PatientRow({
    required this.patient,
    required this.t,
    required this.showDivider,
  });

  final Patient patient;
  final PatientsStrings t;
  final bool showDivider;

  // Largura que o AppListRow reserva ao redor do texto (padding da linha,
  // leading 36 + 12 e trailing 12 + ícone 20). Usada só para decidir se
  // "motivo · data" cabe numa linha; o teste de varredura de larguras em
  // patients_list_page_test.dart pega qualquer divergência com o componente.
  static const double _rowPadding = AppSpacing.s16 * 2;
  static const double _leadingSlot = 36 + AppSpacing.s12;
  static const double _trailingSlot = AppSpacing.s12 + 20;

  /// Telefone (se houver) e, para paciente com alta, o motivo e a data.
  /// Se "motivo · data" cabe numa linha, fica numa linha; se não cabe, vira
  /// duas linhas ("motivo" / "data") SEM o separador, para o "·" nunca ficar
  /// pendurado no fim da linha. Sem linha vazia artificial.
  String? _subtitle(BuildContext context, double rowWidth) {
    final lines = <String>[
      if (patient.personalInfo.phone.isNotEmpty) patient.personalInfo.phone,
    ];
    final discharge = patient.discharge;
    if (discharge != null) {
      final reason = discharge.reason.label(t.language);
      final date = AppDateField.format(discharge.date);
      final oneLine = '$reason · $date';
      final painter = TextPainter(
        text: TextSpan(
          text: oneLine,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final available = rowWidth - _rowPadding - _leadingSlot - _trailingSlot;
      final fits = painter.width <= available - 1;
      painter.dispose();
      lines.add(fits ? oneLine : '$reason\n$date');
    }
    return lines.isEmpty ? null : lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final name = patient.personalInfo.name;
    return LayoutBuilder(
      builder: (context, constraints) => AppListRow(
        leading: AppInitialAvatar(name: name),
        title: name.isEmpty ? t.noNamePlaceholder : name,
        // Nome de paciente precisa ficar identificável: até 3 linhas.
        titleMaxLines: 3,
        subtitle: _subtitle(context, constraints.maxWidth),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/pacientes/${patient.id}', extra: patient),
        showDivider: showDivider,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      ),
    );
  }
}
