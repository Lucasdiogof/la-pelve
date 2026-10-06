import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment_status.dart';
import 'package:la_pelve/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:la_pelve/features/agenda/presentation/widgets/appointment_status_style.dart';
import 'package:la_pelve/features/agenda/presentation/widgets/status_picker_sheet.dart';
import 'package:la_pelve/shared/widgets/app_time_row.dart';

/// Adaptador de [Appointment] para [AppTimeRow]: converte a entidade nos
/// textos/tom da linha e liga as duas interações (linha abre a edição;
/// status abre o seletor). Fica dentro do painel do dia, sem card próprio.
class AppointmentRow extends StatelessWidget {
  const AppointmentRow({
    required this.appointment,
    super.key,
    this.showDivider = true,
  });

  final Appointment appointment;
  final bool showDivider;

  Future<void> _changeStatus(BuildContext context) async {
    final selected = await showModalBottomSheet<AppointmentStatus>(
      context: context,
      // Sem o limite padrão de 9/16 da tela: em 360x640 as 6 opções cabem
      // sem rolar (o scroll do sheet fica só como rede de segurança).
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatusPickerSheet(current: appointment.status),
    );
    if (selected != null && context.mounted) {
      await context.read<AgendaCubit>().updateStatus(appointment.id, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LocaleCubit>().state;
    return AppTimeRow(
      time: appointment.time.format(context),
      title: appointment.patientName,
      statusLabel: appointment.status.label(language),
      statusTone: appointment.status.tone,
      onTap: () =>
          context.push('/agenda/${appointment.id}/editar', extra: appointment),
      onStatusTap: () => _changeStatus(context),
      showDivider: showDivider,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
    );
  }
}
