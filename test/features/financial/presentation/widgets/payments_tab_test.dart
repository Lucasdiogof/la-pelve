// Testes de fechamento da reforma visual do Financeiro: ordenação,
// agrupamento por mês, navegação, pull-to-refresh, empty, badges, fallback
// de nome e a variante responsiva da row. Não são testes de pixel.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_enums.dart';
import 'package:la_pelve/features/financial/domain/repositories/financial_repository.dart';
import 'package:la_pelve/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:la_pelve/features/financial/presentation/widgets/payments_tab.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';
import 'package:la_pelve/shared/widgets/app_status_badge.dart';

class _FakeFinancialRepository extends Mock implements FinancialRepository {}

void main() {
  late _FakeFinancialRepository repository;
  late List<FinancialEntry> stored;

  Future<void> pumpTab(
    WidgetTester tester,
    List<FinancialEntry> entries, {
    Size size = const Size(390, 1600),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    stored = [...entries];
    repository = _FakeFinancialRepository();
    when(
      () => repository.getAll(),
    ).thenAnswer((_) async => Success([...stored]));

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: PaymentsTab())),
        GoRoute(
          path: '/financeiro/novo',
          builder: (_, _) => const Scaffold(body: Text('NOVO-LANCAMENTO')),
        ),
        GoRoute(
          path: '/financeiro/:id/editar',
          builder: (_, state) => Scaffold(
            body: Text(
              'EDITAR ${(state.extra! as FinancialEntry).id}',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => FinancialCubit(repository)..ensureLoaded()),
          BlocProvider(create: (_) => LocaleCubit()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  group('ordenação e agrupamento', () {
    testWidgets('mantém ordem date DESC dentro e entre os meses', (
      tester,
    ) async {
      await pumpTab(tester, [
        FinancialEntry(
          id: 'f1',
          patientName: 'Antiga',
          date: DateTime(2026, 9, 10),
          amount: 100,
        ),
        FinancialEntry(
          id: 'f2',
          patientName: 'MaisNova',
          date: DateTime(2026, 10, 20),
          amount: 100,
        ),
        FinancialEntry(
          id: 'f3',
          patientName: 'MeioOutubro',
          date: DateTime(2026, 10, 5),
          amount: 100,
        ),
      ]);

      expect(top(tester, 'MaisNova'), lessThan(top(tester, 'MeioOutubro')));
      expect(top(tester, 'MeioOutubro'), lessThan(top(tester, 'Antiga')));
    });

    testWidgets('agrupa visualmente em um painel por mês', (tester) async {
      await pumpTab(tester, [
        FinancialEntry(
          id: 'f1',
          patientName: 'Outubro1',
          date: DateTime(2026, 10, 3),
          amount: 100,
        ),
        FinancialEntry(
          id: 'f2',
          patientName: 'Outubro2',
          date: DateTime(2026, 10, 1),
          amount: 100,
        ),
        FinancialEntry(
          id: 'f3',
          patientName: 'Setembro1',
          date: DateTime(2026, 9, 15),
          amount: 100,
        ),
      ]);

      expect(find.byType(AppSection), findsNWidgets(2));
      expect(find.text('OUTUBRO DE 2026'), findsOneWidget);
      expect(find.text('SETEMBRO DE 2026'), findsOneWidget);
    });
  });

  group('navegação', () {
    testWidgets('tocar na row abre a edição com o entry correto', (
      tester,
    ) async {
      await pumpTab(tester, [
        FinancialEntry(
          id: 'f1',
          patientName: 'Primeira',
          date: DateTime(2026, 10, 10),
          amount: 100,
        ),
        FinancialEntry(
          id: 'f2',
          patientName: 'Segunda',
          date: DateTime(2026, 10, 5),
          amount: 100,
        ),
      ]);

      await tester.tap(find.text('Segunda'));
      await tester.pumpAndSettle();

      expect(find.text('EDITAR f2'), findsOneWidget);
    });
  });

  group('pull-to-refresh', () {
    testWidgets('arrastar para baixo chama reload do cubit', (tester) async {
      await pumpTab(tester, [
        FinancialEntry(
          id: 'f1',
          patientName: 'Maria',
          date: DateTime(2026, 10, 10),
          amount: 100,
        ),
      ]);
      verify(() => repository.getAll()).called(1);

      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 500),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      verify(() => repository.getAll()).called(1);
    });
  });

  group('empty state', () {
    testWidgets('sem lançamentos mostra ação "Registrar cobrança"', (
      tester,
    ) async {
      await pumpTab(tester, const []);

      final actionFinder = find.widgetWithText(OutlinedButton, 'Registrar cobrança');
      expect(actionFinder, findsOneWidget);

      await tester.tap(actionFinder);
      await tester.pumpAndSettle();

      expect(find.text('NOVO-LANCAMENTO'), findsOneWidget);
    });
  });

  group('status', () {
    testWidgets('cada status usa o tom semântico correto', (tester) async {
      await pumpTab(tester, [
        FinancialEntry(
          id: 'f1',
          patientName: 'Paga',
          date: DateTime(2026, 10, 1),
          amount: 100,
          status: PaymentStatus.paid,
        ),
        FinancialEntry(
          id: 'f2',
          patientName: 'Pendente',
          date: DateTime(2026, 10, 2),
          amount: 100,
          status: PaymentStatus.pending,
        ),
        FinancialEntry(
          id: 'f3',
          patientName: 'ParcialEntry',
          date: DateTime(2026, 10, 3),
          amount: 100,
          status: PaymentStatus.partial,
        ),
        FinancialEntry(
          id: 'f4',
          patientName: 'OutraEntry',
          date: DateTime(2026, 10, 4),
          amount: 100,
          status: PaymentStatus.other,
        ),
      ]);

      AppStatusTone toneOf(String label) => tester
          .widget<AppStatusBadge>(
            find.ancestor(
              of: find.text(label),
              matching: find.byType(AppStatusBadge),
            ),
          )
          .tone;

      expect(toneOf('Pago'), AppStatusTone.success);
      expect(toneOf('Pendente'), AppStatusTone.warning);
      expect(toneOf('Parcial'), AppStatusTone.primary);
      expect(toneOf('Outro'), AppStatusTone.muted);
    });
  });

  group('nome do paciente', () {
    testWidgets('nome vazio usa o fallback "Sem nome"', (tester) async {
      await pumpTab(tester, [
        FinancialEntry(
          id: 'f1',
          patientName: '',
          date: DateTime(2026, 10, 1),
          amount: 100,
        ),
      ]);

      expect(find.text('Sem nome'), findsOneWidget);
    });

    testWidgets('nome longo aparece inteiro, sem reticências', (
      tester,
    ) async {
      const longName = 'Maria Aparecida Fernandes de Albuquerque Souza';
      await pumpTab(tester, [
        FinancialEntry(
          id: 'f1',
          patientName: longName,
          date: DateTime(2026, 10, 1),
          amount: 100,
        ),
      ]);

      final text = tester.widget<Text>(find.text(longName));
      expect(
        text.overflow == null || text.overflow == TextOverflow.clip,
        isTrue,
      );
      expect(find.textContaining('…'), findsNothing);
    });
  });

  group('responsivo', () {
    testWidgets('390px normal usa o layout lado a lado (nome e valor na mesma linha)', (
      tester,
    ) async {
      await pumpTab(tester, [
        FinancialEntry(
          id: 'f1',
          patientName: 'Maria',
          date: DateTime(2026, 10, 1),
          amount: 180,
        ),
      ]);

      expect(top(tester, 'Maria'), top(tester, 'R\$ 180,00'));
    });

    testWidgets('360px com textScale 1.3 empilha nome e valor', (
      tester,
    ) async {
      const longName = 'Maria Aparecida Fernandes de Albuquerque Souza';
      await pumpTab(
        tester,
        [
          FinancialEntry(
            id: 'f1',
            patientName: longName,
            date: DateTime(2026, 10, 1),
            amount: 180,
          ),
        ],
        size: const Size(360, 1600),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
      expect(top(tester, longName), lessThan(top(tester, 'R\$ 180,00')));
      expect(find.textContaining('…'), findsNothing);
    });

    testWidgets('valor grande não colide com nome longo em 360/1.3', (
      tester,
    ) async {
      const longName = 'Maria Aparecida Fernandes de Albuquerque Souza';
      await pumpTab(
        tester,
        [
          FinancialEntry(
            id: 'f1',
            patientName: longName,
            date: DateTime(2026, 10, 1),
            amount: 12500,
          ),
        ],
        size: const Size(360, 1600),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('R\$ 12.500,00'), findsOneWidget);
    });
  });
}
