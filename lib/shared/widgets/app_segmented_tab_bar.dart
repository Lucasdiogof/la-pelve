import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';

class AppSegmentedTabBar extends StatelessWidget {
  const AppSegmentedTabBar({required this.tabs, super.key});

  final List<Tab> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: TabBar(
        tabs: tabs,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: context.colors.primaryButton,
          borderRadius: BorderRadius.circular(10),
        ),
        splashBorderRadius: BorderRadius.circular(10),
        labelColor: Colors.white,
        unselectedLabelColor: context.colors.textSecondary,
      ),
    );
  }
}
