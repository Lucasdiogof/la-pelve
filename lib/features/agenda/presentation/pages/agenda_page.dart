import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/agenda/l10n/agenda_strings.dart';
import 'package:la_pelve/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:la_pelve/features/agenda/presentation/widgets/agenda_monthly_report_tab.dart';
import 'package:la_pelve/features/agenda/presentation/widgets/agenda_view_models.dart';
import 'package:la_pelve/features/agenda/presentation/widgets/appointment_row.dart';
import 'package:la_pelve/shared/widgets/app_date_field.dart';
import 'package:la_pelve/shared/widgets/app_empty_state.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';
import 'package:la_pelve/shared/widgets/app_segmented_tab_bar.dart';
import 'package:la_pelve/shared/widgets/modern_app_bar.dart';

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AgendaStrings(context.watch<LocaleCubit>().state);
    final today = dateOnly(DateTime.now());
    void create() => context.push('/agenda/novo');
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: Column(
          children: [
            ModernAppBar(
              title: t.pageTitle,
              subtitle: t.pageSubtitle,
              actionIcon: Icons.add,
              actionTooltip: t.createAppointment,
              onAction: create,
            ),
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
                      final dias = porDia.keys.toList()..sort();

                      return RefreshIndicator(
                        onRefresh: () => context.read<AgendaCubit>().reload(),
                        child: dias.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  AppEmptyState(
                                    icon: Icons.calendar_month_outlined,
                                    title: t.emptyTitle,
                                    message: t.emptyMessage,
                                    actionLabel: t.createAppointment,
                                    onAction: create,
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.gutter,
                                  AppSpacing.s20,
                                  AppSpacing.gutter,
                                  AppSpacing.s32,
                                ),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: dias.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: AppSpacing.s24),
                                itemBuilder: (context, index) {
                                  final dia = dias[index];
                                  final doDia = porDia[dia]!;
                                  // Um painel por dia (overline fora); as
                                  // consultas ficam dentro, com divisores --
                                  // nunca um card por consulta.
                                  return AppSection(
                                    title: _dayLabel(dia, today, t),
                                    children: [
                                      for (var i = 0; i < doDia.length; i++)
                                        AppointmentRow(
                                          appointment: doDia[i],
                                          showDivider: i != doDia.length - 1,
                                        ),
                                    ],
                                  );
                                },
                              ),
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
