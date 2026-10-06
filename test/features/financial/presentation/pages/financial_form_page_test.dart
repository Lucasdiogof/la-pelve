// Testes focados do formulário financeiro: regras de habilitação, criação e
// edição (o que vai para o repositório), status/forma de pagamento (inclusive
// os campos condicionais de "Outro"), exclusão e o comportamento com o
// teclado. Não verificam pixel exato.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/app_language.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_enums.dart';
import 'package:la_pelve/features/financial/domain/repositories/financial_repository.dart';
import 'package:la_pelve/features/financial/l10n/financial_strings.dart';
import 'package:la_pelve/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:la_pelve/features/financial/presentation/pages/financial_form_page.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_repository.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/shared/widgets/app_confirm_sheet.dart';
import 'package:la_pelve/shared/widgets/app_date_field.dart';
import 'package:la_pelve/shared/widgets/app_info_bottom_sheet.dart';
import 'package:la_pelve/shared/widgets/app_text_field.dart';
import 'package:la_pelve/shared/widgets/primary_button.dart';

class _FakeFinancialRepository extends Mock implements FinancialRepository {}

class _FakePatientRepository extends Mock implements PatientRepository {}

const _t = FinancialStrings(AppLanguage.portuguese);

final _existing = FinancialEntry(
  id: 'f1',
  patientId: 'p1',
  patientName: 'Maria Teste',
  date: DateTime(2026, 8, 12),
  amount: 180,
  notes: 'NOTA-EXISTENTE-X',
  paymentMethod: PaymentMethod.pix,
  status: PaymentStatus.paid,
);

final _registeredPatient = Patient(
  id: 'p1',
  createdAt: DateTime(2026, 1, 1),
  personalInfo: const PersonalInfo(name: 'Maria Teste'),
);

void main() {
  late _FakeFinancialRepository financialRepository;
  late _FakePatientRepository patientRepository;

  setUpAll(() {
    registerFallbackValue(_existing);
  });

  /// Abre a lista falsa e empilha o formulário por cima (como no app), para o
  /// `pop` depois de salvar/excluir ter para onde voltar.
  Future<void> pumpForm(
    WidgetTester tester, {
    FinancialEntry? existing,
    List<Patient> patients = const [],
    Completer<Result<void>>? pendingSave,
    bool failSave = false,
    Completer<Result<void>>? pendingDelete,
    bool failDelete = false,
    double keyboard = 0,
    Size size = const Size(390, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    SharedPreferences.setMockInitialValues({});

    financialRepository = _FakeFinancialRepository();
    Future<Result<void>> save(_) async {
      if (pendingSave != null) return pendingSave.future;
      if (failSave) return Error(ServerFailure('FALHA-SALVAR-X'));
      return const Success(null);
    }

    when(() => financialRepository.add(any())).thenAnswer(save);
    when(() => financialRepository.update(any())).thenAnswer(save);
    when(() => financialRepository.delete(any())).thenAnswer((_) async {
      if (pendingDelete != null) return pendingDelete.future;
      if (failDelete) return Error(ServerFailure('FALHA-EXCLUIR-X'));
      return const Success(null);
    });
    when(
      () => financialRepository.getAll(),
    ).thenAnswer((_) async => const Success([]));

    patientRepository = _FakePatientRepository();
    when(
      () => patientRepository.getAll(),
    ).thenAnswer((_) async => Success(patients));

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('LISTA')),
        ),
        GoRoute(
          path: '/form',
          builder: (_, state) =>
              FinancialFormPage(existingEntry: state.extra as FinancialEntry?),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => FinancialCubit(financialRepository)),
          BlocProvider(create: (_) => PatientsCubit(patientRepository)),
          BlocProvider(create: (_) => LocaleCubit()),
        ],
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

  Finder nameTextField() => find.byWidgetPredicate(
    (w) => w is TextField && w.maxLines == 2,
    description: 'campo de nome do paciente',
  );

  Finder amountField() => find.byWidgetPredicate(
    (w) =>
        w is TextField &&
        w.decoration?.hintText == _t.amountPaidHint,
    description: 'campo de valor',
  );

  Finder notesField() => find.byWidgetPredicate(
    (w) => w is TextField && w.minLines == 3,
    description: 'campo de observações',
  );

  Finder statusOutroField() => find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is AppTextField && w.label == _t.whichStatusHint,
    ),
    matching: find.byType(TextField),
  );

  Finder saveFinder() => find.descendant(
    of: find.byType(FinancialFormPage),
    matching: find.byType(PrimaryButton),
  );

  PrimaryButton saveButton(WidgetTester tester) =>
      tester.widget<PrimaryButton>(saveFinder());

  bool canSave(WidgetTester tester) => saveButton(tester).onPressed != null;

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

  Future<void> fillMinimumValidForm(WidgetTester tester) async {
    await tester.enterText(nameTextField(), 'Paciente Teste');
    await pickDate(tester);
    await tester.enterText(amountField(), '18000');
    await tester.pump();
  }

  group('criação: campos obrigatórios', () {
    testWidgets('salvar começa desabilitado', (tester) async {
      await pumpForm(tester);

      expect(canSave(tester), isFalse);
      expect(find.text(_t.registerPaymentButton), findsOneWidget);
      expect(find.text(_t.formPageTitle), findsOneWidget);
    });

    testWidgets('nome vazio não habilita, mesmo com data e valor', (
      tester,
    ) async {
      await pumpForm(tester);

      await pickDate(tester);
      await tester.enterText(amountField(), '18000');
      await tester.pump();

      expect(canSave(tester), isFalse);
    });

    testWidgets('sem data não habilita, mesmo com nome e valor', (
      tester,
    ) async {
      await pumpForm(tester);

      await tester.enterText(nameTextField(), 'Paciente Teste');
      await tester.enterText(amountField(), '18000');
      await tester.pump();

      expect(canSave(tester), isFalse);
    });

    testWidgets('valor zero não habilita, mesmo com nome e data', (
      tester,
    ) async {
      await pumpForm(tester);

      await tester.enterText(nameTextField(), 'Paciente Teste');
      await pickDate(tester);
      await tester.pump();

      expect(canSave(tester), isFalse);
    });

    testWidgets('nome + data + valor > 0 habilitam', (tester) async {
      await pumpForm(tester);

      await fillMinimumValidForm(tester);

      expect(canSave(tester), isTrue);
    });
  });

  group('criação: fluxo de salvar', () {
    testWidgets('chama add (não update) com os dados do formulário', (
      tester,
    ) async {
      await pumpForm(tester);

      final date = await pickDate(tester);
      await tester.enterText(nameTextField(), '  Paciente Novo  ');
      await tester.enterText(amountField(), '18000');
      await tester.pump();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      final entry =
          verify(() => financialRepository.add(captureAny())).captured.single
              as FinancialEntry;
      expect(entry.patientName, 'Paciente Novo');
      expect(entry.date, date);
      expect(entry.amount, 180);
      expect(entry.id, isNotEmpty);
      expect(entry.patientId, isNull);
      verifyNever(() => financialRepository.update(any()));
    });

    testWidgets('selecionar paciente pelo picker leva patientId/patientName', (
      tester,
    ) async {
      await pumpForm(tester, patients: [_registeredPatient]);

      await tester.tap(find.byIcon(Icons.list_alt_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maria Teste'));
      await tester.pumpAndSettle();
      await pickDate(tester);
      await tester.enterText(amountField(), '18000');
      await tester.pump();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      final entry =
          verify(() => financialRepository.add(captureAny())).captured.single
              as FinancialEntry;
      expect(entry.patientId, 'p1');
      expect(entry.patientName, 'Maria Teste');
    });

    testWidgets('editar o nome manualmente depois do picker limpa patientId', (
      tester,
    ) async {
      await pumpForm(tester, patients: [_registeredPatient]);

      await tester.tap(find.byIcon(Icons.list_alt_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maria Teste'));
      await tester.pumpAndSettle();

      await tester.enterText(nameTextField(), 'Maria Teste Editada');
      await pickDate(tester);
      await tester.enterText(amountField(), '18000');
      await tester.pump();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      final entry =
          verify(() => financialRepository.add(captureAny())).captured.single
              as FinancialEntry;
      expect(entry.patientId, isNull);
      expect(entry.patientName, 'Maria Teste Editada');
    });

    testWidgets('sucesso volta para a tela anterior e avisa', (tester) async {
      await pumpForm(tester);

      await fillMinimumValidForm(tester);
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('LISTA'), findsOneWidget);
      expect(find.byType(AppInfoBottomSheet), findsOneWidget);
      expect(find.text(_t.paymentRegisteredSuccess), findsOneWidget);
    });
  });

  group('edição', () {
    testWidgets('vem preenchido e o CTA é "Salvar alterações"', (
      tester,
    ) async {
      await pumpForm(tester, existing: _existing);

      expect(find.text(_t.editFormPageTitle), findsOneWidget);
      expect(
        tester.widget<TextField>(nameTextField()).controller!.text,
        'Maria Teste',
      );
      expect(find.text('12/08/2026'), findsOneWidget);
      expect(
        tester.widget<TextField>(amountField()).controller!.text,
        'R\$ 180,00',
      );
      expect(
        tester.widget<TextField>(notesField()).controller!.text,
        'NOTA-EXISTENTE-X',
      );
      expect(find.text(_t.saveChangesButton), findsOneWidget);
      expect(canSave(tester), isTrue);
    });

    testWidgets('update preserva o id e os demais campos editados', (
      tester,
    ) async {
      await pumpForm(tester, existing: _existing);

      await tester.enterText(amountField(), '20000');
      await tester.pump();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      final entry =
          verify(
                () => financialRepository.update(captureAny()),
              ).captured.single
              as FinancialEntry;
      expect(entry.id, 'f1');
      expect(entry.patientId, 'p1');
      expect(entry.amount, 200);
      verifyNever(() => financialRepository.add(any()));
      expect(find.text(_t.paymentUpdatedSuccess), findsOneWidget);
    });

    testWidgets('nome longo de paciente cabe em até 2 linhas, sem ellipsis', (
      tester,
    ) async {
      final longNameEntry = FinancialEntry(
        id: 'f2',
        patientName: 'Maria Aparecida Fernandes de Albuquerque Souza',
        date: DateTime(2026, 8, 12),
        amount: 180,
      );
      await pumpForm(tester, existing: longNameEntry);

      final field = tester.widget<TextField>(nameTextField());
      expect(field.maxLines, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('"Excluir lançamento" só aparece em edição', (tester) async {
      await pumpForm(tester);
      expect(find.text(_t.deletePaymentTitle), findsNothing);

      await pumpForm(tester, existing: _existing);
      expect(find.text(_t.deletePaymentTitle), findsOneWidget);
    });
  });

  group('status', () {
    for (final status in PaymentStatus.values) {
      testWidgets('é possível selecionar ${status.name}', (tester) async {
        await pumpForm(tester);

        // "Outro" também existe como opção de forma de pagamento; o chip de
        // status vem primeiro na árvore.
        await tester.tap(find.text(status.label(AppLanguage.portuguese)).first);
        await tester.pump();

        expect(
          find.text(_t.whichStatusHint),
          status == PaymentStatus.other ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('"Qual status" preserva a validação de mínimo 4 caracteres', (
      tester,
    ) async {
      await pumpForm(tester);
      await fillMinimumValidForm(tester);

      await tester.tap(find.text('Outro').first);
      await tester.pump();
      expect(canSave(tester), isFalse);

      await tester.enterText(statusOutroField(), 'ab');
      await tester.pump();
      expect(find.text(_t.statusMinCharsError), findsOneWidget);
      expect(canSave(tester), isFalse);

      await tester.enterText(statusOutroField(), 'abcd');
      await tester.pump();
      expect(find.text(_t.statusMinCharsError), findsNothing);
      expect(canSave(tester), isTrue);
    });
  });

  group('forma de pagamento', () {
    for (final method in PaymentMethod.values) {
      testWidgets('é possível selecionar ${method.name}', (tester) async {
        await pumpForm(tester);

        // "Outro" também existe como opção de status; o chip de forma de
        // pagamento vem depois na árvore.
        await tester.tap(find.text(method.label(AppLanguage.portuguese)).last);
        await tester.pump();

        expect(
          find.text(_t.whichPaymentMethodHint),
          method == PaymentMethod.other ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('continua opcional: salvar sem escolher forma de pagamento', (
      tester,
    ) async {
      await pumpForm(tester);
      await fillMinimumValidForm(tester);

      expect(canSave(tester), isTrue);
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      final entry =
          verify(() => financialRepository.add(captureAny())).captured.single
              as FinancialEntry;
      expect(entry.paymentMethod, isNull);
    });
  });

  group('observações', () {
    testWidgets('continua opcional e o texto é preservado com trim', (
      tester,
    ) async {
      await pumpForm(tester);
      await fillMinimumValidForm(tester);
      await tester.enterText(notesField(), '  observação de teste  ');
      await tester.pump();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      final entry =
          verify(() => financialRepository.add(captureAny())).captured.single
              as FinancialEntry;
      expect(entry.notes, 'observação de teste');
    });

    testWidgets('sem observação, salva com string vazia', (tester) async {
      await pumpForm(tester);
      await fillMinimumValidForm(tester);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      final entry =
          verify(() => financialRepository.add(captureAny())).captured.single
              as FinancialEntry;
      expect(entry.notes, '');
    });
  });

  group('exclusão', () {
    testWidgets('mostra a confirmação atual', (tester) async {
      await pumpForm(tester, existing: _existing);

      await tester.tap(find.text(_t.deletePaymentTitle));
      await tester.pumpAndSettle();

      expect(find.byType(AppConfirmSheet), findsOneWidget);
      expect(find.text(_t.deletePaymentDescription), findsOneWidget);
    });

    testWidgets('cancelar não exclui', (tester) async {
      await pumpForm(tester, existing: _existing);

      await tester.tap(find.text(_t.deletePaymentTitle));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppConfirmSheet),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      verifyNever(() => financialRepository.delete(any()));
      expect(find.text('LISTA'), findsNothing);
    });

    testWidgets('confirmar chama delete com o id certo e volta', (
      tester,
    ) async {
      await pumpForm(tester, existing: _existing);

      await tester.tap(find.text(_t.deletePaymentTitle));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppConfirmSheet),
          matching: find.text(_t.deleteLabel),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => financialRepository.delete('f1')).called(1);
      expect(find.text('LISTA'), findsOneWidget);
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
