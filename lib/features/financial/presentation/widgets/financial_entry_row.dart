import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_enums.dart';
import 'package:fisioterapia_pelvica/features/financial/l10n/financial_strings.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_confirm_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';

class FinancialEntryRow extends StatelessWidget {
  const FinancialEntryRow({required this.entry, super.key});

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
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.patientName,
                    overflow: TextOverflow.ellipsis,
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
            const SizedBox(width: 8),
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
      ),
    );
  }
}
