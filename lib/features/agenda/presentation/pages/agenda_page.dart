import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/l10n/agenda_strings.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/widgets/agenda_monthly_report_tab.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/widgets/agenda_view_models.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/widgets/appointment_row.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_empty_state.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_segmented_tab_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AgendaStrings(context.watch<LocaleCubit>().state);
    final today = dateOnly(DateTime.now());
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.colors.background,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'agenda-fab',
          onPressed: () => context.push('/agenda/novo'),
          icon: const Icon(Icons.add),
          label: Text(t.createAppointment),
        ),
        body: Column(
          children: [
            ModernAppBar(title: t.pageTitle, subtitle: t.pageSubtitle),
            AppSegmentedTabBar(
              tabs: [
                Tab(text: t.upcomingTab),
                Tab(text: t.reportTab),
              ],
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
                        return AppEmptyState(
                          icon: Icons.calendar_month_outlined,
                          title: t.emptyTitle,
                          message: t.emptyMessage,
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
                                  _dayLabel(dia, today, t),
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

  String _dayLabel(DateTime day, DateTime today, AgendaStrings t) {
    final diff = day.difference(today).inDays;
    if (diff == 0) return t.today;
    if (diff == 1) return t.tomorrow;
    final weekday = t.weekdayLabel(day.weekday).toUpperCase();
    return '$weekday, ${AppDateField.format(day)}';
  }
}
