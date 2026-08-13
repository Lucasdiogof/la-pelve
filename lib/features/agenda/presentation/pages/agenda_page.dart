import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/widgets/agenda_monthly_report_tab.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/widgets/agenda_view_models.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/widgets/appointment_row.dart';
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

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            Material(
              color: context.colors.surface,
              child: TabBar(
                labelColor: context.colors.textPrimary,
                unselectedLabelColor: context.colors.textSecondary,
                indicatorColor: context.colors.primaryButton,
                tabs: const [
                  Tab(text: 'Próximos'),
                  Tab(text: 'Relatório'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  BlocBuilder<AgendaCubit, List<Appointment>>(
                    builder: (context, appointments) {
                      final porDia = groupUpcomingAppointmentsByDay(
                        appointments,
                        today: today,
                      );

                      if (porDia.isEmpty) {
                        return const AppEmptyState(
                          icon: Icons.calendar_month_outlined,
                          title: 'Nenhum agendamento',
                          message: 'Nada marcado para os próximos 7 dias.',
                        );
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
                                    child: AppointmentRow(
                                      appointment: appointment,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const AgendaMonthlyReportTab(),
                ],
              ),
            ),
          ],
        ),
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
