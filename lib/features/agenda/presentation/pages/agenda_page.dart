import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment_status.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_empty_state.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';

const _weekdays = [
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final endDate = today.add(const Duration(days: 7));
    return Scaffold(
      backgroundColor: context.colors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'agenda-fab',
        onPressed: () => context.push('/agenda/novo'),
        icon: const Icon(Icons.add),
        label: const Text('Criar agendamento'),
      ),
      body: Column(
        children: [
          const ModernAppBar(
            title: 'Agenda',
            subtitle: 'Seus próximos atendimentos',
          ),
          Expanded(
            child: BlocBuilder<AgendaCubit, List<Appointment>>(
              builder: (context, appointments) {
                final semana =
                    appointments.where((a) {
                      final data = _dateOnly(a.data);
                      return !data.isBefore(today) && !data.isAfter(endDate);
                    }).toList()..sort((a, b) {
                      final byDate = a.data.compareTo(b.data);
                      if (byDate != 0) return byDate;
                      return _minutes(a.hora).compareTo(_minutes(b.hora));
                    });

                if (semana.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: 'Nenhum agendamento',
                    message: 'Nada marcado para os próximos 7 dias.',
                  );
                }

                final porDia = <DateTime, List<Appointment>>{};
                for (final appointment in semana) {
                  porDia
                      .putIfAbsent(_dateOnly(appointment.data), () => [])
                      .add(appointment);
                }
                final dias = porDia.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: dias.length,
                  itemBuilder: (context, index) {
                    final dia = dias[index];
                    final appointmentsDoDia = porDia[dia]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dayLabel(dia, today),
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final appointment in appointmentsDoDia)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _AppointmentRow(appointment: appointment),
                            ),
                        ],
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
  }

  String _dayLabel(DateTime day, DateTime today) {
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'HOJE';
    if (diff == 1) return 'AMANHÃ';
    final weekday = _weekdays[day.weekday - 1].toUpperCase();
    return '$weekday, ${AppDateField.format(day)}';
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({required this.appointment});

  final Appointment appointment;

  Future<void> _changeStatus(BuildContext context) async {
    final selected = await showModalBottomSheet<AppointmentStatus>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatusPickerSheet(current: appointment.status),
    );
    if (selected != null && context.mounted) {
      await context.read<AgendaCubit>().updateStatus(appointment.id, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foreground = appointment.status.foreground(context.colors);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              appointment.hora.format(context),
              style: TextStyle(
                color: context.colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              appointment.nomePaciente,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () => _changeStatus(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    );
  }
}

class _StatusPickerSheet extends StatelessWidget {
  const _StatusPickerSheet({required this.current});

  final AppointmentStatus current;

  @override
  Widget build(BuildContext context) {
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
                'Status do agendamento',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
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
                  title: Text(status.label),
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
    AppointmentStatus.agendado => colors.primary,
    AppointmentStatus.confirmado => colors.primaryButton,
    AppointmentStatus.atendido => colors.success,
    AppointmentStatus.cancelado => colors.error,
    AppointmentStatus.faltou => colors.error,
    AppointmentStatus.reagendado => colors.textSecondary,
  };
}
