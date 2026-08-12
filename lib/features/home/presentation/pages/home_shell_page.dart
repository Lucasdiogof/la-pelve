import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/pages/agenda_page.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/pages/financial_page.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/pages/home_page.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/pages/patients_list_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _index = 0;
  int _agendaResetKey = 0;
  int _financialResetKey = 0;

  void _onNavigateToTab(int index) {
    setState(() {
      if (index == 2) _agendaResetKey++;
      if (index == 3) _financialResetKey++;
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onNavigateToTab: _onNavigateToTab),
      const PatientsListPage(),
      AgendaPage(key: ValueKey(_agendaResetKey)),
      FinancialPage(key: ValueKey(_financialResetKey)),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: context.colors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _onNavigateToTab,
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: context.colors.primary.withValues(alpha: 0.15),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: context.colors.primary),
                label: 'Início',
              ),
              NavigationDestination(
                icon: const Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people, color: context.colors.primary),
                label: 'Pacientes',
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(
                  Icons.calendar_month,
                  color: context.colors.primary,
                ),
                label: 'Agenda',
              ),
              NavigationDestination(
                icon: const Icon(Icons.attach_money_outlined),
                selectedIcon: Icon(
                  Icons.attach_money,
                  color: context.colors.primary,
                ),
                label: 'Financeiro',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
