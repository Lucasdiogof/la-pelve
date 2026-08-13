import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_empty_state.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';

class PatientsListPage extends StatelessWidget {
  const PatientsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'patients-fab',
        onPressed: () => context.push('/pacientes/novo'),
        icon: const Icon(Icons.add),
        label: const Text('Novo paciente'),
      ),
      body: Column(
        children: [
          const ModernAppBar(
            title: 'Pacientes',
            subtitle: 'Gerencie seus pacientes',
          ),
          Expanded(
            child: BlocBuilder<PatientsCubit, List<Patient>>(
              builder: (context, patients) {
                if (patients.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.people_outline,
                    title: 'Nenhum paciente cadastrado',
                    message: 'Toque em "Novo paciente" para começar.',
                  );
                }
                final sorted = [
                  ...patients.where((p) => p.discharge == null),
                  ...patients.where((p) => p.discharge != null),
                ];
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final patient = sorted[index];
                    return _PatientTile(patient: patient);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/pacientes/${patient.id}', extra: patient),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: context.colors.primary.withValues(alpha: 0.15),
                child: Text(
                  patient.personalInfo.name.isEmpty
                      ? '?'
                      : patient.personalInfo.name[0].toUpperCase(),
                  style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            patient.personalInfo.name.isEmpty
                                ? 'Sem nome'
                                : patient.personalInfo.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (patient.discharge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.textHint.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              patient.discharge!.reason.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (patient.personalInfo.phone.isNotEmpty)
                      Text(
                        patient.personalInfo.phone,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
