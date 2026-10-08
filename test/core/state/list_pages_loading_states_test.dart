import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:la_pelve/features/agenda/presentation/pages/agenda_page.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:la_pelve/features/financial/presentation/widgets/payments_tab.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/features/patients/presentation/pages/patients_list_page.dart';
import 'package:la_pelve/shared/widgets/app_empty_state.dart';
import 'package:la_pelve/shared/widgets/app_error_state.dart';
import 'package:la_pelve/shared/widgets/app_loading_widget.dart';

import '../session/session_test_support.dart';

/// Regra comum às listas principais: loading inicial != vazio, erro !=
/// vazio, refresh != vazio. Cada cenário é rodado nas três telas.
void main() {
  Widget app(Widget child, List<BlocProvider> providers) {
    return MaterialApp(
      theme: AppTheme.light,
      home: MultiBlocProvider(
        providers: [
          ...providers,
          BlocProvider(create: (_) => LocaleCubit()),
        ],
        child: Scaffold(body: child),
      ),
    );
  }

  final appointment = Appointment(
    id: 'a1',
    date: DateTime.now().add(const Duration(days: 1)),
    time: const TimeOfDay(hour: 10, minute: 0),
    patientName: 'Ana Souza',
  );
  final entry = FinancialEntry(
    id: 'f1',
    patientName: 'Ana Souza',
    date: DateTime.now(),
    amount: 150,
  );

  Future<void> runScenario(
    WidgetTester tester, {
    required Widget page,
    required List<BlocProvider> providers,
  }) async {
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    await tester.pumpWidget(app(page, providers));
  }

  // Patients ----------------------------------------------------------------
  group('Pacientes', () {
    late MockPatientRepository repository;
    late PatientsCubit cubit;
    setUp(() {
      repository = MockPatientRepository();
      cubit = PatientsCubit(repository);
    });
    tearDown(() => cubit.close());

    Future<void> pump(WidgetTester tester) => runScenario(
      tester,
      page: const PatientsListPage(),
      providers: [BlocProvider<PatientsCubit>.value(value: cubit)],
    );

    testWidgets('carregando: loading, nunca o "sem pacientes"', (tester) async {
      final pending = Completer<Result<List<Patient>>>();
      when(() => repository.getAll()).thenAnswer((_) => pending.future);
      unawaited(cubit.ensureLoaded());
      await pump(tester);
      await tester.pump();

      expect(find.byType(AppLoadingWidget), findsOneWidget);
      expect(find.byType(AppEmptyState), findsNothing);

      pending.complete(const Success([]));
      await tester.pumpAndSettle();
      expect(find.byType(AppEmptyState), findsOneWidget);
    });

    testWidgets('falha inicial: erro + retry, não vazio', (tester) async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => Error(NetworkFailure()));
      await cubit.ensureLoaded();
      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.byType(AppEmptyState), findsNothing);

      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => Success([patientNamed('p1', 'Ana Souza')]));
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.byType(AppErrorState), findsNothing);
    });

    testWidgets('refresh que falha mantém a lista e avisa', (tester) async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => Success([patientNamed('p1', 'Ana Souza')]));
      await cubit.ensureLoaded();
      await pump(tester);
      await tester.pumpAndSettle();

      final pending = Completer<Result<List<Patient>>>();
      when(() => repository.getAll()).thenAnswer((_) => pending.future);
      await tester.fling(find.text('Ana Souza'), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      // Durante a atualização a lista continua.
      expect(find.text('Ana Souza'), findsOneWidget);

      pending.complete(Error(NetworkFailure()));
      await tester.pumpAndSettle();
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.byType(AppEmptyState), findsNothing);
      expect(
        find.text(
          'Não foi possível atualizar. Mostrando os últimos dados carregados.',
        ),
        findsOneWidget,
      );
    });
  });

  // Agenda ------------------------------------------------------------------
  group('Agenda', () {
    late MockAgendaRepository repository;
    late AgendaCubit cubit;
    setUp(() {
      repository = MockAgendaRepository();
      cubit = AgendaCubit(repository);
    });
    tearDown(() => cubit.close());

    Future<void> pump(WidgetTester tester) => runScenario(
      tester,
      page: const AgendaPage(),
      providers: [BlocProvider<AgendaCubit>.value(value: cubit)],
    );

    testWidgets('carregando: loading, nunca o "sem agendamentos"', (
      tester,
    ) async {
      final pending = Completer<Result<List<Appointment>>>();
      when(() => repository.getAll()).thenAnswer((_) => pending.future);
      unawaited(cubit.ensureLoaded());
      await pump(tester);
      await tester.pump();

      expect(find.byType(AppLoadingWidget), findsOneWidget);
      expect(find.byType(AppEmptyState), findsNothing);

      pending.complete(Success([appointment]));
      await tester.pumpAndSettle();
      expect(find.text('Ana Souza'), findsOneWidget);
    });

    testWidgets('falha inicial: erro + retry, não vazio', (tester) async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => Error(ServerFailure()));
      await cubit.ensureLoaded();
      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.byType(AppEmptyState), findsNothing);
    });
  });

  // Financeiro --------------------------------------------------------------
  group('Financeiro', () {
    late MockFinancialRepository repository;
    late FinancialCubit cubit;
    setUp(() {
      repository = MockFinancialRepository();
      cubit = FinancialCubit(repository);
    });
    tearDown(() => cubit.close());

    Future<void> pump(WidgetTester tester) => runScenario(
      tester,
      page: const PaymentsTab(),
      providers: [BlocProvider<FinancialCubit>.value(value: cubit)],
    );

    testWidgets('carregando: loading, nunca o "sem pagamentos"', (
      tester,
    ) async {
      final pending = Completer<Result<List<FinancialEntry>>>();
      when(() => repository.getAll()).thenAnswer((_) => pending.future);
      unawaited(cubit.ensureLoaded());
      await pump(tester);
      await tester.pump();

      expect(find.byType(AppLoadingWidget), findsOneWidget);
      expect(find.byType(AppEmptyState), findsNothing);

      pending.complete(Success([entry]));
      await tester.pumpAndSettle();
      expect(find.text('Ana Souza'), findsOneWidget);
    });

    testWidgets('falha inicial: erro + retry, não vazio', (tester) async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => Error(NetworkFailure()));
      await cubit.ensureLoaded();
      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.byType(AppEmptyState), findsNothing);
    });
  });
}
