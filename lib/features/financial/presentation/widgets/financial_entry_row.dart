import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_enums.dart';
import 'package:la_pelve/features/financial/l10n/financial_strings.dart';
import 'package:la_pelve/shared/utils/money_format.dart';
import 'package:la_pelve/shared/widgets/app_date_field.dart';
import 'package:la_pelve/shared/widgets/app_status_badge.dart';

AppStatusTone _toneFor(PaymentStatus status) => switch (status) {
  PaymentStatus.paid => AppStatusTone.success,
  PaymentStatus.pending => AppStatusTone.warning,
  PaymentStatus.partial => AppStatusTone.primary,
  PaymentStatus.other => AppStatusTone.muted,
};

/// Linha de pagamento dentro do painel do mês: nome + valor em cima, data +
/// status embaixo. Sem card próprio; quem agrupa (painel do mês) cuida da
/// borda/divisor.
class FinancialEntryRow extends StatelessWidget {
  const FinancialEntryRow({
    required this.entry,
    super.key,
    this.showDivider = true,
  });

  final FinancialEntry entry;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final t = FinancialStrings(context.watch<LocaleCubit>().state);
    final name = entry.patientName.trim().isEmpty
        ? t.unnamedEntryFallback
        : entry.patientName;
    final nameStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500);
    final valueStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: context.colors.textPrimary,
    );
    final dateStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: context.colors.textSecondary);
    final badge = AppStatusBadge(
      label: entry.status.label(t.language),
      tone: _toneFor(entry.status),
    );
    final value = Text(
      formatBrl(entry.amount, language: t.language),
      style: valueStyle,
    );
    final dateRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(AppDateField.format(entry.date), style: dateStyle)),
        const SizedBox(width: AppSpacing.s8),
        badge,
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () =>
              context.push('/financeiro/${entry.id}/editar', extra: entry),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s12,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Nome longo + largura pequena + texto ampliado fazem o nome
                // quebrar em linhas demais na composição lado a lado; abaixo
                // de 300 de largura disponível, com textScale >= 1.15,
                // empilha nome / valor / (data + status).
                final textScale = MediaQuery.textScalerOf(
                  context,
                ).scale(100);
                final stacked = constraints.maxWidth < 300 && textScale >= 115;
                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: nameStyle),
                      const SizedBox(height: AppSpacing.s4),
                      value,
                      const SizedBox(height: AppSpacing.s4),
                      dateRow,
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(name, style: nameStyle)),
                        const SizedBox(width: AppSpacing.s8),
                        value,
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    dateRow,
                  ],
                );
              },
            ),
          ),
        ),
        if (showDivider) const Divider(indent: AppSpacing.s16, height: 1),
      ],
    );
  }
}
