import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/agenda/l10n/agenda_strings.dart';
import 'package:la_pelve/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:la_pelve/features/agenda/presentation/cubit/agenda_report_month_cubit.dart';
import 'package:la_pelve/shared/widgets/app_date_field.dart';
import 'package:la_pelve/shared/widgets/app_metric.dart';

class AgendaMonthlyReportTab extends StatelessWidget {
  const AgendaMonthlyReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AgendaReportMonthCubit(),
      child: BlocBuilder<AgendaReportMonthCubit, DateTime>(
        builder: (context, month) => _AgendaMonthlyReportView(month: month),
      ),
    );
  }
}

class _AgendaMonthlyReportView extends StatelessWidget {
  const _AgendaMonthlyReportView({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final t = AgendaStrings(context.watch<LocaleCubit>().state);
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final monthCubit = context.read<AgendaReportMonthCubit>();

    return BlocBuilder<AgendaCubit, List<Appointment>>(
      builder: (context, appointments) {
        final inMonth = appointments
            .where(
              (appointment) =>
                  appointment.date.year == month.year &&
                  appointment.date.month == month.month,
            )
            .toList();

        final textTheme = Theme.of(context).textTheme;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.s16,
            AppSpacing.gutter,
            AppSpacing.s32,
          ),
          children: [
            // Seletor de mês: chevrons com área de 48 e o mês no centro
            // (pode quebrar em 2 linhas com fonte ampliada).
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).previousMonthTooltip,
                  onPressed: () => monthCubit.shift(-1),
                ),
                Expanded(
                  child: Text(
                    '${t.monthName(month.month)} ${month.year}',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: textTheme.titleMedium?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                  onPressed: () => monthCubit.shift(1),
                ),
              ],
            ),
            Text(
              t.periodRange(
                AppDateField.format(firstDay),
                AppDateField.format(lastDay),
              ),
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            // Um único agrupamento: surface + borda, raio md, sem sombra e
            // sem fundo de cor -- o número carrega a hierarquia.
            Material(
              color: context.colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdAll,
                side: BorderSide(color: context.colors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s20),
                child: AppMetric(
                  label: t.appointmentsInMonth,
                  value: '${inMonth.length}',
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
