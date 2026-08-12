import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/evolution_entry.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/patient_repository.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_empty_state.dart';

class EvolutionListPage extends StatefulWidget {
  const EvolutionListPage({required this.patient, super.key});

  final Patient patient;

  @override
  State<EvolutionListPage> createState() => _EvolutionListPageState();
}

class _EvolutionListPageState extends State<EvolutionListPage> {
  final _repository = sl<PatientRepository>();
  late Future<Result<List<EvolutionEntry>>> _future = _repository.getEvolutions(
    widget.patient.id,
  );

  Future<void> _reload() async {
    setState(() => _future = _repository.getEvolutions(widget.patient.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: const Text('Evolução')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'evolution-fab',
        onPressed: () async {
          await context.push('/pacientes/${widget.patient.id}/evolucao/novo');
          if (mounted) await _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova evolução'),
      ),
      body: FutureBuilder<Result<List<EvolutionEntry>>>(
        future: _future,
        builder: (context, snapshot) {
          final result = snapshot.data;
          final entries = switch (result) {
            Success(:final data) => data,
            _ => const <EvolutionEntry>[],
          };
          if (result is Error<List<EvolutionEntry>>) {
            return Center(
              child: Text(
                result.failure.message,
                style: TextStyle(color: context.colors.textSecondary),
              ),
            );
          }
          if (entries.isEmpty) {
            return const AppEmptyState(
              icon: Icons.timeline_outlined,
              title: 'Nenhuma evolução registrada',
              message: 'Toque em "Nova evolução" para começar.',
            );
          }
          final sorted = [...entries]..sort((a, b) => b.data.compareTo(a.data));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = sorted[index];
              return Material(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await context.push(
                      '/pacientes/${widget.patient.id}/evolucao/${entry.id}/editar',
                      extra: entry,
                    );
                    if (mounted) await _reload();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppDateField.format(entry.data),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: context.colors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(entry.descricao),
                        if (entry.updatedAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Editado em ${AppDateField.format(entry.updatedAt!)}',
                            style: TextStyle(
                              color: context.colors.textSecondary,
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
    );
  }
}
