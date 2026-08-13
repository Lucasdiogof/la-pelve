import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/evolution_entry.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/patient_repository.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_strings.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/evolution_list_cubit.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_empty_state.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';

class EvolutionListPage extends StatelessWidget {
  const EvolutionListPage({required this.patient, super.key});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EvolutionListCubit(sl<PatientRepository>(), patient.id),
      child: Builder(
        builder: (context) {
          final cubit = context.read<EvolutionListCubit>();
          final t = PatientsStrings(context.watch<LocaleCubit>().state);
          return Scaffold(
            backgroundColor: context.colors.background,
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'evolution-fab',
              onPressed: () async {
                await context.push('/pacientes/${patient.id}/evolucao/novo');
                if (context.mounted) await cubit.reload();
              },
              icon: const Icon(Icons.add),
              label: Text(t.newEvolutionButton),
            ),
            body: Column(
              children: [
                ModernAppBar(
                  title: t.evolutionPageTitle,
                  subtitle: t.evolutionPageSubtitle,
                  showBackButton: true,
                ),
                Expanded(
                  child:
                      BlocBuilder<
                        EvolutionListCubit,
                        Result<List<EvolutionEntry>>?
                      >(
                        builder: (context, result) {
                          final entries = switch (result) {
                            Success(:final data) => data,
                            _ => const <EvolutionEntry>[],
                          };
                          if (result is Error<List<EvolutionEntry>>) {
                            return Center(
                              child: Text(
                                result.failure.message,
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            );
                          }
                          if (entries.isEmpty) {
                            return AppEmptyState(
                              icon: Icons.timeline_outlined,
                              title: t.evolutionEmptyTitle,
                              message: t.evolutionEmptyMessage,
                            );
                          }
                          final sorted = [...entries]
                            ..sort((a, b) => b.date.compareTo(a.date));
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                            itemCount: sorted.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final entry = sorted[index];
                              return Material(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    await context.push(
                                      '/pacientes/${patient.id}/evolucao/${entry.id}/editar',
                                      extra: entry,
                                    );
                                    if (context.mounted) await cubit.reload();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppDateField.format(entry.date),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: context.colors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(entry.description),
                                        if (entry.updatedAt != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            t.editedOn(
                                              AppDateField.format(
                                                entry.updatedAt!,
                                              ),
                                            ),
                                            style: TextStyle(
                                              color:
                                                  context.colors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
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
