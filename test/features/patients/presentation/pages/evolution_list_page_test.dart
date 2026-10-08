// Testes de CARACTERIZAÇÃO da lista de evoluções: capturam comportamento e
// dados (ordem, texto completo, regra de "Editado em", navegação, reload,
// exclusão, empty e erro), não o visual. Servem para provar que a reforma
// visual da lista não perde informação nem fluxo.
//
// Os localizadores de ação aceitam a posição antiga e a nova (ex.: criar como
// FAB com texto ou como "+" com tooltip), porque o que se garante é o fluxo.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/app_language.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/patients/domain/entities/evolution_entry.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_repository.dart';
import 'package:la_pelve/features/patients/l10n/patients_strings.dart';
import 'package:la_pelve/features/patients/presentation/pages/evolution_list_page.dart';
import 'package:la_pelve/features/patients/presentation/widgets/evolution/evolution_timeline.dart';
import 'package:la_pelve/shared/widgets/app_confirm_sheet.dart';
import 'package:la_pelve/shared/widgets/app_info_bottom_sheet.dart';
import 'package:la_pelve/shared/widgets/app_error_state.dart';
import 'package:la_pelve/shared/widgets/app_empty_state.dart';

class _FakePatientRepository extends Mock implements PatientRepository {}

const _t = PatientsStrings(AppLanguage.portuguese);

EvolutionEntry _entry(
  String id,
  DateTime date,
  String description, {
  DateTime? updatedAt,
}) => EvolutionEntry(
  id: id,
  patientId: 'p1',
  date: date,
  description: description,
  updatedAt: updatedAt,
);

void main() {
  late _FakePatientRepository repository;
  late List<EvolutionEntry> stored;
  final patient = Patient(
    id: 'p1',
    createdAt: DateTime(2026, 1, 1),
    personalInfo: const PersonalInfo(name: 'Maria Teste'),
  );

  setUpAll(() {
    registerFallbackValue(_entry('x', DateTime(2026), 'x'));
  });

  setUp(() async {
    await sl.reset();
  });

  tearDown(() async => sl.reset());

  /// Monta a lista falsa ("LISTA") e empilha as evoluções por cima, como no app.
  /// As rotas de criar/editar são telas falsas com um botão VOLTAR.
  Future<void> pumpList(
    WidgetTester tester,
    List<EvolutionEntry> entries, {
    Result<List<EvolutionEntry>>? result,
    Size size = const Size(390, 4000),
    bool deleteFails = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    SharedPreferences.setMockInitialValues({});

    stored = [...entries];
    repository = _FakePatientRepository();
    when(
      () => repository.getEvolutions('p1'),
    ).thenAnswer((_) async => result ?? Success([...stored]));
    when(() => repository.deleteEvolution(any())).thenAnswer((
      invocation,
    ) async {
      if (deleteFails) return Error(ServerFailure('FALHA-EXCLUIR-X'));
      final id = invocation.positionalArguments.first as String;
      stored = stored.where((e) => e.id != id).toList();
      return const Success(null);
    });
    sl.registerSingleton<PatientRepository>(repository);

    Widget fakeForm(String label) => Scaffold(
      body: Builder(
        builder: (context) => Column(
          children: [
            Text(label),
            TextButton(onPressed: context.pop, child: const Text('VOLTAR')),
          ],
        ),
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('LISTA')),
        ),
        GoRoute(
          path: '/pacientes/:id/evolucao',
          builder: (_, state) =>
              EvolutionListPage(patient: state.extra! as Patient),
        ),
        GoRoute(
          path: '/pacientes/:id/evolucao/novo',
          builder: (_, _) => fakeForm('NOVA-EVOLUCAO'),
        ),
        GoRoute(
          path: '/pacientes/:id/evolucao/:entryId/editar',
          builder: (_, state) => fakeForm(
            'EDITAR ${state.pathParameters['entryId']} '
            '${(state.extra! as EvolutionEntry).description}',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider(
        key: UniqueKey(),
        create: (_) => LocaleCubit(),
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.push('/pacientes/p1/evolucao', extra: patient));
    await tester.pumpAndSettle();
  }

  Future<void> tapCreate(WidgetTester tester) async {
    final byTooltip = find.byTooltip(_t.newEvolutionButton);
    final target = byTooltip.evaluate().isNotEmpty
        ? byTooltip
        : find.text(_t.newEvolutionButton);
    await tester.tap(target.first);
    await tester.pumpAndSettle();
  }

  /// Abre a ação de excluir do item [index], esteja ela como lixeira fixa (UI
  /// antiga) ou atrás do botão "mais" + menu (UI nova).
  Future<void> tapDeleteOf(WidgetTester tester, int index) async {
    final trash = find.byTooltip(_t.deleteEvolutionTooltip);
    if (trash.evaluate().isNotEmpty) {
      await tester.ensureVisible(trash.at(index));
      await tester.tap(trash.at(index));
      await tester.pumpAndSettle();
      return;
    }
    final more = find.byTooltip(_t.moreOptionsTooltip);
    await tester.ensureVisible(more.at(index));
    await tester.tap(more.at(index));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_t.deleteEvolutionTitle));
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.text('VOLTAR'));
    await tester.pumpAndSettle();
  }

  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  group('conteúdo e ordenação', () {
    testWidgets('mostra as evoluções da mais nova para a mais antiga', (
      tester,
    ) async {
      // O repositório entrega em ordem crescente; a tela inverte.
      await pumpList(tester, [
        _entry('e1', DateTime(2026, 8, 10), 'ANTIGA-X'),
        _entry('e2', DateTime(2026, 8, 12), 'MEIO-X'),
        _entry('e3', DateTime(2026, 8, 13), 'NOVA-X'),
      ]);

      expect(top(tester, 'NOVA-X'), lessThan(top(tester, 'MEIO-X')));
      expect(top(tester, 'MEIO-X'), lessThan(top(tester, 'ANTIGA-X')));
    });

    testWidgets('ordena por date mesmo se o repositório entregar embaralhado', (
      tester,
    ) async {
      await pumpList(tester, [
        _entry('e2', DateTime(2026, 8, 12), 'MEIO-X'),
        _entry('e3', DateTime(2026, 8, 13), 'NOVA-X'),
        _entry('e1', DateTime(2026, 8, 10), 'ANTIGA-X'),
      ]);

      expect(top(tester, 'NOVA-X'), lessThan(top(tester, 'MEIO-X')));
      expect(top(tester, 'MEIO-X'), lessThan(top(tester, 'ANTIGA-X')));
    });

    testWidgets('cada evolução mostra a data dd/MM/yyyy', (tester) async {
      await pumpList(tester, [
        _entry('e1', DateTime(2026, 3, 5), 'A-X'),
        _entry('e2', DateTime(2026, 11, 20), 'B-X'),
      ]);

      expect(find.text('05/03/2026'), findsOneWidget);
      expect(find.text('20/11/2026'), findsOneWidget);
    });

    testWidgets('texto longo aparece inteiro, sem truncar', (tester) async {
      final long = List.filled(
        40,
        'Paciente relata melhora progressiva da dor pélvica',
      ).join(' ');
      await pumpList(tester, [_entry('e1', DateTime(2026, 8, 10), long)]);

      final text = tester.widget<Text>(find.text(long));
      expect(text.maxLines, isNull);
      expect(
        text.overflow == null || text.overflow == TextOverflow.clip,
        isTrue,
      );
    });

    testWidgets('várias evoluções na mesma data: todas presentes', (
      tester,
    ) async {
      await pumpList(tester, [
        _entry('e1', DateTime(2026, 8, 10), 'PRIMEIRA-X'),
        _entry('e2', DateTime(2026, 8, 10), 'SEGUNDA-X'),
        _entry('e3', DateTime(2026, 8, 10), 'TERCEIRA-X'),
        _entry('e4', DateTime(2026, 8, 9), 'OUTRO-DIA-X'),
      ]);

      // A ordem entre as empatadas NÃO é garantida (tie-break instável).
      expect(find.text('PRIMEIRA-X'), findsOneWidget);
      expect(find.text('SEGUNDA-X'), findsOneWidget);
      expect(find.text('TERCEIRA-X'), findsOneWidget);
      expect(find.text('OUTRO-DIA-X'), findsOneWidget);
      expect(
        top(tester, 'OUTRO-DIA-X'),
        greaterThan(top(tester, 'PRIMEIRA-X')),
      );
      expect(top(tester, 'OUTRO-DIA-X'), greaterThan(top(tester, 'SEGUNDA-X')));
      expect(
        top(tester, 'OUTRO-DIA-X'),
        greaterThan(top(tester, 'TERCEIRA-X')),
      );
    });
  });

  group('indicação de edição', () {
    testWidgets('sem updatedAt não mostra "Editado em"', (tester) async {
      await pumpList(tester, [_entry('e1', DateTime(2026, 8, 10), 'A-X')]);

      expect(find.textContaining('Editado em'), findsNothing);
    });

    testWidgets('com updatedAt mostra "Editado em dd/MM/yyyy"', (tester) async {
      await pumpList(tester, [
        _entry(
          'e1',
          DateTime(2026, 8, 10),
          'A-X',
          updatedAt: DateTime(2026, 8, 13, 9, 30),
        ),
      ]);

      expect(find.text('Editado em 13/08/2026'), findsOneWidget);
    });

    testWidgets('a regra vale por item, mesmo no mesmo dia da evolução', (
      tester,
    ) async {
      await pumpList(tester, [
        _entry('e1', DateTime(2026, 8, 10), 'A-X'),
        _entry(
          'e2',
          DateTime(2026, 8, 11),
          'B-X',
          updatedAt: DateTime(2026, 8, 11, 18),
        ),
      ]);

      expect(find.textContaining('Editado em'), findsOneWidget);
      expect(find.text('Editado em 11/08/2026'), findsOneWidget);
    });
  });

  group('criar', () {
    testWidgets('abre /novo e recarrega ao voltar', (tester) async {
      await pumpList(tester, [_entry('e1', DateTime(2026, 8, 10), 'A-X')]);
      verify(() => repository.getEvolutions('p1')).called(1);

      await tapCreate(tester);
      expect(find.text('NOVA-EVOLUCAO'), findsOneWidget);

      stored = [...stored, _entry('e2', DateTime(2026, 8, 11), 'CRIADA-X')];
      await back(tester);

      verify(() => repository.getEvolutions('p1')).called(1);
      expect(find.text('CRIADA-X'), findsOneWidget);
    });
  });

  group('editar', () {
    testWidgets('tocar na evolução abre a edição com o entry correto', (
      tester,
    ) async {
      await pumpList(tester, [
        _entry('e1', DateTime(2026, 8, 10), 'PRIMEIRA-X'),
        _entry('e2', DateTime(2026, 8, 12), 'SEGUNDA-X'),
      ]);

      await tester.tap(find.text('PRIMEIRA-X'));
      await tester.pumpAndSettle();

      expect(find.text('EDITAR e1 PRIMEIRA-X'), findsOneWidget);
    });

    testWidgets('voltar da edição recarrega a lista', (tester) async {
      await pumpList(tester, [_entry('e1', DateTime(2026, 8, 10), 'ANTES-X')]);
      verify(() => repository.getEvolutions('p1')).called(1);

      await tester.tap(find.text('ANTES-X'));
      await tester.pumpAndSettle();
      stored = [_entry('e1', DateTime(2026, 8, 10), 'DEPOIS-X')];
      await back(tester);

      verify(() => repository.getEvolutions('p1')).called(1);
      expect(find.text('DEPOIS-X'), findsOneWidget);
      expect(find.text('ANTES-X'), findsNothing);
    });
  });

  group('excluir', () {
    testWidgets('cancelar não exclui', (tester) async {
      await pumpList(tester, [_entry('e1', DateTime(2026, 8, 10), 'A-X')]);

      await tapDeleteOf(tester, 0);
      expect(find.byType(AppConfirmSheet), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AppConfirmSheet),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      verifyNever(() => repository.deleteEvolution(any()));
      expect(find.text('A-X'), findsOneWidget);
    });

    testWidgets('confirmar exclui o entry certo e recarrega', (tester) async {
      await pumpList(tester, [
        _entry('e1', DateTime(2026, 8, 10), 'ANTIGA-X'),
        _entry('e2', DateTime(2026, 8, 12), 'NOVA-X'),
      ]);

      // Índice 0 é a mais nova (e2) porque a tela ordena decrescente.
      await tapDeleteOf(tester, 0);
      expect(find.text(_t.deleteEvolutionTitle), findsWidgets);
      await tester.tap(
        find.descendant(
          of: find.byType(AppConfirmSheet),
          matching: find.text(_t.deleteLabel),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => repository.deleteEvolution('e2')).called(1);
      expect(find.text('NOVA-X'), findsNothing);
      expect(find.text('ANTIGA-X'), findsOneWidget);
    });

    testWidgets('excluir não abre a edição', (tester) async {
      await pumpList(tester, [_entry('e1', DateTime(2026, 8, 10), 'A-X')]);

      await tapDeleteOf(tester, 0);

      expect(find.textContaining('EDITAR'), findsNothing);
    });

    testWidgets('erro ao excluir mostra o feedback e mantém o item', (
      tester,
    ) async {
      await pumpList(tester, [
        _entry('e1', DateTime(2026, 8, 10), 'A-X'),
      ], deleteFails: true);

      await tapDeleteOf(tester, 0);
      await tester.tap(
        find.descendant(
          of: find.byType(AppConfirmSheet),
          matching: find.text(_t.deleteLabel),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => repository.deleteEvolution('e1')).called(1);
      expect(find.byType(AppInfoBottomSheet), findsOneWidget);
      expect(find.text('FALHA-EXCLUIR-X'), findsOneWidget);
      expect(find.text('A-X'), findsOneWidget);
    });
  });

  group('empty e erro', () {
    testWidgets('sem evoluções mostra título e mensagem do empty', (
      tester,
    ) async {
      await pumpList(tester, const []);

      expect(find.text(_t.evolutionEmptyTitle), findsOneWidget);
      expect(find.text(_t.evolutionEmptyMessage), findsOneWidget);
      expect(find.byType(EvolutionTimelineItem), findsNothing);
    });

    testWidgets('erro mostra a mensagem da falha e nenhuma evolução', (
      tester,
    ) async {
      await pumpList(
        tester,
        const [],
        result: Error(ServerFailure('FALHA-LISTA-X')),
      );

      expect(find.text('FALHA-LISTA-X'), findsOneWidget);
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.byType(EvolutionTimelineItem), findsNothing);
      // Erro não é "sem evoluções".
      expect(find.byType(AppEmptyState), findsNothing);
    });
  });
}
