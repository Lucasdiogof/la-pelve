import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment_status.dart';
import 'package:la_pelve/features/agenda/domain/repositories/agenda_repository.dart';
import 'package:la_pelve/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:la_pelve/features/agenda/presentation/pages/agenda_page.dart';
import 'package:la_pelve/features/agenda/presentation/widgets/status_picker_sheet.dart';
import 'package:la_pelve/shared/widgets/app_empty_state.dart';
import 'package:la_pelve/shared/widgets/app_metric.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';
import 'package:la_pelve/shared/widgets/app_time_row.dart';

class _FakeAgendaRepository extends Mock implements AgendaRepository {}

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  setUpAll(() => registerFallbackValue(AppointmentStatus.scheduled));

  Appointment appt(
    String id,
    DateTime date,
    int hour,
    String name, {
    AppointmentStatus status = AppointmentStatus.scheduled,
  }) => Appointment(
    id: id,
    date: date,
    time: TimeOfDay(hour: hour, minute: 0),
    patientName: name,
    status: status,
  );

  /// Monta a Agenda com rotas falsas para criar/editar: navegar troca a tela
  /// por um texto ("NOVO" / "EDITAR <id>") que os testes procuram.
  Future<_FakeAgendaRepository> pumpAgenda(
    WidgetTester tester, {
    List<Appointment> appointments = const [],
    Size size = const Size(390, 900),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    SharedPreferences.setMockInitialValues({});

    final repository = _FakeAgendaRepository();
    when(
      () => repository.getAll(),
    ).thenAnswer((_) async => Success(appointments));
    when(
      () => repository.updateStatus(any(), any()),
    ).thenAnswer((_) async => const Success(null));

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const AgendaPage()),
        GoRoute(
          path: '/agenda/novo',
          builder: (_, _) => const Scaffold(body: Text('NOVO')),
        ),
        GoRoute(
          path: '/agenda/:id/editar',
          builder: (_, state) =>
              Scaffold(body: Text('EDITAR ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AgendaCubit(repository)..ensureLoaded()),
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

  final sample = [
    appt('a1', today, 9, 'Maria Souza', status: AppointmentStatus.confirmed),
    appt('a2', today, 14, 'Ana Paula Ribeiro'),
    appt('a3', today.add(const Duration(days: 1)), 10, 'Joana Lima'),
    appt('a4', today.add(const Duration(days: 3)), 8, 'Carla Dias'),
    // Fora da janela da Agenda (hoje..hoje+7): não aparece.
    appt('a5', today.add(const Duration(days: 10)), 8, 'Fora da Janela'),
  ];

  testWidgets('agrupa por dia: um painel por dia, linhas sem card', (
    tester,
  ) async {
    await pumpAgenda(tester, appointments: sample);

    expect(find.text('HOJE'), findsOneWidget);
    expect(find.text('AMANHÃ'), findsOneWidget);
    expect(find.byType(AppSection), findsNWidgets(3));
    expect(find.byType(AppTimeRow), findsNWidgets(4));
    expect(find.text('Fora da Janela'), findsNothing);

    // As duas consultas de hoje ficam no MESMO painel.
    AppSection sectionOf(String name) => tester.widget<AppSection>(
      find.ancestor(of: find.text(name), matching: find.byType(AppSection)),
    );
    expect(
      identical(sectionOf('Maria Souza'), sectionOf('Ana Paula Ribeiro')),
      isTrue,
    );
    expect(
      identical(sectionOf('Maria Souza'), sectionOf('Joana Lima')),
      isFalse,
    );

    // Nenhuma estrutura de card por consulta: nem Card, nem um Material
    // próprio entre a linha e o painel do dia.
    expect(find.byType(Card), findsNothing);
    for (final row in tester.widgetList<AppTimeRow>(find.byType(AppTimeRow))) {
      final materials = find.ancestor(
        of: find.byWidget(row),
        matching: find.descendant(
          of: find.byType(AppSection),
          matching: find.byType(Material),
        ),
      );
      expect(materials, findsOneWidget, reason: 'só o Material do painel');
    }
  });

  testWidgets('"+" na AppBar abre a criação e não existe FAB', (tester) async {
    await pumpAgenda(tester, appointments: sample);

    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.tap(find.byTooltip('Criar agendamento'));
    await tester.pumpAndSettle();
    expect(find.text('NOVO'), findsOneWidget);
  });

  testWidgets('tocar na linha abre a edição da consulta', (tester) async {
    await pumpAgenda(tester, appointments: sample);

    await tester.tap(find.text('Joana Lima'));
    await tester.pumpAndSettle();
    expect(find.text('EDITAR a3'), findsOneWidget);
  });

  testWidgets(
    'tocar no status abre o seletor com os 6 status sem abrir a edição',
    (tester) async {
      await pumpAgenda(tester, appointments: sample);

      await tester.tap(find.text('Confirmado'));
      await tester.pumpAndSettle();

      expect(find.byType(StatusPickerSheet), findsOneWidget);
      expect(find.textContaining('EDITAR'), findsNothing);
      expect(find.text('Status do agendamento'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StatusPickerSheet),
          matching: find.byType(ListTile),
        ),
        findsNWidgets(AppointmentStatus.values.length),
      );
      for (final label in [
        'Agendado',
        'Confirmado',
        'Atendido',
        'Cancelado',
        'Faltou',
        'Reagendado',
      ]) {
        expect(
          find.descendant(
            of: find.byType(StatusPickerSheet),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets('o toque do status tem área de pelo menos 48px', (tester) async {
    await pumpAgenda(tester, appointments: sample);

    final tapArea = find.ancestor(
      of: find.text('Confirmado'),
      matching: find.byType(InkWell),
    );
    // O primeiro InkWell acima do badge é o do status (não o da linha).
    final size = tester.getSize(tapArea.first);
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
  });

  testWidgets('escolher um status chama updateStatus com o status escolhido', (
    tester,
  ) async {
    final repository = await pumpAgenda(tester, appointments: sample);

    await tester.tap(find.text('Confirmado'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(StatusPickerSheet),
        matching: find.text('Atendido'),
      ),
    );
    await tester.pumpAndSettle();

    verify(
      () => repository.updateStatus('a1', AppointmentStatus.fulfilled),
    ).called(1);
    expect(find.byType(StatusPickerSheet), findsNothing);
  });

  testWidgets('estado vazio mantém o texto e tem a ação de criar', (
    tester,
  ) async {
    await pumpAgenda(tester);

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('Nenhum agendamento'), findsOneWidget);
    expect(find.text('Nada marcado para os próximos 7 dias.'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AppEmptyState),
        matching: find.text('Criar agendamento'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('NOVO'), findsOneWidget);
  });

  testWidgets('relatório mostra o total do mês e troca de mês', (tester) async {
    final thisMonth = DateTime(now.year, now.month);
    await pumpAgenda(
      tester,
      appointments: [
        appt('r1', DateTime(thisMonth.year, thisMonth.month, 1), 9, 'R1'),
        appt(
          'r2',
          DateTime(thisMonth.year, thisMonth.month, 15),
          9,
          'R2',
          status: AppointmentStatus.cancelled,
        ),
        appt('r3', DateTime(thisMonth.year, thisMonth.month + 1, 2), 9, 'R3'),
      ],
    );

    await tester.tap(find.text('Relatório'));
    await tester.pumpAndSettle();

    String total() => tester.widget<AppMetric>(find.byType(AppMetric)).value;

    // A contagem é a atual: todos os agendamentos do mês, de qualquer status.
    expect(find.text('Agendamentos no mês'), findsOneWidget);
    expect(total(), '2');

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(total(), '1');

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(total(), '0');
  });

  testWidgets('360px com textScale 1.3: Próximos e Relatório sem overflow', (
    tester,
  ) async {
    await pumpAgenda(
      tester,
      appointments: [
        ...sample,
        appt('a6', today, 16, 'Maria Aparecida Fernandes de Albuquerque'),
      ],
      size: const Size(360, 800),
      textScale: 1.3,
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(AppTimeRow), findsWidgets);

    await tester.tap(find.text('Relatório'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AppMetric), findsOneWidget);
  });

  // O bottom sheet padrão limita a altura a 9/16 da tela (360 em 640) e as 6
  // opções precisam de ~414: em celulares curtos o seletor estourava. Agora o
  // sheet abre sem esse limite e, se ainda faltar altura (360x400 simula uma
  // tela bem curta/paisagem), as opções rolam dentro do sheet.
  for (final (size, scale) in [
    (const Size(360, 640), 1.0),
    (const Size(375, 667), 1.0),
    (const Size(360, 640), 1.3),
    (const Size(360, 400), 1.0),
  ]) {
    testWidgets(
      'seletor de status em ${size.width.toInt()}x${size.height.toInt()} '
      'x$scale: sem overflow e a última opção é alcançável',
      (tester) async {
        final repository = await pumpAgenda(
          tester,
          appointments: sample,
          size: size,
          textScale: scale,
        );

        await tester.tap(find.text('Confirmado'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final inSheet = find.byType(StatusPickerSheet);
        await tester.scrollUntilVisible(
          find.descendant(of: inSheet, matching: find.text('Reagendado')),
          80,
          scrollable: find.descendant(
            of: inSheet,
            matching: find.byType(Scrollable),
          ),
        );
        await tester.tap(
          find.descendant(of: inSheet, matching: find.text('Reagendado')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        verify(
          () => repository.updateStatus('a1', AppointmentStatus.rescheduled),
        ).called(1);
      },
    );
  }

  for (final (size, scale) in [
    (const Size(360, 640), 1.0),
    (const Size(375, 667), 1.0),
    (const Size(360, 640), 1.3),
  ]) {
    testWidgets(
      'seletor de status em ${size.width.toInt()}x${size.height.toInt()} '
      'x$scale: as 6 opções ficam visíveis sem rolar',
      (tester) async {
        await pumpAgenda(
          tester,
          appointments: sample,
          size: size,
          textScale: scale,
        );
        await tester.tap(find.text('Confirmado'));
        await tester.pumpAndSettle();

        for (final label in [
          'Agendado',
          'Confirmado',
          'Atendido',
          'Cancelado',
          'Faltou',
          'Reagendado',
        ]) {
          final rect = tester.getRect(
            find.descendant(
              of: find.byType(StatusPickerSheet),
              matching: find.text(label),
            ),
          );
          expect(rect.top, greaterThanOrEqualTo(0), reason: label);
          expect(rect.bottom, lessThanOrEqualTo(size.height), reason: label);
        }
      },
    );
  }
}
