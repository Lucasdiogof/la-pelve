import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/session/session_data_gate.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/home/presentation/cubit/home_financial_visibility_cubit.dart';
import 'package:la_pelve/features/home/presentation/pages/home_page.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/shared/widgets/app_error_state.dart';
import 'package:la_pelve/shared/widgets/pulsing_logo.dart';

import 'session_test_support.dart';

void main() {
  late SessionHarness h;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    h = SessionHarness();
  });
  tearDown(() => h.close());

  /// Gate com a Home real dentro (como na rota /home).
  Future<void> pumpGate(WidgetTester tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: h.controller.patients),
            BlocProvider.value(value: h.controller.agenda),
            BlocProvider.value(value: h.controller.financial),
            BlocProvider.value(value: h.controller.profile),
            BlocProvider(create: (_) => LocaleCubit()),
            BlocProvider(create: (_) => HomeFinancialVisibilityCubit()),
          ],
          child: SessionDataGate(
            controller: h.controller,
            child: HomePage(onNavigateToTab: (_) {}),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'cold start/login: loading até tudo carregar; a Home nunca aparece com '
    'zeros ou "sem atendimentos" falsos',
    (tester) async {
      final patients = Completer<Result<List<Patient>>>();
      final financial = Completer<Result<List<FinancialEntry>>>();
      h.patientsAnswer = pendingAnswer(patients);
      h.financialAnswer = pendingAnswer(financial);

      await pumpGate(tester);
      await tester.pump();

      expect(find.byType(PulsingLogo), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      expect(find.text('Nenhum atendimento agendado.'), findsNothing);
      expect(find.text('0'), findsNothing);

      patients.complete(
        Success([patientNamed('p1', 'Ana'), patientNamed('p2', 'Bia')]),
      );
      await tester.pump();
      // Ainda falta o financeiro: continua no loading.
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(PulsingLogo), findsOneWidget);

      financial.complete(const Success([]));
      await tester.pump();
      await tester.pump();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(PulsingLogo), findsNothing);
      // Já na primeira renderização: 2 pacientes reais.
      expect(find.text('2'), findsOneWidget);
    },
  );

  testWidgets('falha de uma fonte crítica: erro + tentar novamente, nunca '
      'clínica vazia; o retry libera a Home', (tester) async {
    h.agendaAnswer = () async => Error(NetworkFailure());
    await pumpGate(tester);
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('Não foi possível carregar sua clínica'), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    expect(find.text('Nenhum atendimento agendado.'), findsNothing);

    h.agendaAnswer = () async => const Success([]);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorState), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    // Só a agenda (que falhou) foi buscada de novo.
    expect((h.patientCalls, h.agendaCalls, h.financialCalls), (1, 2, 1));
  });

  testWidgets(
    'logout e login de outra conta: nenhum frame mostra dados da conta A',
    (tester) async {
      h.patientsAnswer = () async => Success([
        patientNamed('a1', 'A'),
        patientNamed('a2', 'A'),
        patientNamed('a3', 'A'),
      ]);
      h.controller.onSessionUser('user-a');
      await pumpGate(tester);
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget); // 3 pacientes da conta A

      // Logout.
      h.controller.onSessionUser(null);
      await tester.pump();
      expect(find.byType(HomePage), findsNothing);
      expect(find.text('3'), findsNothing);

      // Conta B entra; a carga dela demora.
      final patientsB = Completer<Result<List<Patient>>>();
      h.patientsAnswer = pendingAnswer(patientsB);
      h.controller.onSessionUser('user-b');
      unawaited(h.controller.ensureLoaded());
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('3'), findsNothing, reason: 'frame $i');
        expect(find.byType(HomePage), findsNothing, reason: 'frame $i');
      }

      patientsB.complete(Success([patientNamed('b1', 'B')]));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsNothing);
    },
  );
}
