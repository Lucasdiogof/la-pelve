import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment_status.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/widgets/status_picker_sheet.dart';

class AppointmentRow extends StatelessWidget {
  const AppointmentRow({required this.appointment, super.key});

  final Appointment appointment;

  Future<void> _changeStatus(BuildContext context) async {
    final selected = await showModalBottomSheet<AppointmentStatus>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatusPickerSheet(current: appointment.status),
    );
    if (selected != null && context.mounted) {
      await context.read<AgendaCubit>().updateStatus(appointment.id, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foreground = appointment.status.foreground(context.colors);
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          '/agenda/${appointment.id}/editar',
          extra: appointment,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  appointment.time.format(context),
                  style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  appointment.patientName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () => _changeStatus(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    appointment.status.label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _AppointmentStatusColor on AppointmentStatus {
  Color foreground(AppColors colors) => switch (this) {
    AppointmentStatus.scheduled => colors.primary,
    AppointmentStatus.confirmed => colors.primaryButton,
    AppointmentStatus.fulfilled => colors.success,
    AppointmentStatus.cancelled => colors.error,
    AppointmentStatus.noShow => colors.error,
    AppointmentStatus.rescheduled => colors.textSecondary,
  };
}
