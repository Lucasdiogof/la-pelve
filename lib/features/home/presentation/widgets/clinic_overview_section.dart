import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/home/l10n/home_strings.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/widgets/home_view_models.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/widgets/home_styles.dart';

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
    final t = HomeStrings(context.watch<LocaleCubit>().state);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.clinicOverviewTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(kHomeCardRadius),
              boxShadow: kHomeCardShadow,
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _OverviewStat(
                      icon: Icons.groups_outlined,
                      iconColor: context.colors.logoTeal,
                      value: '${overview.activePatients}',
                      label: t.activePatientsLabel,
                      onTap: () => onNavigateToTab(1),
                    ),
                  ),
                  VerticalDivider(
                    color: context.colors.border,
                    width: 1,
                    indent: 4,
                    endIndent: 4,
                  ),
                  Expanded(
                    child: _OverviewStat(
                      icon: Icons.calendar_month_outlined,
                      iconColor: context.colors.primary,
                      value: '${overview.appointmentsThisWeek}',
                      label: t.appointmentsThisWeekLabel,
                      onTap: () => onNavigateToTab(2),
                    ),
                  ),
                  VerticalDivider(
                    color: context.colors.border,
                    width: 1,
                    indent: 4,
                    endIndent: 4,
                  ),
                  Expanded(
                    child: _OverviewStat(
                      icon: Icons.payments_outlined,
                      iconColor: context.colors.success,
                      value:
                          'R\$ ${overview.receivedThisMonth.toStringAsFixed(0)}',
                      label: t.receivedThisMonthLabel,
                      onTap: () => onNavigateToTab(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
