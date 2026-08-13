import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_enums.dart';
import 'package:fisioterapia_pelvica/features/financial/l10n/financial_strings.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/financial_report_month_cubit.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_confirm_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';

class MonthlyReportTab extends StatelessWidget {
  const MonthlyReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FinancialReportMonthCubit(),
      child: BlocBuilder<FinancialReportMonthCubit, DateTime>(
        builder: (context, month) => _MonthlyReportView(month: month),
      ),
    );
  }
}

class _MonthlyReportView extends StatelessWidget {
  const _MonthlyReportView({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final t = FinancialStrings(context.watch<LocaleCubit>().state);
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final monthCubit = context.read<FinancialReportMonthCubit>();

    return BlocBuilder<FinancialCubit, List<FinancialEntry>>(
      builder: (context, entries) {
        final inMonth =
            entries
                .where(
                  (entry) =>
                      entry.date.year == month.year &&
                      entry.date.month == month.month,
                )
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date));
        final total = inMonth
            .where((entry) => entry.status == PaymentStatus.paid)
            .fold<double>(0, (sum, entry) => sum + entry.amount);

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
                    t.totalReceived,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (inMonth.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  t.noPaymentsThisMonth,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              )
            else
              for (final entry in inMonth) _MonthlyReportEntryTile(entry),
          ],
        );
      },
    );
  }
}

class _MonthlyReportEntryTile extends StatelessWidget {
  const _MonthlyReportEntryTile(this.entry);

  final FinancialEntry entry;

  Future<void> _delete(BuildContext context) async {
    final t = FinancialStrings(context.read<LocaleCubit>().state);
    final confirmed = await AppConfirmSheet.show(
      context,
      title: t.deletePaymentTitle,
      description: t.deletePaymentDescription,
      confirmLabel: t.deleteLabel,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<FinancialCubit>().deleteEntry(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final t = FinancialStrings(context.watch<LocaleCubit>().state);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.patientName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  AppDateField.format(entry.date),
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  entry.status.label(t.language),
                  style: TextStyle(
                    color: entry.status == PaymentStatus.paid
                        ? context.colors.success
                        : context.colors.primaryButton,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'R\$ ${entry.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.colors.primary,
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: context.colors.error),
            tooltip: t.deletePaymentTooltip,
            onPressed: () => _delete(context),
          ),
        ],
      ),
    );
  }
}
