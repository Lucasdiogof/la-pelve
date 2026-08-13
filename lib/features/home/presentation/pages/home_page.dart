import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/cubit/home_clock_cubit.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/widgets/clinic_overview_section.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/widgets/home_header.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/widgets/home_view_models.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/widgets/quick_actions_section.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/widgets/today_summary_card.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.onNavigateToTab, super.key});

  final ValueChanged<int> onNavigateToTab;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _clockCubit = HomeClockCubit();

  @override
  void dispose() {
    _clockCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientCount = context.watch<PatientsCubit>().state.length;
    final appointments = context.watch<AgendaCubit>().state;
    final financialEntries = context.watch<FinancialCubit>().state;
    final language = context.watch<LocaleCubit>().state;

    return BlocProvider.value(
      value: _clockCubit,
      child: BlocBuilder<HomeClockCubit, int>(
        builder: (context, _) {
          final schedule = buildUpcomingSchedule(appointments, language);
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
                  TodaySummaryCard(
                    schedule: schedule,
                    onTap: () => widget.onNavigateToTab(2),
                  ),
                  const SizedBox(height: 24),
                  QuickActionsSection(onNavigateToTab: widget.onNavigateToTab),
                  const SizedBox(height: 24),
                  ClinicOverviewSection(overview: overview),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
