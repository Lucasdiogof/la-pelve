import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment_status.dart';
import 'package:la_pelve/features/agenda/l10n/agenda_strings.dart';
import 'package:la_pelve/shared/widgets/app_sheet.dart';

class StatusPickerSheet extends StatelessWidget {
  const StatusPickerSheet({required this.current, super.key});

  final AppointmentStatus current;

  @override
  Widget build(BuildContext context) {
    final t = AgendaStrings(context.watch<LocaleCubit>().state);
    return AppSheet(
      children: [
        Text(
          t.statusPickerTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: context.colors.primary,
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
    );
  }
}
