import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/financial/l10n/financial_strings.dart';
import 'package:la_pelve/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:la_pelve/features/financial/presentation/widgets/financial_entry_row.dart';
import 'package:la_pelve/shared/widgets/app_empty_state.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';

class PaymentsTab extends StatelessWidget {
  const PaymentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = FinancialStrings(context.watch<LocaleCubit>().state);
    return BlocBuilder<FinancialCubit, List<FinancialEntry>>(
      builder: (context, entries) {
        final sorted = entries.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        void registerPayment() => context.push('/financeiro/novo');

        return RefreshIndicator(
          onRefresh: () => context.read<FinancialCubit>().reload(),
          child: sorted.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    AppEmptyState(
                      icon: Icons.payments_outlined,
                      title: t.emptyPaymentsTitle,
                      message: t.emptyPaymentsMessage,
                      actionLabel: t.registerPaymentFab,
                      onAction: registerPayment,
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.s16,
                    AppSpacing.gutter,
                    AppSpacing.s32,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    for (final group in _groupByMonth(sorted))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s20),
                        child: AppSection(
                          title: t.monthYearLabel(group.month),
                          children: [
                            for (var i = 0; i < group.entries.length; i++)
                              FinancialEntryRow(
                                entry: group.entries[i],
                                showDivider: i < group.entries.length - 1,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  List<_MonthGroup> _groupByMonth(List<FinancialEntry> sorted) {
    final groups = <_MonthGroup>[];
    for (final entry in sorted) {
      final monthKey = DateTime(entry.date.year, entry.date.month);
      if (groups.isNotEmpty && groups.last.month == monthKey) {
        groups.last.entries.add(entry);
      } else {
        groups.add(_MonthGroup(monthKey, [entry]));
      }
    }
    return groups;
  }
}

class _MonthGroup {
  _MonthGroup(this.month, this.entries);

  final DateTime month;
  final List<FinancialEntry> entries;
}
