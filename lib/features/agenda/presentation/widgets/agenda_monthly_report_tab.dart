import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/l10n/agenda_strings.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_report_month_cubit.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';

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

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => monthCubit.shift(-1),
                ),
                Text(
                  '${t.monthName(month.month)} ${month.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
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
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    t.appointmentsInMonth,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${inMonth.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
