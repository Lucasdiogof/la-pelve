import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/router/app_router.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/home/presentation/cubit/home_financial_visibility_cubit.dart';
import 'package:la_pelve/features/home/presentation/pages/home_page.dart';
import 'package:la_pelve/features/home/presentation/pages/home_shell_page.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/shared/widgets/app_loading_widget.dart';

import '../../../../core/session/session_test_support.dart';

void main() {
  late SessionHarness h;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    h = SessionHarness();
  });
  tearDown(() => h.close());

  Future<void> pump(WidgetTester tester, Widget child) async {
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
          child: child,
        ),
      ),
    );
  }

  testWidgets('Home sem a primeira carga não renderiza números falsos', (
    tester,
  ) async {
    // Nenhum ensureLoaded: dados ainda não carregados.
    await pump(tester, HomePage(onNavigateToTab: (_) {}));
    await tester.pump();

    expect(find.byType(AppLoadingWidget), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.text('Nenhum atendimento agendado.'), findsNothing);
    expect(find.textContaining(r'R$'), findsNothing);
  });

  testWidgets('trocar de aba não dispara recarga', (tester) async {
    await h.controller.ensureLoaded();
    await pump(tester, const HomeShellPage());
    await tester.pumpAndSettle();
    final before = (h.patientCalls, h.agendaCalls, h.financialCalls);

    for (final label in ['Pacientes', 'Agenda', 'Financeiro', 'Início']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    expect((h.patientCalls, h.agendaCalls, h.financialCalls), before);
  });

  testWidgets('voltar do background revalida mantendo os dados na tela', (
    tester,
  ) async {
    h.patientsAnswer = () async =>
        Success([patientNamed('p1', 'Ana'), patientNamed('p2', 'Bia')]);
    await h.controller.ensureLoaded();
    await pump(tester, HomePage(onNavigateToTab: (_) {}));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);

    final pending = Completer<Result<List<Patient>>>();
    h.patientsAnswer = pendingAnswer(pending);
    final binding = tester.binding;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(h.patientCalls, 2, reason: 'revalidou ao voltar');
    expect(find.byType(AppLoadingWidget), findsNothing);
    expect(find.text('2'), findsOneWidget, reason: 'dados antigos visíveis');

    // A revalidação falha: os dados continuam.
    pending.complete(Error(NetworkFailure()));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
  });

  group('authRedirect', () {
    test('sem sessão, a área logada leva ao login', () {
      for (final location in [
        '/home',
        '/pacientes/novo',
        '/agenda/novo',
        '/perfil',
      ]) {
        expect(authRedirect(hasSession: false, location: location), '/');
      }
    });

    test('sem sessão, login/cadastro/redefinir senha seguem normais', () {
      for (final location in publicRoutes) {
        expect(authRedirect(hasSession: false, location: location), isNull);
      }
    });

    test('sessão restaurada no cold start abre a Home', () {
      expect(authRedirect(hasSession: true, location: '/'), '/home');
      expect(authRedirect(hasSession: true, location: '/home'), isNull);
    });
  });
}
