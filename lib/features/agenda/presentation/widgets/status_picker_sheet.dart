import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment_status.dart';
import 'package:fisioterapia_pelvica/features/agenda/l10n/agenda_strings.dart';

class StatusPickerSheet extends StatelessWidget {
  const StatusPickerSheet({required this.current, super.key});

  final AppointmentStatus current;

  @override
  Widget build(BuildContext context) {
    final t = AgendaStrings(context.watch<LocaleCubit>().state);
    return Material(
      color: context.colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                t.statusPickerTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.colors.primaryButton,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              for (final status in AppointmentStatus.values)
                ListTile(
                  onTap: () => Navigator.of(context).pop(status),
                  leading: Icon(
                    status == current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: status == current
                        ? context.colors.primary
                        : context.colors.textSecondary,
                  ),
                  title: Text(status.label(t.language)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
