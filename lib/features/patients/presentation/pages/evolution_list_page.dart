import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/state/data_state.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/patients/domain/entities/evolution_entry.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_repository.dart';
import 'package:la_pelve/features/patients/l10n/patients_strings.dart';
import 'package:la_pelve/features/patients/presentation/cubit/evolution_list_cubit.dart';
import 'package:la_pelve/features/patients/presentation/widgets/evolution/evolution_timeline.dart';
import 'package:la_pelve/shared/widgets/app_confirm_sheet.dart';
import 'package:la_pelve/shared/widgets/app_empty_state.dart';
import 'package:la_pelve/shared/widgets/app_info_bottom_sheet.dart';
import 'package:la_pelve/shared/widgets/app_sheet.dart';
import 'package:la_pelve/shared/widgets/data_state_view.dart';
import 'package:la_pelve/shared/widgets/modern_app_bar.dart';

class EvolutionListPage extends StatelessWidget {
  const EvolutionListPage({required this.patient, super.key});

  final Patient patient;

  /// Menu pequeno do item: a única ação é excluir (em danger, só aqui).
  Future<void> _showActions(
    BuildContext context,
    EvolutionListCubit cubit,
    PatientsStrings t,
    String entryId,
  ) async {
    final delete = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AppSheet(
        children: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: sheetContext.colors.danger,
            ),
            onPressed: () => Navigator.of(sheetContext).pop(true),
            child: Text(t.deleteEvolutionTitle),
          ),
        ],
      ),
    );
    if (delete != true || !context.mounted) return;
    await _delete(context, cubit, t, entryId);
  }

  Future<void> _delete(
    BuildContext context,
    EvolutionListCubit cubit,
    PatientsStrings t,
    String entryId,
  ) async {
    final confirmed = await AppConfirmSheet.show(
      context,
      title: t.deleteEvolutionTitle,
      description: t.deleteEvolutionDescription,
      confirmLabel: t.deleteLabel,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final result = await cubit.delete(entryId);
    if (!context.mounted) return;
    if (result case Error(:final failure)) {
      await AppInfoBottomSheet.showError(context, description: failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EvolutionListCubit(sl<PatientRepository>(), patient.id),
      child: Builder(
        builder: (context) {
          final cubit = context.read<EvolutionListCubit>();
          final t = PatientsStrings(context.watch<LocaleCubit>().state);
          Future<void> create() async {
            await context.push('/pacientes/${patient.id}/evolucao/novo');
            if (context.mounted) await cubit.refresh();
          }

          final name = patient.personalInfo.name;
          return Scaffold(
            backgroundColor: context.colors.background,
            body: Column(
              children: [
                ModernAppBar(
                  title: t.evolutionsPageTitle,
                  subtitle: name.isEmpty ? null : name,
                  showBackButton: true,
                  actionIcon: Icons.add,
                  actionTooltip: t.newEvolutionButton,
                  onAction: create,
                ),
                Expanded(
                  child:
                      BlocBuilder<
                        EvolutionListCubit,
                        DataState<List<EvolutionEntry>>
                      >(
                        // Primeira carga: loading (não "vazio"); falha sem
                        // dados: erro + tentar novamente; recargas mantêm a
                        // lista atual na tela.
                        builder: (context, state) =>
                            DataStateView<List<EvolutionEntry>>(
                              state: state,
                              onRetry: cubit.refresh,
                              builder: (context, entries) {
                                if (entries.isEmpty) {
                                  return AppEmptyState(
                                    icon: Icons.timeline_outlined,
                                    title: t.evolutionEmptyTitle,
                                    message: t.evolutionEmptyMessage,
                                    actionLabel: t.newEvolutionButton,
                                    onAction: create,
                                  );
                                }
                                final sorted = [...entries]
                                  ..sort((a, b) => b.date.compareTo(a.date));
                                return ListView(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.gutter,
                                    AppSpacing.s8,
                                    AppSpacing.gutter,
                                    AppSpacing.s32,
                                  ),
                                  children: [
                                    EvolutionTimeline(
                                      entries: sorted,
                                      t: t,
                                      onEdit: (entry) async {
                                        await context.push(
                                          '/pacientes/${patient.id}/evolucao/${entry.id}/editar',
                                          extra: entry,
                                        );
                                        if (context.mounted) {
                                          await cubit.refresh();
                                        }
                                      },
                                      onMore: (entry) => _showActions(
                                        context,
                                        cubit,
                                        t,
                                        entry.id,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
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
