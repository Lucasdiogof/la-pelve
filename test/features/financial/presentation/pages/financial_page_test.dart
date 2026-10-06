// Testes de fechamento da reforma visual do Financeiro principal: cobrem só
// o essencial de fluxo da página (ação "+", ausência do FAB antigo, abas),
// não o visual pixel a pixel (isso já foi validado via preview).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/app_language.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/financial/domain/repositories/financial_repository.dart';
import 'package:la_pelve/features/financial/l10n/financial_strings.dart';
import 'package:la_pelve/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:la_pelve/features/financial/presentation/pages/financial_page.dart';

class _FakeFinancialRepository extends Mock implements FinancialRepository {}

const _t = FinancialStrings(AppLanguage.portuguese);

void main() {
  late _FakeFinancialRepository repository;

  Future<void> pumpPage(WidgetTester tester, {List<FinancialEntry>? entries}) async {
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    repository = _FakeFinancialRepository();
    when(
      () => repository.getAll(),
    ).thenAnswer((_) async => Success(entries ?? const []));

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const FinancialPage()),
        GoRoute(
          path: '/financeiro/novo',
          builder: (_, _) => const Scaffold(body: Text('NOVO-LANCAMENTO')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => FinancialCubit(repository)),
          BlocProvider(create: (_) => LocaleCubit()),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('o botão "+" do AppBar abre /financeiro/novo', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('NOVO-LANCAMENTO'), findsOneWidget);
  });

  testWidgets('não existe mais FloatingActionButton', (tester) async {
    await pumpPage(tester);

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(FloatingActionButton).evaluate(), isEmpty);
  });

  testWidgets('as abas Lançamentos e Relatório trocam de conteúdo', (
    tester,
  ) async {
    await pumpPage(
      tester,
      entries: [
        FinancialEntry(
          id: 'f1',
          patientName: 'Maria',
          date: DateTime(2026, 10, 5),
          amount: 100,
        ),
      ],
    );

    expect(find.text(_t.totalReceived), findsNothing);

    await tester.tap(find.text(_t.reportTab));
    await tester.pumpAndSettle();

    expect(find.text(_t.totalReceived), findsOneWidget);

    await tester.tap(find.text(_t.paymentsTab));
    await tester.pumpAndSettle();

    expect(find.text(_t.totalReceived), findsNothing);
  });
}
