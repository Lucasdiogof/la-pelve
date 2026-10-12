import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/features/agenda/data/appointment_reminder_repository.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment_reminder.dart';
import 'package:la_pelve/features/agenda/l10n/agenda_strings.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';
import 'package:la_pelve/shared/widgets/app_status_badge.dart';

/// Situação dos lembretes do WhatsApp de uma consulta (só leitura). Some
/// quando a consulta não tem lembrete ou a leitura falha: é informação
/// complementar, nunca bloqueia a edição.
class AppointmentRemindersSection extends StatefulWidget {
  const AppointmentRemindersSection({
    required this.appointmentId,
    required this.repository,
    super.key,
  });

  final String appointmentId;
  final AppointmentReminderRepository repository;

  @override
  State<AppointmentRemindersSection> createState() =>
      _AppointmentRemindersSectionState();
}

class _AppointmentRemindersSectionState
    extends State<AppointmentRemindersSection> {
  late final Future<Result<List<AppointmentReminder>>> _future = widget
      .repository
      .remindersFor(widget.appointmentId);

  @override
  Widget build(BuildContext context) {
    final t = AgendaStrings(context.watch<LocaleCubit>().state);
    return FutureBuilder<Result<List<AppointmentReminder>>>(
      future: _future,
      builder: (context, snapshot) {
        final result = snapshot.data;
        final reminders = result is Success<List<AppointmentReminder>>
            ? result.data
            : const <AppointmentReminder>[];
        if (reminders.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: AppSection(
            title: t.whatsappRemindersTitle,
            children: [
              for (final (index, reminder) in reminders.indexed)
                _ReminderRow(
                  reminder: reminder,
                  t: t,
                  showDivider: index != reminders.length - 1,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.reminder,
    required this.t,
    required this.showDivider,
  });

  final AppointmentReminder reminder;
  final AgendaStrings t;
  final bool showDivider;

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _format(DateTime at) =>
      '${_two(at.day)}/${_two(at.month)} ${_two(at.hour)}:${_two(at.minute)}';

  AppStatusTone get _tone => switch (reminder.status) {
    'read' || 'delivered' => AppStatusTone.success,
    'sent' => AppStatusTone.primary,
    'failed' => AppStatusTone.danger,
    'cancelled' => AppStatusTone.muted,
    _ => AppStatusTone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final at = reminder.statusAt;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.reminderTypeLabel(reminder.reminderType),
                      style: textTheme.bodyLarge,
                    ),
                    if (at != null)
                      Text(
                        _format(at),
                        style: textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: t.reminderStatusLabel(reminder.status),
                tone: _tone,
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
