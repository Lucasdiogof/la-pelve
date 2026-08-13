import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';

class PatientPickerSheet extends StatelessWidget {
  const PatientPickerSheet({required this.patients, super.key});

  final List<Patient> patients;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Selecionar paciente',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.colors.primaryButton,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              if (patients.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Nenhum paciente cadastrado ainda.\n'
                    'Toque em "Novo paciente" para cadastrar o primeiro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: patients.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      final nome = patient.personalInfo.name.trim().isEmpty
                          ? 'Sem nome'
                          : patient.personalInfo.name.trim();
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(context).pop(patient),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.colors.background,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: context.colors.primary
                                    .withValues(alpha: 0.12),
                                child: Text(
                                  nome[0].toUpperCase(),
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
                                    Text(
                                      nome,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (patient.personalInfo.phone
                                        .trim()
                                        .isNotEmpty)
                                      Text(
                                        patient.personalInfo.phone,
                                        style: TextStyle(
                                          color: context.colors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: context.colors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
