import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment_status.dart';
import 'package:la_pelve/features/agenda/domain/repositories/agenda_repository.dart';
import 'package:la_pelve/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/financial/domain/repositories/financial_repository.dart';
import 'package:la_pelve/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:la_pelve/features/home/presentation/cubit/home_financial_visibility_cubit.dart';
import 'package:la_pelve/features/home/presentation/pages/home_page.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_repository.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/features/profile/domain/repositories/profile_repository.dart';
import 'package:la_pelve/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:la_pelve/shared/widgets/app_time_row.dart';

class _FakePatientRepository extends Mock implements PatientRepository {}

class _FakeAgendaRepository extends Mock implements AgendaRepository {}

class _FakeFinancialRepository extends Mock implements FinancialRepository {}

class _FakeProfileRepository extends Mock implements ProfileRepository {}

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  Future<List<int>> pumpHome(
    WidgetTester tester, {
    List<Appointment> appointments = const [],
    List<FinancialEntry> entries = const [],
    int patientCount = 0,
  }) async {
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    SharedPreferences.setMockInitialValues({});

    final patients = _FakePatientRepository();
    final agenda = _FakeAgendaRepository();
    final financial = _FakeFinancialRepository();
    final profile = _FakeProfileRepository();
    when(() => patients.getAll()).thenAnswer(
      (_) async => Success([
        for (var i = 0; i < patientCount; i++)
          Patient(id: 'p$i', createdAt: today),
      ]),
    );
    when(() => agenda.getAll()).thenAnswer((_) async => Success(appointments));
    when(() => financial.getAll()).thenAnswer((_) async => Success(entries));
    when(
      () => profile.getCurrent(),
    ).thenAnswer((_) async => Error(ServerFailure()));

    final navigatedTabs = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => PatientsCubit(patients)),
            BlocProvider(create: (_) => AgendaCubit(agenda)),
            BlocProvider(create: (_) => FinancialCubit(financial)),
            BlocProvider(create: (_) => ProfileCubit(profile)),
            BlocProvider(create: (_) => LocaleCubit()),
            BlocProvider(create: (_) => HomeFinancialVisibilityCubit()),
          ],
          child: HomePage(onNavigateToTab: navigatedTabs.add),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return navigatedTabs;
  }

  testWidgets('lista os próximos atendimentos agrupados por dia, sem card', (
    tester,
  ) async {
    await pumpHome(
      tester,
      appointments: [
        Appointment(
          id: 'a1',
          date: tomorrow,
          time: const TimeOfDay(hour: 10, minute: 4),
          patientName: 'Leandro',
        ),
        Appointment(
          id: 'a2',
          date: tomorrow,
          time: const TimeOfDay(hour: 11, minute: 0),
          patientName: 'Carlos',
          status: AppointmentStatus.confirmed,
        ),
      ],
    );

    expect(find.text('Próximos atendimentos'), findsOneWidget);
    expect(find.text('AMANHÃ'), findsOneWidget);
    expect(find.byType(AppTimeRow), findsNWidgets(2));
    expect(find.text('10:04'), findsOneWidget);
    expect(find.text('Leandro'), findsOneWidget);
    expect(find.text('Carlos'), findsOneWidget);
    // Status da Home continua sendo o ScheduleStatus derivado.
    expect(find.text('Próximo'), findsOneWidget);
    expect(find.text('Aguardando'), findsOneWidget);
    expect(find.text('Nenhum atendimento nos próximos 7 dias.'), findsNothing);
  });

  testWidgets('sem atendimentos mostra mensagem compacta e ação de agendar', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(
      find.text('Nenhum atendimento nos próximos 7 dias.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Agendar consulta'), findsOneWidget);
    expect(find.byType(AppTimeRow), findsNothing);
  });

  testWidgets('mostra métricas e a receita formatada em reais', (tester) async {
    await pumpHome(
      tester,
      patientCount: 3,
      entries: [
        FinancialEntry(
          id: 'f1',
          patientName: 'Maria',
          date: today,
          amount: 1450,
        ),
      ],
    );

    expect(find.text('Visão geral da clínica'), findsOneWidget);
    expect(find.text('Pacientes ativos'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('R\$ 1.450,00'), findsOneWidget);
  });

  testWidgets('o olho esconde e mostra a receita', (tester) async {
    await pumpHome(
      tester,
      entries: [
        FinancialEntry(
          id: 'f1',
          patientName: 'Maria',
          date: today,
          amount: 250,
        ),
      ],
    );

    expect(find.text('R\$ 250,00'), findsOneWidget);

    await tester.tap(find.byTooltip('Esconder valor'));
    await tester.pumpAndSettle();
    expect(find.text('R\$ 250,00'), findsNothing);
    expect(find.text('R\$ ••••'), findsOneWidget);

    await tester.tap(find.byTooltip('Mostrar valor'));
    await tester.pumpAndSettle();
    expect(find.text('R\$ 250,00'), findsOneWidget);
  });

  testWidgets('ações e atalhos navegam para as mesmas abas de antes', (
    tester,
  ) async {
    final tabs = await pumpHome(
      tester,
      appointments: [
        Appointment(
          id: 'a1',
          date: tomorrow,
          time: const TimeOfDay(hour: 9, minute: 0),
          patientName: 'Leandro',
        ),
      ],
    );

    await tester.tap(find.text('Ver agenda'));
    await tester.tap(find.text('Leandro'));
    await tester.ensureVisible(find.text('Registrar evolução'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar evolução'));
    await tester.tap(find.text('Lançar receita'));
    await tester.pump();

    expect(tabs, [2, 2, 1, 3]);
  });
}
