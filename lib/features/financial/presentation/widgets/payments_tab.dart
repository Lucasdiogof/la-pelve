import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';
import 'package:fisioterapia_pelvica/features/financial/l10n/financial_strings.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/widgets/financial_entry_row.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_empty_state.dart';

class PaymentsTab extends StatelessWidget {
  const PaymentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = FinancialStrings(context.watch<LocaleCubit>().state);
    return BlocBuilder<FinancialCubit, List<FinancialEntry>>(
      builder: (context, entries) {
        if (entries.isEmpty) {
          return AppEmptyState(
            icon: Icons.payments_outlined,
            title: t.emptyPaymentsTitle,
            message: t.emptyPaymentsMessage,
          );
        }

        final sorted = entries.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: sorted.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FinancialEntryRow(entry: sorted[index]),
          ),
        );
      },
    );
  }
}
