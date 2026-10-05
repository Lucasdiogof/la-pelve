import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/features/agenda/presentation/pages/agenda_page.dart';
import 'package:la_pelve/features/financial/presentation/pages/financial_page.dart';
import 'package:la_pelve/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:la_pelve/features/home/presentation/cubit/home_shell_state.dart';
import 'package:la_pelve/features/home/presentation/pages/home_page.dart';
import 'package:la_pelve/features/patients/presentation/pages/patients_list_page.dart';
import 'package:la_pelve/shared/l10n/app_strings.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  final _shellCubit = HomeShellCubit();

  @override
  void dispose() {
    _shellCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.strings.home;
    return BlocProvider.value(
      value: _shellCubit,
      child: BlocBuilder<HomeShellCubit, HomeShellState>(
        builder: (context, shellState) {
          final pages = [
            HomePage(onNavigateToTab: _shellCubit.navigateToTab),
            const PatientsListPage(),
            AgendaPage(key: ValueKey(shellState.agendaResetKey)),
            FinancialPage(key: ValueKey(shellState.financialResetKey)),
          ];
          return Scaffold(
            body: IndexedStack(index: shellState.index, children: pages),
            // Barra inferior: superfície + linha de 1px no topo, sem pílula,
            // sem sombra e sem cantos arredondados (cores no
            // navigationBarTheme).
            bottomNavigationBar: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.surface,
                border: Border(top: BorderSide(color: context.colors.border)),
              ),
              child: SafeArea(
                top: false,
                child: NavigationBar(
                  selectedIndex: shellState.index,
                  onDestinationSelected: _shellCubit.navigateToTab,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home),
                      label: t.navHome,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.people_outline),
                      selectedIcon: const Icon(Icons.people),
                      label: t.navPatients,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.calendar_month_outlined),
                      selectedIcon: const Icon(Icons.calendar_month),
                      label: t.navAgenda,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.receipt_long_outlined),
                      selectedIcon: const Icon(Icons.receipt_long),
                      label: t.navFinancial,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
