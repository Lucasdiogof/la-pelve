import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/home/l10n/home_strings.dart';
import 'package:la_pelve/features/home/presentation/cubit/home_financial_visibility_cubit.dart';
import 'package:la_pelve/features/home/presentation/widgets/home_panel.dart';
import 'package:la_pelve/features/home/presentation/widgets/home_view_models.dart';
import 'package:la_pelve/shared/utils/money_format.dart';
import 'package:la_pelve/shared/widgets/app_metric.dart';

/// Visão geral da clínica num único painel, em composição 1 + 2: a receita do
/// mês em destaque (com o botão de ocultar) e, abaixo, pacientes e
/// atendimentos da semana. Assim o valor em reais nunca disputa uma coluna
/// estreita com as outras métricas.
class ClinicOverviewSection extends StatelessWidget {
  const ClinicOverviewSection({
    required this.overview,
    required this.onNavigateToTab,
    super.key,
  });

  final ClinicOverview overview;
  final ValueChanged<int> onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LocaleCubit>().state;
    final t = HomeStrings(language);
    final hideFinancial = context.watch<HomeFinancialVisibilityCubit>().state;
    // Os rótulos têm quebra embutida do layout antigo; aqui quebram sozinhos.
    String label(String raw) => raw.replaceAll('\n', ' ');
    return HomePanel(
      title: t.clinicOverviewTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TappableMetric(
                  onTap: () => onNavigateToTab(3),
                  padding: const EdgeInsets.fromLTRB(
                    HomePanel.inset,
                    AppSpacing.s8,
                    AppSpacing.s8,
                    AppSpacing.s16,
                  ),
                  child: AppMetric(
                    label: label(t.receivedThisMonthLabel),
                    value: hideFinancial
                        ? 'R\$ ••••'
                        : formatBrl(
                            overview.receivedThisMonth,
                            language: language,
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.s4,
                  right: AppSpacing.s4,
                ),
                child: IconButton(
                  icon: Icon(
                    hideFinancial
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  color: context.colors.textSecondary,
                  tooltip: hideFinancial
                      ? t.showFinancialValueTooltip
                      : t.hideFinancialValueTooltip,
                  onPressed: () =>
                      context.read<HomeFinancialVisibilityCubit>().toggle(),
                ),
              ),
            ],
          ),
          Divider(height: 1, color: context.colors.border),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _TappableMetric(
                    onTap: () => onNavigateToTab(1),
                    padding: const EdgeInsets.fromLTRB(
                      HomePanel.inset,
                      AppSpacing.s16,
                      AppSpacing.s12,
                      AppSpacing.s16,
                    ),
                    child: AppMetric(
                      label: label(t.activePatientsLabel),
                      value: '${overview.activePatients}',
                      large: false,
                    ),
                  ),
                ),
                VerticalDivider(width: 1, color: context.colors.border),
                Expanded(
                  child: _TappableMetric(
                    onTap: () => onNavigateToTab(2),
                    padding: const EdgeInsets.fromLTRB(
                      HomePanel.inset,
                      AppSpacing.s16,
                      HomePanel.inset,
                      AppSpacing.s16,
                    ),
                    child: AppMetric(
                      label: label(t.appointmentsThisWeekLabel),
                      value: '${overview.appointmentsThisWeek}',
                      large: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Métrica tocável (leva à aba correspondente, como antes), com o número
/// alinhado embaixo para as duas colunas baterem mesmo se um rótulo quebrar.
class _TappableMetric extends StatelessWidget {
  const _TappableMetric({
    required this.onTap,
    required this.padding,
    required this.child,
  });

  final VoidCallback onTap;
  final EdgeInsets padding;
  final AppMetric child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Align(alignment: Alignment.bottomLeft, child: child),
      ),
    );
  }
}
