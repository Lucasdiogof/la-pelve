import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/state/data_state.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_enums.dart';
import 'package:la_pelve/features/financial/l10n/financial_strings.dart';
import 'package:la_pelve/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:la_pelve/features/financial/presentation/cubit/financial_report_month_cubit.dart';
import 'package:la_pelve/shared/utils/money_format.dart';
import 'package:la_pelve/shared/widgets/app_date_field.dart';
import 'package:la_pelve/shared/widgets/app_metric.dart';
import 'package:la_pelve/shared/widgets/data_state_view.dart';

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

    return BlocBuilder<FinancialCubit, DataState<List<FinancialEntry>>>(
      builder: (context, state) => DataStateView<List<FinancialEntry>>(
        state: state,
        onRetry: () => context.read<FinancialCubit>().refresh(),
        builder: (context, entries) {
          final inMonth = entries.where(
            (entry) =>
                entry.date.year == month.year &&
                entry.date.month == month.month,
          );
          final total = inMonth
              .where((entry) => entry.status == PaymentStatus.paid)
              .fold<double>(0, (sum, entry) => sum + entry.amount);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => monthCubit.shift(-1),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          t.monthYearLabel(month),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.periodRange(
                            AppDateField.format(firstDay),
                            AppDateField.format(lastDay),
                          ),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => monthCubit.shift(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s20),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s20),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: context.colors.border),
                ),
                child: AppMetric(
                  label: t.totalReceived,
                  value: formatBrl(total, language: t.language),
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
