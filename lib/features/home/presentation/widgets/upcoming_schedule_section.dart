import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/home/l10n/home_strings.dart';
import 'package:la_pelve/features/home/presentation/widgets/home_panel.dart';
import 'package:la_pelve/features/home/presentation/widgets/home_view_models.dart';
import 'package:la_pelve/shared/widgets/app_time_row.dart';

/// Próximos atendimentos (7 dias, regra de `buildUpcomingSchedule`) num único
/// painel, agrupados pelo rótulo de dia que o view model já entrega. As
/// linhas não viram cards: ficam dentro do painel, com divisores.
class UpcomingScheduleSection extends StatelessWidget {
  const UpcomingScheduleSection({
    required this.schedule,
    required this.onOpenAgenda,
    super.key,
  });

  final List<ScheduleItem> schedule;
  final VoidCallback onOpenAgenda;

  static const _rowPadding = EdgeInsets.symmetric(horizontal: HomePanel.inset);

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LocaleCubit>().state;
    final t = HomeStrings(language);
    return HomePanel(
      title: t.upcomingAppointmentsTitle,
      actionLabel: t.viewAgendaAction,
      onAction: onOpenAgenda,
      child: schedule.isEmpty
          ? _EmptySchedule(t: t)
          : Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, group) in _groupByDay(
                    schedule,
                  ).indexed) ...[
                    // Entre dias: espaço maior que entre consultas + um
                    // divisor discreto na largura do conteúdo.
                    if (index > 0) ...[
                      const SizedBox(height: AppSpacing.s8),
                      const Divider(
                        height: 1,
                        indent: HomePanel.inset,
                        endIndent: HomePanel.inset,
                      ),
                    ],
                    _DayHeader(group.label, isFirst: index == 0),
                    for (var i = 0; i < group.items.length; i++)
                      AppTimeRow(
                        time: group.items[i].time,
                        title: group.items[i].patientName,
                        statusLabel: group.items[i].status.label(language),
                        statusTone: group.items[i].status.tone,
                        onTap: onOpenAgenda,
                        padding: _rowPadding,
                        showDivider: i != group.items.length - 1,
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  /// Agrupa itens consecutivos com o mesmo rótulo de dia (a lista já vem
  /// ordenada por data e horário).
  static List<({String label, List<ScheduleItem> items})> _groupByDay(
    List<ScheduleItem> schedule,
  ) {
    final groups = <({String label, List<ScheduleItem> items})>[];
    for (final item in schedule) {
      if (groups.isEmpty || groups.last.label != item.dayLabel) {
        groups.add((label: item.dayLabel, items: [item]));
      } else {
        groups.last.items.add(item);
      }
    }
    return groups;
  }
}

/// Cabeçalho de grupo de dia: só o overline sobre o surface do painel (sem
/// faixa preenchida); a hierarquia vem do espaço e do divisor entre grupos.
class _DayHeader extends StatelessWidget {
  const _DayHeader(this.label, {required this.isFirst});

  final String label;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        HomePanel.inset,
        isFirst ? AppSpacing.s12 : AppSpacing.s16,
        HomePanel.inset,
        AppSpacing.s4,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(
          context,
        ).textTheme.overline.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule({required this.t});

  final HomeStrings t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              HomePanel.inset,
              AppSpacing.s4,
              HomePanel.inset,
              0,
            ),
            child: Text(
              t.noUpcomingAppointmentsMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
          // O TextButton tem 12 de padding interno: 4 + 12 = recuo do painel.
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s4),
            child: TextButton(
              onPressed: () => context.push('/agenda/novo'),
              child: Text(t.scheduleAppointmentAction.replaceAll('\n', ' ')),
            ),
          ),
        ],
      ),
    );
  }
}
