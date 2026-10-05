import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/shared/widgets/app_list_row.dart';
import 'package:la_pelve/shared/widgets/app_sheet.dart';

class PatientPickerSheet extends StatelessWidget {
  const PatientPickerSheet({required this.patients, super.key});

  final List<Patient> patients;

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      children: [
        Text(
          'Selecionar paciente',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: context.colors.primary,
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
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                final nome = patient.personalInfo.name.trim().isEmpty
                    ? 'Sem nome'
                    : patient.personalInfo.name.trim();
                return AppListRow(
                  title: nome,
                  subtitle: patient.personalInfo.phone.trim(),
                  leading: AppInitialAvatar(name: nome),
                  trailing: const Icon(Icons.chevron_right),
                  padding: EdgeInsets.zero,
                  showDivider: index != patients.length - 1,
                  onTap: () => Navigator.of(context).pop(patient),
                );
              },
            ),
          ),
      ],
    );
  }
}
