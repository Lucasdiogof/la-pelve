import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/widgets/clinic_overview_section.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/widgets/home_header.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/widgets/home_view_models.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/widgets/quick_actions_section.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/widgets/today_summary_card.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.onNavigateToTab, super.key});

  final ValueChanged<int> onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final patientCount = context.watch<PatientsCubit>().state.length;
    final appointments = context.watch<AgendaCubit>().state;
    final financialEntries = context.watch<FinancialCubit>().state;

    final schedule = buildUpcomingSchedule(appointments);
    final overview = buildClinicOverview(
      patientCount: patientCount,
      appointments: appointments,
      financialEntries: financialEntries,
    );

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const HomeHeader(),
            const SizedBox(height: 20),
            TodaySummaryCard(schedule: schedule),
            const SizedBox(height: 24),
            QuickActionsSection(onNavigateToTab: onNavigateToTab),
            const SizedBox(height: 24),
            ClinicOverviewSection(overview: overview),
          ],
        ),
      ),
    );
  }
}
