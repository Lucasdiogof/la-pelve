import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/widgets/lancamentos_tab.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/widgets/monthly_report_tab.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';

class FinancialPage extends StatelessWidget {
  const FinancialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: Column(
          children: [
            const ModernAppBar(
              title: 'Financeiro',
              subtitle: 'Lançamentos e relatórios',
            ),
            Material(
              color: context.colors.surface,
              child: TabBar(
                labelColor: context.colors.textPrimary,
                unselectedLabelColor: context.colors.textSecondary,
                indicatorColor: context.colors.primaryButton,
                tabs: const [
                  Tab(text: 'Lançamentos'),
                  Tab(text: 'Relatório'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [LancamentosTab(), MonthlyReportTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
