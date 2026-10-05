import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';

/// Abas da tela: texto + sublinhado de 2px em primary (via `tabBarTheme`),
/// sem contêiner nem pílula. O nome foi mantido para não mexer nas telas.
class AppSegmentedTabBar extends StatelessWidget {
  const AppSegmentedTabBar({required this.tabs, super.key});

  final List<Tab> tabs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: TabBar(tabs: tabs),
    );
  }
}
