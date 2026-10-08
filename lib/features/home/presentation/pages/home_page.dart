import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:la_pelve/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:la_pelve/features/home/presentation/cubit/home_clock_cubit.dart';
import 'package:la_pelve/features/home/presentation/widgets/clinic_overview_section.dart';
import 'package:la_pelve/features/home/presentation/widgets/home_header.dart';
import 'package:la_pelve/features/home/presentation/widgets/home_view_models.dart';
import 'package:la_pelve/features/home/presentation/widgets/quick_actions_section.dart';
import 'package:la_pelve/features/home/presentation/widgets/upcoming_schedule_section.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/shared/widgets/app_loading_widget.dart';
import 'package:la_pelve/shared/widgets/data_state_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.onNavigateToTab, super.key});

  final ValueChanged<int> onNavigateToTab;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _clockCubit = HomeClockCubit();
  bool _wasBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockCubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasBackgrounded = true;
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      // Revalida sem esconder nada: os dados atuais continuam na tela e, se
      // a atualização falhar, continuam valendo.
      _refreshAll();
    }
  }

  Future<void> _refreshAll({bool reportFailure = false}) async {
    final patients = context.read<PatientsCubit>();
    final agenda = context.read<AgendaCubit>();
    final financial = context.read<FinancialCubit>();
    await Future.wait([
      patients.refresh(),
      agenda.refresh(),
      financial.refresh(),
    ]);
    final failed = [
      patients.state,
      agenda.state,
      financial.state,
    ].any((s) => s.failure != null);
    if (reportFailure && failed && mounted) showRefreshFailed(context);
  }

  @override
  Widget build(BuildContext context) {
    final patients = context.watch<PatientsCubit>().state.data;
    final appointments = context.watch<AgendaCubit>().state.data;
    final financialEntries = context.watch<FinancialCubit>().state.data;
    final language = context.watch<LocaleCubit>().state;

    // Sem a primeira carga de algum dado da Home, não há métrica, agenda ou
    // receita para mostrar: nada de "0" ou "sem atendimentos" falsos. Na
    // navegação normal isso não aparece, porque o SessionDataGate só monta a
    // Home com os dados prontos.
    if (patients == null || appointments == null || financialEntries == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: const AppLoadingWidget(),
      );
    }
    final patientCount = patients.length;

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
              child: RefreshIndicator(
                onRefresh: () => _refreshAll(reportFailure: true),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s32),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const HomeHeader(),
                    const SizedBox(height: AppSpacing.s24),
                    UpcomingScheduleSection(
                      schedule: schedule,
                      onOpenAgenda: () => widget.onNavigateToTab(2),
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    QuickActionsSection(
                      onNavigateToTab: widget.onNavigateToTab,
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    ClinicOverviewSection(
                      overview: overview,
                      onNavigateToTab: widget.onNavigateToTab,
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
