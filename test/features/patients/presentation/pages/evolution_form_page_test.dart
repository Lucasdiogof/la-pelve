// Testes focados do formulário de evolução: regras de habilitação, criação e
// edição (o que vai para o repositório), loading, erro, contexto do paciente na
// AppBar, textarea e a separação da barra de ação com o teclado aberto.
// Não verificam pixel exato.

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
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/features/patients/presentation/pages/evolution_form_page.dart';
import 'package:la_pelve/shared/widgets/app_info_bottom_sheet.dart';
import 'package:la_pelve/shared/widgets/app_date_field.dart';
import 'package:la_pelve/shared/widgets/primary_button.dart';

class _FakePatientRepository extends Mock implements PatientRepository {}

const _t = PatientsStrings(AppLanguage.portuguese);

final _existing = EvolutionEntry(
  id: 'e1',
  patientId: 'p1',
  date: DateTime(2026, 8, 12),
  description: 'TEXTO-EXISTENTE-X',
  createdBy: 'u1',
  createdAt: DateTime(2026, 8, 12, 9),
);

void main() {
  late _FakePatientRepository repository;

  setUpAll(() {
    registerFallbackValue(_existing);
  });

  setUp(() async => sl.reset());
  tearDown(() async => sl.reset());

  /// Abre a lista falsa e empilha o formulário por cima (como no app), para o
  /// `pop` depois de salvar ter para onde voltar.
  Future<void> pumpForm(
    WidgetTester tester, {
    EvolutionEntry? existing,
    bool registerPatients = true,
    bool patientLoaded = true,
    Completer<Result<void>>? pending,
    bool failSave = false,
    double keyboard = 0,
    Size size = const Size(390, 1200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    SharedPreferences.setMockInitialValues({});

    repository = _FakePatientRepository();
    Future<Result<void>> save(_) async {
      if (pending != null) return pending.future;
      if (failSave) return Error(ServerFailure('FALHA-SALVAR-X'));
      return const Success(null);
    }

    when(() => repository.addEvolution(any())).thenAnswer(save);
    when(() => repository.updateEvolution(any())).thenAnswer(save);
    when(() => repository.getAll()).thenAnswer(
      (_) async => Success([
        if (patientLoaded)
          Patient(
            id: 'p1',
            createdAt: DateTime(2026, 1, 1),
            personalInfo: const PersonalInfo(name: 'Maria Teste-X'),
          ),
      ]),
    );
    sl.registerSingleton<PatientRepository>(repository);
    if (registerPatients) {
      final patientsCubit = PatientsCubit(repository);
      sl.registerSingleton<PatientsCubit>(patientsCubit);
      unawaited(patientsCubit.ensureLoaded());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('LISTA')),
        ),
        GoRoute(
          path: '/form',
          builder: (_, state) => EvolutionFormPage(
            patientId: 'p1',
            existingEntry: state.extra as EvolutionEntry?,
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
    unawaited(router.push('/form', extra: existing));
    await tester.pumpAndSettle();
  }

  Finder description() => find.byWidgetPredicate(
    (w) => w is TextField && w.maxLines == null,
    description: 'textarea da evolução',
  );

  /// O botão de salvar da própria página (o sheet de erro também tem botão).
  Finder saveFinder() => find.descendant(
    of: find.byType(EvolutionFormPage),
    matching: find.byType(PrimaryButton),
  );

  PrimaryButton saveButton(WidgetTester tester) =>
      tester.widget<PrimaryButton>(saveFinder());

  bool canSave(WidgetTester tester) => saveButton(tester).onPressed != null;

  /// Escolhe o dia 1 do mês atual (sempre <= hoje) no seletor de data.
  Future<DateTime> pickDate(WidgetTester tester) async {
    await tester.tap(find.byType(AppDateField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  group('novo', () {
    testWidgets('salvar começa desabilitado e a data começa vazia', (
      tester,
    ) async {
      await pumpForm(tester);

      expect(canSave(tester), isFalse);
      expect(find.text(_t.saveLabel), findsOneWidget);
      expect(find.text(_t.newEvolutionTitle), findsOneWidget);
    });

    testWidgets('sem data não habilita, mesmo com texto', (tester) async {
      await pumpForm(tester);

      await tester.enterText(description(), 'Evolução válida');
      await tester.pump();

      expect(canSave(tester), isFalse);
    });

    testWidgets('com data mas texto vazio ou só espaços não habilita', (
      tester,
    ) async {
      await pumpForm(tester);

      await pickDate(tester);
      expect(canSave(tester), isFalse);
      await tester.enterText(description(), '    ');
      await tester.pump();

      expect(canSave(tester), isFalse);
    });

    testWidgets('data + texto válido habilitam; addEvolution leva '
        'patientId, texto com trim e sem updatedAt', (tester) async {
      await pumpForm(tester);

      final date = await pickDate(tester);
      await tester.enterText(description(), '   texto novo X   ');
      await tester.pump();
      expect(canSave(tester), isTrue);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      final entry =
          verify(() => repository.addEvolution(captureAny())).captured.single
              as EvolutionEntry;
      expect(entry.patientId, 'p1');
      expect(entry.description, 'texto novo X');
      expect(entry.date, date);
      expect(entry.updatedAt, isNull);
      expect(entry.id, isNotEmpty);
      verifyNever(() => repository.updateEvolution(any()));
    });

    testWidgets('sucesso volta para a tela anterior e avisa', (tester) async {
      await pumpForm(tester);

      await pickDate(tester);
      await tester.enterText(description(), 'texto novo X');
      await tester.pump();
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('LISTA'), findsOneWidget);
      expect(find.byType(AppInfoBottomSheet), findsOneWidget);
      expect(find.text(_t.evolutionCreatedSuccess), findsOneWidget);
    });
  });

  group('editar', () {
    testWidgets('vem preenchido e o botão é "Salvar alterações"', (
      tester,
    ) async {
      await pumpForm(tester, existing: _existing);

      expect(find.text(_t.editEvolutionTitle), findsOneWidget);
      expect(find.text('12/08/2026'), findsOneWidget);
      expect(
        tester.widget<TextField>(description()).controller!.text,
        'TEXTO-EXISTENTE-X',
      );
      expect(find.text(_t.saveChangesLabel), findsOneWidget);
      expect(canSave(tester), isTrue);
    });

    testWidgets('updateEvolution mantém o id, usa trim e define updatedAt', (
      tester,
    ) async {
      await pumpForm(tester, existing: _existing);

      await tester.enterText(description(), '  texto editado X  ');
      await tester.pump();
      final before = DateTime.now();
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      final entry =
          verify(() => repository.updateEvolution(captureAny())).captured.single
              as EvolutionEntry;
      expect(entry.id, 'e1');
      expect(entry.patientId, 'p1');
      expect(entry.description, 'texto editado X');
      expect(entry.date, DateTime(2026, 8, 12));
      expect(entry.updatedAt, isNotNull);
      expect(entry.updatedAt!.isBefore(before), isFalse);
      verifyNever(() => repository.addEvolution(any()));
      expect(find.text(_t.evolutionUpdatedSuccess), findsOneWidget);
    });

    testWidgets('apagar o texto desabilita salvar', (tester) async {
      await pumpForm(tester, existing: _existing);

      await tester.enterText(description(), '  ');
      await tester.pump();

      expect(canSave(tester), isFalse);
    });
  });

  group('salvando e erro', () {
    testWidgets('durante o salvamento o botão fica em loading e desabilitado', (
      tester,
    ) async {
      final pending = Completer<Result<void>>();
      await pumpForm(tester, existing: _existing, pending: pending);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(saveButton(tester).isLoading, isTrue);
      // Em loading é o ElevatedButton interno que fica desabilitado.
      final inner = tester.widget<ElevatedButton>(
        find.descendant(
          of: saveFinder(),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(inner.onPressed, isNull);
      expect(
        find.descendant(
          of: find.byType(PrimaryButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      // Segundo toque não dispara outro salvamento.
      await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
      await tester.pump();
      verify(() => repository.updateEvolution(any())).called(1);

      pending.complete(const Success(null));
      await tester.pumpAndSettle();
    });

    testWidgets('erro: mostra o aviso, mantém a tela, o texto e o salvar', (
      tester,
    ) async {
      await pumpForm(tester, existing: _existing, failSave: true);

      await tester.enterText(description(), 'texto editado X');
      await tester.pump();
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.byType(AppInfoBottomSheet), findsOneWidget);
      expect(find.text('FALHA-SALVAR-X'), findsOneWidget);
      expect(find.text('LISTA'), findsNothing);
      expect(
        tester.widget<TextField>(description()).controller!.text,
        'texto editado X',
      );
      expect(saveButton(tester).isLoading, isFalse);
      expect(canSave(tester), isTrue);
    });
  });

  group('AppBar e contexto do paciente', () {
    testWidgets('mostra o nome do paciente quando encontrado', (tester) async {
      await pumpForm(tester);

      expect(find.text('Maria Teste-X'), findsOneWidget);
    });

    testWidgets('paciente não carregado: sem subtítulo e o form funciona', (
      tester,
    ) async {
      await pumpForm(tester, patientLoaded: false);

      expect(find.text('Maria Teste-X'), findsNothing);
      expect(find.text(_t.newEvolutionTitle), findsOneWidget);
      await pickDate(tester);
      await tester.enterText(description(), 'texto X');
      await tester.pump();
      expect(canSave(tester), isTrue);
    });

    testWidgets('PatientsCubit não registrado: o form continua funcionando', (
      tester,
    ) async {
      await pumpForm(tester, registerPatients: false);

      expect(find.text(_t.newEvolutionTitle), findsOneWidget);
      expect(find.text('Maria Teste-X'), findsNothing);
      await pickDate(tester);
      await tester.enterText(description(), 'texto X');
      await tester.pump();
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      verify(() => repository.addEvolution(any())).called(1);
    });
  });

  group('campos', () {
    testWidgets('textarea: label "Evolução", sem ícone, minLines 6 e '
        'maxLines nulo', (tester) async {
      await pumpForm(tester);

      expect(find.text(_t.evolutionFieldLabel), findsOneWidget);
      expect(find.text(_t.evolutionDescriptionHint), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsNothing);
      final field = tester.widget<TextField>(description());
      expect(field.minLines, 6);
      expect(field.maxLines, isNull);
    });

    testWidgets('data com label explícito e ícone de calendário', (
      tester,
    ) async {
      await pumpForm(tester);

      expect(find.text(_t.dateHint), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });
  });

  group('teclado', () {
    testWidgets('com teclado aberto há divisor entre o conteúdo e a barra', (
      tester,
    ) async {
      await pumpForm(tester, keyboard: 300, size: const Size(360, 800));

      expect(find.byType(Divider), findsOneWidget);
      expect(find.byType(PrimaryButton), findsOneWidget);
    });

    testWidgets('sem teclado não há esse divisor', (tester) async {
      await pumpForm(tester);

      expect(find.byType(Divider), findsNothing);
    });
  });
}
