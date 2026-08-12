import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_enums.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_confirm_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';

const _monthNames = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

class MonthlyReportTab extends StatefulWidget {
  const MonthlyReportTab({super.key});

  @override
  State<MonthlyReportTab> createState() => _MonthlyReportTabState();
}

class _MonthlyReportTabState extends State<MonthlyReportTab> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final lastDay = DateTime(_month.year, _month.month + 1, 0);

    return BlocBuilder<FinancialCubit, List<FinancialEntry>>(
      builder: (context, entries) {
        final inMonth =
            entries
                .where(
                  (entry) =>
                      entry.data.year == _month.year &&
                      entry.data.month == _month.month,
                )
                .toList()
              ..sort((a, b) => a.data.compareTo(b.data));
        final total = inMonth
            .where((entry) => entry.status == StatusPagamento.pago)
            .fold<double>(0, (sum, entry) => sum + entry.valor);

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _shiftMonth(-1),
                ),
                Text(
                  '${_monthNames[_month.month - 1]} ${_month.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _shiftMonth(1),
                ),
              ],
            ),
            Text(
              'Período: ${AppDateField.format(firstDay)} a ${AppDateField.format(lastDay)}',
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
                  const Text(
                    'Total recebido',
                    style: TextStyle(color: Colors.white70),
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
                  'Nenhum lançamento neste mês.',
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
    final confirmed = await AppConfirmSheet.show(
      context,
      title: 'Excluir lançamento',
      description:
          'Tem certeza que deseja excluir este lançamento? Essa ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<FinancialCubit>().deleteEntry(entry.id);
  }

  @override
  Widget build(BuildContext context) {
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
                  AppDateField.format(entry.data),
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  entry.status.label,
                  style: TextStyle(
                    color: entry.status == StatusPagamento.pago
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
            'R\$ ${entry.valor.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.colors.primary,
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: context.colors.error),
            tooltip: 'Excluir lançamento',
            onPressed: () => _delete(context),
          ),
        ],
      ),
    );
  }
}
