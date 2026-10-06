// Testes da REFORMA VISUAL da lista de evoluções: AppBar com paciente e "+",
// sem FAB, loading, empty com ação, painel único com timeline, agrupamento por
// data, exclusão neutra e independente, e telas pequenas com texto grande.
//
// Carregam a Poppins REAL do app. O comportamento (ordem, regras, fluxos) está
// em evolution_list_page_test.dart (caracterização).

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/app_language.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/patients/domain/entities/evolution_entry.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_repository.dart';
import 'package:la_pelve/features/patients/l10n/patients_strings.dart';
import 'package:la_pelve/features/patients/presentation/pages/evolution_list_page.dart';
import 'package:la_pelve/features/patients/presentation/widgets/evolution/evolution_timeline.dart';
import 'package:la_pelve/shared/widgets/app_confirm_sheet.dart';
import 'package:la_pelve/shared/widgets/app_empty_state.dart';

class _FakePatientRepository extends Mock implements PatientRepository {}

const _t = PatientsStrings(AppLanguage.portuguese);
const _longName = 'Maria Aparecida Fernandes de Albuquerque Souza';
const _longText =
    'Paciente relata melhora progressiva da dor pélvica após as últimas '
    'sessões, com redução da urgência urinária noturna, boa adesão aos '
    'exercícios domiciliares e tolerância adequada à cinesioterapia, sem '
    'queixas de desconforto durante ou após o atendimento.';

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
  final patient = Patient(
    id: 'p1',
    createdAt: DateTime(2026, 1, 1),
    personalInfo: const PersonalInfo(name: _longName),
  );

  setUpAll(() async {
    final poppins = FontLoader('Poppins');
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      poppins.addFont(
        Future.value(
          ByteData.sublistView(
            Uint8List.fromList(
              File(
                'lib/assets/google_fonts/Poppins-$weight.ttf',
              ).readAsBytesSync(),
            ),
          ),
        ),
      );
    }
    await poppins.load();
  });

  setUp(() async => sl.reset());
  tearDown(() async => sl.reset());

  late _FakePatientRepository repository;

  Future<void> pumpList(
    WidgetTester tester,
    List<EvolutionEntry> entries, {
    Size size = const Size(390, 4000),
    double textScale = 1,
    bool dark = false,
    Completer<Result<List<EvolutionEntry>>>? pending,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    SharedPreferences.setMockInitialValues({});

    repository = _FakePatientRepository();
    when(() => repository.getEvolutions('p1')).thenAnswer(
      (_) => pending != null
          ? pending.future
          : Future.value(Success([...entries])),
    );
    when(
      () => repository.deleteEvolution(any()),
    ).thenAnswer((_) async => const Success(null));
    sl.registerSingleton<PatientRepository>(repository);

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
          builder: (_, _) => const Scaffold(body: Text('NOVA-EVOLUCAO')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider(
        key: UniqueKey(),
        create: (_) => LocaleCubit(),
        child: MaterialApp.router(
          theme: dark ? AppTheme.dark : AppTheme.light,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
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
    unawaited(router.push('/pacientes/p1/evolucao', extra: patient));
    if (pending != null) {
      await tester.pump();
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
  }

  List<EvolutionEntry> many(int n) => [
    for (var i = 0; i < n; i++)
      _entry(
        'e$i',
        DateTime(2026, 1, 1).add(Duration(days: i)),
        'Evolução número $i. $_longText',
        updatedAt: i.isEven ? DateTime(2026, 8, 13) : null,
      ),
  ];

  group('AppBar e criação', () {
    testWidgets('mostra "Evoluções" e o nome completo do paciente', (
      tester,
    ) async {
      await pumpList(
        tester,
        many(1),
        size: const Size(360, 800),
        textScale: 1.3,
      );

      expect(find.text(_t.evolutionsPageTitle), findsOneWidget);
      final name = find.text(_longName);
      expect(name, findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(name).didExceedMaxLines,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tem "+" com tooltip e não tem FAB', (tester) async {
      await pumpList(tester, many(1));

      expect(find.byTooltip(_t.newEvolutionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('"+" abre /novo', (tester) async {
      await pumpList(tester, many(1));

      await tester.tap(find.byTooltip(_t.newEvolutionButton));
      await tester.pumpAndSettle();

      expect(find.text('NOVA-EVOLUCAO'), findsOneWidget);
    });
  });

  group('loading e empty', () {
    testWidgets('enquanto carrega mostra loading, não o empty', (tester) async {
      final pending = Completer<Result<List<EvolutionEntry>>>();
      await pumpList(tester, const [], pending: pending);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(_t.evolutionEmptyTitle), findsNothing);

      pending.complete(const Success([]));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(_t.evolutionEmptyTitle), findsOneWidget);
    });

    testWidgets('empty tem a ação "Nova evolução" com o mesmo fluxo do "+"', (
      tester,
    ) async {
      await pumpList(tester, const []);

      final action = find.descendant(
        of: find.byType(AppEmptyState),
        matching: find.text(_t.newEvolutionButton),
      );
      expect(action, findsOneWidget);
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(find.text('NOVA-EVOLUCAO'), findsOneWidget);
    });
  });

  group('timeline', () {
    testWidgets('um painel único para o histórico inteiro, sem card por item', (
      tester,
    ) async {
      await pumpList(tester, many(5));

      expect(find.byType(EvolutionTimeline), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      final surfaces = tester
          .widgetList<Material>(
            find.descendant(
              of: find.byType(EvolutionTimeline),
              matching: find.byType(Material),
            ),
          )
          .where((m) => m.shape is RoundedRectangleBorder && m.color != null);
      expect(surfaces.length, 1);
    });

    testWidgets('um marcador por data e linha ligando os marcadores', (
      tester,
    ) async {
      await pumpList(tester, many(4));

      final markers = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).shape == BoxShape.circle,
      );
      expect(markers, findsNWidgets(4));
      final lines = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 1 && w.child is ColoredBox,
      );
      // Um segmento por data, ligando cada marcador ao anterior/seguinte.
      expect(lines, findsNWidgets(4));
    });

    testWidgets('uma única evolução: marcador sem linha', (tester) async {
      await pumpList(tester, many(1));

      final lines = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 1 && w.child is ColoredBox,
      );
      expect(lines, findsNothing);
    });

    testWidgets('mesma data compartilha um único marcador e cabeçalho', (
      tester,
    ) async {
      await pumpList(tester, [
        _entry('e1', DateTime(2026, 8, 10), 'PRIMEIRA-X'),
        _entry('e2', DateTime(2026, 8, 10), 'SEGUNDA-X'),
        _entry('e3', DateTime(2026, 8, 10), 'TERCEIRA-X'),
        _entry('e4', DateTime(2026, 8, 9), 'OUTRO-DIA-X'),
      ]);

      expect(find.text('10/08/2026'), findsOneWidget);
      expect(find.text('09/08/2026'), findsOneWidget);
      for (final text in [
        'PRIMEIRA-X',
        'SEGUNDA-X',
        'TERCEIRA-X',
        'OUTRO-DIA-X',
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      final markers = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).shape == BoxShape.circle,
      );
      expect(markers, findsNWidgets(2));
    });

    test('groupByDay agrupa só datas consecutivas e preserva a ordem', () {
      final groups = EvolutionTimeline.groupByDay([
        _entry('a', DateTime(2026, 8, 10), 'a'),
        _entry('b', DateTime(2026, 8, 9), 'b'),
        _entry('c', DateTime(2026, 8, 10), 'c'),
        _entry('d', DateTime(2026, 8, 10), 'd'),
      ]);

      expect(groups.map((g) => g.map((e) => e.id).toList()).toList(), [
        ['a'],
        ['b'],
        ['c', 'd'],
      ]);
    });

    testWidgets('legenda de edição só nos itens editados', (tester) async {
      await pumpList(tester, many(4));

      expect(find.textContaining('Editado em'), findsNWidgets(2));
    });
  });

  group('ação "mais" neutra e independente', () {
    testWidgets('não há lixeira fixa; o botão "mais" é neutro e tem >= 48', (
      tester,
    ) async {
      await pumpList(tester, many(2));

      expect(find.byIcon(Icons.delete_outline), findsNothing);
      expect(find.byTooltip(_t.deleteEvolutionTooltip), findsNothing);
      final finder = find.widgetWithIcon(IconButton, Icons.more_horiz).first;
      final button = tester.widget<IconButton>(finder);
      final context = tester.element(find.byType(EvolutionTimeline));
      expect(button.color, context.colors.textSecondary);
      expect(button.color, isNot(context.colors.danger));
      final size = tester.getSize(finder);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('o texto clínico usa a largura toda do item (nada reservado)', (
      tester,
    ) async {
      await pumpList(
        tester,
        many(1),
        size: const Size(360, 4000),
        textScale: 1.3,
      );

      final text = tester.getRect(find.textContaining('Evolução número 0'));
      final more = tester.getRect(find.byIcon(Icons.more_horiz));
      // O botão fica abaixo do texto, não ao lado dele.
      expect(more.top, greaterThanOrEqualTo(text.bottom));
      final panel = tester.getRect(find.byType(EvolutionTimeline));
      expect(panel.right - text.right, lessThan(24));
    });

    testWidgets('menu abre com "Excluir evolução" em danger', (tester) async {
      await pumpList(tester, many(1));

      await tester.tap(find.byTooltip(_t.moreOptionsTooltip));
      await tester.pumpAndSettle();

      final action = find.widgetWithText(TextButton, _t.deleteEvolutionTitle);
      expect(action, findsOneWidget);
      final context = tester.element(action);
      final style = tester.widget<TextButton>(action).style!;
      expect(style.foregroundColor!.resolve({}), context.colors.danger);
    });

    testWidgets('mesma data: cada evolução tem a sua ação e exclui a certa', (
      tester,
    ) async {
      await pumpList(tester, [
        _entry('e1', DateTime(2026, 8, 10), 'PRIMEIRA-X'),
        _entry('e2', DateTime(2026, 8, 10), 'SEGUNDA-X'),
      ]);

      final buttons = find.byTooltip(_t.moreOptionsTooltip);
      expect(buttons, findsNWidgets(2));
      final first = tester.getRect(find.text('PRIMEIRA-X'));
      final second = tester.getRect(find.text('SEGUNDA-X'));
      final topIsFirst = first.top < second.top;
      final secondButton = tester.getRect(buttons.at(1));
      // O segundo botão pertence ao segundo item da lista (abaixo do primeiro).
      expect(
        secondButton.top,
        greaterThan(topIsFirst ? first.bottom : second.bottom),
      );

      await tester.tap(buttons.at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_t.deleteEvolutionTitle));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppConfirmSheet),
          matching: find.text(_t.deleteLabel),
        ),
      );
      await tester.pumpAndSettle();

      final deletedId =
          verify(() => repository.deleteEvolution(captureAny())).captured.single
              as String;
      // O item de baixo (índice 1 na tela) foi o excluído, e só ele.
      final remaining = topIsFirst ? 'PRIMEIRA-X' : 'SEGUNDA-X';
      final gone = topIsFirst ? 'SEGUNDA-X' : 'PRIMEIRA-X';
      expect(deletedId, topIsFirst ? 'e2' : 'e1');
      expect(find.text(gone), findsOneWidget); // repositório falso não remove
      expect(find.text(remaining), findsOneWidget);
    });
  });

  group('telas pequenas e texto grande', () {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      testWidgets(
        'várias evoluções longas em ${size.width.toInt()}x${size.height.toInt()} '
        'com texto 1.3 não estouram',
        (tester) async {
          await pumpList(tester, many(30), size: size, textScale: 1.3);

          expect(tester.takeException(), isNull);
          for (var i = 0; i < 60; i++) {
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -400),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
          }
        },
      );
    }

    testWidgets('texto clínico longo aparece inteiro, sem limite de linhas', (
      tester,
    ) async {
      await pumpList(
        tester,
        [_entry('e1', DateTime(2026, 8, 10), _longText)],
        size: const Size(360, 4000),
        textScale: 1.3,
      );

      final finder = find.text(_longText);
      final text = tester.widget<Text>(finder);
      expect(text.maxLines, isNull);
      expect(
        tester.renderObject<RenderParagraph>(finder).didExceedMaxLines,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark: monta sem erro', (tester) async {
      await pumpList(tester, many(3), dark: true);

      expect(tester.takeException(), isNull);
      expect(find.byType(EvolutionTimeline), findsOneWidget);
    });
  });
}
