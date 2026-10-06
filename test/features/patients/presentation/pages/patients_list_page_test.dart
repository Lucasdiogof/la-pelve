import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/app_language.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_enums.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_repository.dart';
import 'package:la_pelve/features/patients/l10n/patients_strings.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/features/patients/presentation/pages/patients_list_page.dart';
import 'package:la_pelve/shared/widgets/app_empty_state.dart';
import 'package:la_pelve/shared/widgets/app_list_row.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';
import 'package:la_pelve/shared/widgets/app_status_badge.dart';

class _FakePatientRepository extends Mock implements PatientRepository {}

/// Quantidade de linhas visuais de um parágrafo: posições verticais
/// distintas das caixas do texto (sem depender de pixel exato).
int _lineCount(RenderParagraph paragraph, String text) {
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  return boxes.map((b) => b.top.round()).toSet().length;
}

void main() {
  var seq = 0;

  Patient patient(
    String id,
    String name, {
    String phone = '',
    Discharge? discharge,
  }) => Patient(
    id: id,
    createdAt: DateTime(2026, 1, 1).add(Duration(days: seq++)),
    personalInfo: PersonalInfo(name: name, phone: phone),
    discharge: discharge,
  );

  Discharge discharge(
    DischargeReason reason, {
    DateTime? date,
    String? finalNote,
  }) => Discharge(
    date: date ?? DateTime(2026, 9, 3),
    reason: reason,
    finalNote: finalNote,
  );

  /// Monta a lista com rotas falsas: navegar troca a tela por um texto
  /// ("NOVO" / "DETALHE <id> <nome>") que os testes procuram.
  Future<_FakePatientRepository> pumpList(
    WidgetTester tester, {
    List<Patient> patients = const [],
    Size size = const Size(390, 900),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    SharedPreferences.setMockInitialValues({});

    final repository = _FakePatientRepository();
    when(() => repository.getAll()).thenAnswer((_) async => Success(patients));

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const PatientsListPage()),
        GoRoute(
          path: '/pacientes/novo',
          builder: (_, _) => const Scaffold(body: Text('NOVO')),
        ),
        GoRoute(
          path: '/pacientes/:id',
          builder: (_, state) {
            final extra = state.extra! as Patient;
            return Scaffold(
              body: Text(
                'DETALHE ${state.pathParameters['id']} '
                '${extra.personalInfo.name}',
              ),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => PatientsCubit(repository)),
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
    return repository;
  }

  List<String> titles(WidgetTester tester) => tester
      .widgetList<AppListRow>(find.byType(AppListRow))
      .map((row) => row.title)
      .toList();

  group('linhas', () {
    testWidgets('renderiza nome, telefone e avatar de inicial', (tester) async {
      await pumpList(
        tester,
        patients: [patient('p1', 'Ana Souza', phone: '(62) 99999-0000')],
      );

      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('(62) 99999-0000'), findsOneWidget);
      expect(find.byType(AppListRow), findsOneWidget);
      expect(find.byType(AppInitialAvatar), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('nome vazio usa o fallback "Sem nome" e avatar "?"', (
      tester,
    ) async {
      await pumpList(
        tester,
        patients: [patient('p1', '', phone: '(62) 98888-0000')],
      );

      expect(find.text('Sem nome'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('paciente sem telefone não ganha linha vazia', (tester) async {
      await pumpList(tester, patients: [patient('p1', 'Ana Souza')]);

      final row = tester.widget<AppListRow>(find.byType(AppListRow));
      expect(row.subtitle, isNull);
    });

    testWidgets('toque na linha abre o detalhe do paciente certo', (
      tester,
    ) async {
      await pumpList(
        tester,
        patients: [patient('p1', 'Ana Souza'), patient('p2', 'Bia Lima')],
      );

      await tester.tap(find.text('Bia Lima'));
      await tester.pumpAndSettle();
      expect(find.text('DETALHE p2 Bia Lima'), findsOneWidget);
    });

    testWidgets('nome longo: Pacientes usa até 3 linhas, sem reticências', (
      tester,
    ) async {
      const name = 'Maria Aparecida Fernandes de Albuquerque';
      await pumpList(tester, patients: [patient('p1', name)]);

      expect(
        tester.widget<AppListRow>(find.byType(AppListRow)).titleMaxLines,
        3,
      );
      expect(tester.widget<Text>(find.text(name)).maxLines, 3);
      final paragraph = tester.renderObject<RenderParagraph>(find.text(name));
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(_lineCount(paragraph, name), 3);
    });
  });

  group('ordem e alta', () {
    testWidgets('ativos antes de quem tem alta, preservando a ordem relativa', (
      tester,
    ) async {
      await pumpList(
        tester,
        patients: [
          patient('a1', 'A1'),
          patient('d1', 'D1', discharge: discharge(DischargeReason.completed)),
          patient('a2', 'A2'),
          patient('d2', 'D2', discharge: discharge(DischargeReason.dropOut)),
          patient('a3', 'A3'),
        ],
      );

      expect(titles(tester), ['A1', 'A2', 'A3', 'D1', 'D2']);
    });

    testWidgets('alta mostra "motivo · data" abaixo do telefone', (
      tester,
    ) async {
      await pumpList(
        tester,
        patients: [
          patient(
            'd1',
            'Maria Oliveira',
            phone: '(62) 97777-0000',
            discharge: discharge(DischargeReason.completed),
          ),
        ],
      );

      expect(find.text('(62) 97777-0000\nAlta · 03/09/2026'), findsOneWidget);
    });

    testWidgets('alta sem telefone: "motivo · data" numa linha quando cabe', (
      tester,
    ) async {
      await pumpList(
        tester,
        patients: [
          patient(
            'd1',
            'Maria Oliveira',
            discharge: discharge(DischargeReason.dropOut),
          ),
        ],
        size: const Size(900, 900),
      );

      expect(find.text('Abandono · 03/09/2026'), findsOneWidget);
    });

    testWidgets('quando não cabe, quebra em duas linhas SEM o "·" pendurado', (
      tester,
    ) async {
      await pumpList(
        tester,
        patients: [
          patient(
            'd1',
            'Maria Oliveira',
            discharge: discharge(DischargeReason.referred),
          ),
        ],
      );

      expect(find.text('Encaminhamento\n03/09/2026'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppListRow),
          matching: find.textContaining('·'),
        ),
        findsNothing,
      );
    });

    testWidgets('com telefone: telefone, motivo e data em linhas separadas', (
      tester,
    ) async {
      await pumpList(
        tester,
        patients: [
          patient(
            'd1',
            'Maria Oliveira',
            phone: '(62) 98222-3344',
            discharge: discharge(DischargeReason.referred),
          ),
        ],
      );

      expect(
        find.text('(62) 98222-3344\nEncaminhamento\n03/09/2026'),
        findsOneWidget,
      );
    });

    testWidgets('varredura de larguras e escalas: "·" nunca fica pendurado', (
      tester,
    ) async {
      for (final scale in [1.0, 1.3]) {
        for (var width = 320.0; width <= 600; width += 40) {
          for (final reason in [
            DischargeReason.completed,
            DischargeReason.dropOut,
            DischargeReason.referred,
          ]) {
            await pumpList(
              tester,
              patients: [
                patient('d1', 'Maria Oliveira', discharge: discharge(reason)),
              ],
              size: Size(width, 900),
              textScale: scale,
            );
            final caption = find.byWidgetPredicate(
              (w) => w is Text && (w.data ?? '').contains('03/09/2026'),
            );
            final text = tester.widget<Text>(caption).data!;
            if (text.contains('·')) {
              // Variante de uma linha: a quebra automática NÃO pode ter
              // acontecido (senão o "·" ficaria no fim de uma linha).
              final lines = _lineCount(
                tester.renderObject<RenderParagraph>(caption),
                text,
              );
              expect(
                lines,
                text.split('\n').length,
                reason: '${reason.name} em ${width}px x$scale: "$text"',
              );
            }
          }
        }
      }
    });

    testWidgets('a nota final da alta não aparece na lista', (tester) async {
      await pumpList(
        tester,
        patients: [
          patient(
            'd1',
            'Maria Oliveira',
            discharge: discharge(
              DischargeReason.other,
              finalNote: 'Nota clínica reservada',
            ),
          ),
        ],
      );

      expect(find.textContaining('Nota clínica reservada'), findsNothing);
    });

    testWidgets('nada de pílula/badge de alta e nome continua legível', (
      tester,
    ) async {
      await pumpList(
        tester,
        patients: [
          patient(
            'd1',
            'Maria Oliveira',
            discharge: discharge(DischargeReason.completed),
          ),
        ],
      );

      expect(find.byType(AppStatusBadge), findsNothing);
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('overline COM ALTA só existe quando há alta, antes do grupo', (
      tester,
    ) async {
      await pumpList(
        tester,
        patients: [
          patient('a1', 'A1'),
          patient('d1', 'D1', discharge: discharge(DischargeReason.completed)),
        ],
      );

      expect(find.text('COM ALTA'), findsOneWidget);
      expect(find.text('ATIVOS'), findsNothing);
      final header = tester.getTopLeft(find.text('COM ALTA')).dy;
      expect(header, greaterThan(tester.getBottomLeft(find.text('A1')).dy));
      expect(header, lessThan(tester.getTopLeft(find.text('D1')).dy));
    });

    testWidgets('sem ninguém com alta não há overline', (tester) async {
      await pumpList(
        tester,
        patients: [patient('a1', 'A1'), patient('a2', 'A2')],
      );

      expect(find.text('COM ALTA'), findsNothing);
    });

    testWidgets('todos com alta: o overline abre a lista', (tester) async {
      await pumpList(
        tester,
        patients: [
          patient('d1', 'D1', discharge: discharge(DischargeReason.completed)),
        ],
      );

      expect(find.text('COM ALTA'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('COM ALTA')).dy,
        lessThan(tester.getTopLeft(find.text('D1')).dy),
      );
    });
  });

  group('AppBar e contagem', () {
    testWidgets('contagem do total: plural', (tester) async {
      await pumpList(
        tester,
        patients: [
          patient('a1', 'A1'),
          patient('a2', 'A2'),
          patient('a3', 'A3'),
        ],
      );

      expect(find.text('3 pacientes'), findsOneWidget);
      expect(find.text('Gerencie seus pacientes'), findsNothing);
    });

    testWidgets('contagem do total: singular', (tester) async {
      await pumpList(tester, patients: [patient('a1', 'A1')]);

      expect(find.text('1 paciente'), findsOneWidget);
    });

    testWidgets('contagem com alta: total inclui quem tem alta', (
      tester,
    ) async {
      await pumpList(
        tester,
        patients: [
          patient('a1', 'A1'),
          patient('a2', 'A2'),
          patient('d1', 'D1', discharge: discharge(DischargeReason.completed)),
        ],
      );

      expect(find.text('3 pacientes · 1 com alta'), findsOneWidget);
    });

    testWidgets('lista vazia mantém o subtítulo fixo e não mostra "0"', (
      tester,
    ) async {
      await pumpList(tester);

      expect(find.text('Gerencie seus pacientes'), findsOneWidget);
      expect(find.textContaining('0 pacientes'), findsNothing);
    });

    testWidgets('"+" abre a criação e tem o tooltip "Novo paciente"', (
      tester,
    ) async {
      await pumpList(tester, patients: [patient('a1', 'A1')]);

      expect(find.byTooltip('Novo paciente'), findsOneWidget);
      await tester.tap(find.byTooltip('Novo paciente'));
      await tester.pumpAndSettle();
      expect(find.text('NOVO'), findsOneWidget);
    });

    testWidgets('não existe FloatingActionButton (com e sem pacientes)', (
      tester,
    ) async {
      await pumpList(tester, patients: [patient('a1', 'A1')]);
      expect(find.byType(FloatingActionButton), findsNothing);

      await pumpList(tester);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    test('textos de contagem em pt, en e es (singular/plural)', () {
      const pt = PatientsStrings(AppLanguage.portuguese);
      const en = PatientsStrings(AppLanguage.english);
      const es = PatientsStrings(AppLanguage.spanish);

      expect(pt.patientCount(1), '1 paciente');
      expect(pt.patientCount(16), '16 pacientes');
      expect(pt.patientCountWithDischarged(16, 1), '16 pacientes · 1 com alta');
      expect(pt.patientCountWithDischarged(16, 2), '16 pacientes · 2 com alta');
      expect(pt.dischargedSectionTitle, 'Com alta');

      expect(en.patientCount(1), '1 patient');
      expect(en.patientCount(16), '16 patients');
      expect(
        en.patientCountWithDischarged(16, 1),
        '16 patients · 1 discharged',
      );
      expect(
        en.patientCountWithDischarged(16, 2),
        '16 patients · 2 discharged',
      );
      expect(en.dischargedSectionTitle, 'Discharged');

      expect(es.patientCount(1), '1 paciente');
      expect(es.patientCount(16), '16 pacientes');
      expect(es.patientCountWithDischarged(16, 1), '16 pacientes · 1 con alta');
      expect(es.patientCountWithDischarged(16, 2), '16 pacientes · 2 con alta');
      expect(es.dischargedSectionTitle, 'Con alta');
    });
  });

  group('estado vazio', () {
    testWidgets('mantém textos e tem a ação "Novo paciente"', (tester) async {
      await pumpList(tester);

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Nenhum paciente cadastrado'), findsOneWidget);
      expect(
        find.text('Toque em "Novo paciente" para começar.'),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(AppEmptyState),
          matching: find.text('Novo paciente'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('NOVO'), findsOneWidget);
    });

    testWidgets('puxar para atualizar continua funcionando no vazio', (
      tester,
    ) async {
      final repository = await pumpList(tester);

      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      // 1 carga inicial do cubit + 1 do pull-to-refresh.
      verify(() => repository.getAll()).called(greaterThanOrEqualTo(2));
    });
  });

  group('estrutura visual', () {
    AppSection sectionOf(WidgetTester tester, String name) =>
        tester.widget<AppSection>(
          find.ancestor(of: find.text(name), matching: find.byType(AppSection)),
        );

    testWidgets('um painel por bloco: ativos juntos e quem tem alta à parte', (
      tester,
    ) async {
      await pumpList(
        tester,
        patients: [
          patient('a1', 'A1', phone: '(62) 99999-0000'),
          patient('a2', 'A2'),
          patient('d1', 'D1', discharge: discharge(DischargeReason.completed)),
          patient('d2', 'D2', discharge: discharge(DischargeReason.dropOut)),
        ],
      );

      expect(find.byType(AppSection), findsNWidgets(2));
      expect(
        identical(sectionOf(tester, 'A1'), sectionOf(tester, 'A2')),
        isTrue,
      );
      expect(
        identical(sectionOf(tester, 'D1'), sectionOf(tester, 'D2')),
        isTrue,
      );
      expect(
        identical(sectionOf(tester, 'A1'), sectionOf(tester, 'D1')),
        isFalse,
      );
      // Só o bloco com alta leva overline; os ativos não.
      expect(sectionOf(tester, 'A1').title, isNull);
      expect(sectionOf(tester, 'D1').title, 'Com alta');
    });

    testWidgets('sem ninguém com alta há um único painel, sem overline', (
      tester,
    ) async {
      await pumpList(
        tester,
        patients: [patient('a1', 'A1'), patient('a2', 'A2')],
      );

      expect(find.byType(AppSection), findsOneWidget);
      expect(tester.widget<AppSection>(find.byType(AppSection)).title, isNull);
    });

    testWidgets('todos com alta: só o painel "Com alta"', (tester) async {
      await pumpList(
        tester,
        patients: [
          patient('d1', 'D1', discharge: discharge(DischargeReason.completed)),
        ],
      );

      expect(find.byType(AppSection), findsOneWidget);
      expect(sectionOf(tester, 'D1').title, 'Com alta');
    });

    testWidgets('sem card nem Material próprio por paciente', (tester) async {
      await pumpList(
        tester,
        patients: [
          patient('a1', 'A1', phone: '(62) 99999-0000'),
          patient('a2', 'A2'),
          patient('d1', 'D1', discharge: discharge(DischargeReason.completed)),
        ],
      );

      expect(find.byType(Card), findsNothing);
      expect(find.byType(AppListRow), findsNWidgets(3));
      for (final row in tester.widgetList<AppListRow>(
        find.byType(AppListRow),
      )) {
        // Entre a linha e o painel só existe o Material do próprio painel.
        final materials = find.ancestor(
          of: find.byWidget(row),
          matching: find.descendant(
            of: find.byType(AppSection),
            matching: find.byType(Material),
          ),
        );
        expect(materials, findsOneWidget, reason: row.title);
        expect(
          find.descendant(
            of: find.byWidget(row),
            matching: find.byType(Material),
          ),
          findsNothing,
        );
      }
    });

    testWidgets('divisor entre as linhas do bloco e nenhum depois da última', (
      tester,
    ) async {
      await pumpList(
        tester,
        patients: [
          patient('a1', 'A1'),
          patient('a2', 'A2'),
          patient('d1', 'D1', discharge: discharge(DischargeReason.completed)),
          patient('d2', 'D2', discharge: discharge(DischargeReason.dropOut)),
        ],
      );

      final dividers = tester
          .widgetList<AppListRow>(find.byType(AppListRow))
          .map((row) => row.showDivider)
          .toList();
      expect(dividers, [true, false, true, false]);
    });
  });

  group('responsividade', () {
    testWidgets('360px com textScale 1.3: nomes longos, alta e contagem', (
      tester,
    ) async {
      await pumpList(
        tester,
        patients: [
          patient(
            'a1',
            'Maria Aparecida Fernandes de Albuquerque Souza',
            phone: '(62) 99999-0000',
          ),
          patient('a2', 'Ana'),
          patient('a3', '', phone: '(62) 98888-0000'),
          patient(
            'd1',
            'Luciana Ferreira de Albuquerque',
            phone: '(62) 97777-0000',
            discharge: discharge(DischargeReason.referred),
          ),
          patient('d2', 'Bia', discharge: discharge(DischargeReason.other)),
        ],
        size: const Size(360, 800),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AppListRow), findsWidgets);
      expect(find.text('5 pacientes · 2 com alta'), findsOneWidget);
    });
  });
}
