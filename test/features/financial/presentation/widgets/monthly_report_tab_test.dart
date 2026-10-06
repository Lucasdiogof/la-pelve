// Testes de fechamento do Relatório financeiro: cálculo (só "paid", só do
// mês selecionado), navegação de mês (inclusive virada de ano), mês vazio e
// ausência de métricas extras além de "Total recebido".

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_enums.dart';
import 'package:la_pelve/features/financial/domain/repositories/financial_repository.dart';
import 'package:la_pelve/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:la_pelve/features/financial/presentation/widgets/monthly_report_tab.dart';

class _FakeFinancialRepository extends Mock implements FinancialRepository {}

void main() {
  Future<void> pumpReport(
    WidgetTester tester,
    List<FinancialEntry> entries,
  ) async {
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final repository = _FakeFinancialRepository();
    when(
      () => repository.getAll(),
    ).thenAnswer((_) async => Success(entries));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => FinancialCubit(repository)),
          BlocProvider(create: (_) => LocaleCubit()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: MonthlyReportTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final now = DateTime.now();

  testWidgets('total considera somente entradas pagas', (tester) async {
    await pumpReport(tester, [
      FinancialEntry(
        id: 'f1',
        patientName: 'Paga',
        date: DateTime(now.year, now.month, 1),
        amount: 100,
        status: PaymentStatus.paid,
      ),
      FinancialEntry(
        id: 'f2',
        patientName: 'Pendente',
        date: DateTime(now.year, now.month, 2),
        amount: 500,
        status: PaymentStatus.pending,
      ),
      FinancialEntry(
        id: 'f3',
        patientName: 'Parcial',
        date: DateTime(now.year, now.month, 3),
        amount: 300,
        status: PaymentStatus.partial,
      ),
    ]);

    expect(find.text('R\$ 100,00'), findsOneWidget);
  });

  testWidgets('considera somente entradas do mês selecionado', (
    tester,
  ) async {
    final previousMonth = DateTime(now.year, now.month - 1, 1);
    await pumpReport(tester, [
      FinancialEntry(
        id: 'f1',
        patientName: 'DoMesAtual',
        date: DateTime(now.year, now.month, 1),
        amount: 100,
        status: PaymentStatus.paid,
      ),
      FinancialEntry(
        id: 'f2',
        patientName: 'DoMesPassado',
        date: previousMonth,
        amount: 999,
        status: PaymentStatus.paid,
      ),
    ]);

    expect(find.text('R\$ 100,00'), findsOneWidget);
    expect(find.text('R\$ 999,00'), findsNothing);
  });

  testWidgets('mudar de mês recalcula o total e preserva a navegação', (
    tester,
  ) async {
    final previousMonth = DateTime(now.year, now.month - 1, 1);
    await pumpReport(tester, [
      FinancialEntry(
        id: 'f1',
        patientName: 'Atual',
        date: DateTime(now.year, now.month, 1),
        amount: 100,
        status: PaymentStatus.paid,
      ),
      FinancialEntry(
        id: 'f2',
        patientName: 'Passado',
        date: previousMonth,
        amount: 50,
        status: PaymentStatus.paid,
      ),
    ]);

    expect(find.text('R\$ 100,00'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('R\$ 50,00'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('R\$ 100,00'), findsOneWidget);
  });

  testWidgets('virada de ano: janeiro volta para dezembro do ano anterior', (
    tester,
  ) async {
    final previousDecember = DateTime(now.year - 1, 12, 20);
    await pumpReport(tester, [
      FinancialEntry(
        id: 'f1',
        patientName: 'Dezembro',
        date: previousDecember,
        amount: 70,
        status: PaymentStatus.paid,
      ),
    ]);

    // Navega para trás, mês a mês, até janeiro do ano atual.
    final monthsBackToJanuary = now.month - 1;
    for (var i = 0; i < monthsBackToJanuary; i++) {
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
    }
    expect(find.text('Janeiro de ${now.year}'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('Dezembro de ${now.year - 1}'), findsOneWidget);
    expect(find.text('R\$ 70,00'), findsOneWidget);
  });

  testWidgets('mês sem pagamentos mostra R\$ 0,00', (tester) async {
    await pumpReport(tester, const []);

    expect(find.text('R\$ 0,00'), findsOneWidget);
  });

  testWidgets('exibe o período do mês (dia 1 ao último dia)', (
    tester,
  ) async {
    await pumpReport(tester, const []);

    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    expect(
      find.text('Período: ${fmt(firstDay)} a ${fmt(lastDay)}'),
      findsOneWidget,
    );
  });

  testWidgets('não mostra métricas além de "Total recebido"', (
    tester,
  ) async {
    await pumpReport(tester, [
      FinancialEntry(
        id: 'f1',
        patientName: 'Maria',
        date: DateTime(now.year, now.month, 1),
        amount: 100,
        status: PaymentStatus.paid,
      ),
      FinancialEntry(
        id: 'f2',
        patientName: 'Joana',
        date: DateTime(now.year, now.month, 2),
        amount: 50,
        status: PaymentStatus.pending,
      ),
    ]);

    expect(find.text('Total recebido'), findsOneWidget);
    expect(find.textContaining('Pendente'), findsNothing);
    expect(find.textContaining('Parcial'), findsNothing);
    expect(find.textContaining('pagamentos'), findsNothing);
    expect(find.textContaining('Saldo'), findsNothing);
  });
}
