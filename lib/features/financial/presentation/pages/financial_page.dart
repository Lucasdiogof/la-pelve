import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/financial/l10n/financial_strings.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/widgets/payments_tab.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/widgets/monthly_report_tab.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_segmented_tab_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';

class FinancialPage extends StatelessWidget {
  const FinancialPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = FinancialStrings(context.watch<LocaleCubit>().state);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.colors.background,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'financial-fab',
          onPressed: () => context.push('/financeiro/novo'),
          icon: const Icon(Icons.add),
          label: Text(t.registerPaymentFab),
        ),
        body: Column(
          children: [
            ModernAppBar(title: t.pageTitle, subtitle: t.pageSubtitle),
            AppSegmentedTabBar(
              tabs: [
                Tab(text: t.paymentsTab),
                Tab(text: t.reportTab),
              ],
            ),
            const Expanded(
              child: TabBarView(children: [PaymentsTab(), MonthlyReportTab()]),
            ),
          ],
        ),
      ),
    );
  }
}
