// Estes testes carregam a Poppins REAL do app: as larguras de texto do teste
// padrão (fonte Ahem) não representam o que o usuário vê, e os requisitos
// abaixo (nome extremo em até 3 linhas; legenda da alta sem "·" pendurado)
// dependem das medidas reais.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_enums.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_repository.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/features/patients/presentation/pages/patients_list_page.dart';
import 'package:la_pelve/shared/widgets/app_list_row.dart';

class _FakePatientRepository extends Mock implements PatientRepository {}

int _lineCount(RenderParagraph paragraph, String text) {
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  return boxes.map((b) => b.top.round()).toSet().length;
}

void main() {
  const extremeName = 'Maria Aparecida Fernandes de Albuquerque Souza';
  const longName = 'Maria Aparecida Fernandes de Albuquerque';

  var seq = 0;
  Patient patient(String name, {Discharge? discharge}) => Patient(
    id: 'p${seq++}',
    createdAt: DateTime(2026, 1, 1).add(Duration(days: seq)),
    personalInfo: PersonalInfo(name: name, phone: '(62) 99999-0000'),
    discharge: discharge,
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

  Future<void> pumpList(
    WidgetTester tester,
    List<Patient> patients, {
    required Size size,
    required double textScale,
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
      routes: [GoRoute(path: '/', builder: (_, _) => const PatientsListPage())],
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
  }

  testWidgets(
    '360px x1.3: nomes de 47 e 40 caracteres cabem em até 3 linhas, sem reticências',
    (tester) async {
      await pumpList(
        tester,
        [patient(extremeName), patient(longName), patient('Deusimar Alves')],
        size: const Size(360, 800),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
      for (final name in [extremeName, longName]) {
        final paragraph = tester.renderObject<RenderParagraph>(find.text(name));
        expect(paragraph.didExceedMaxLines, isFalse, reason: name);
        expect(_lineCount(paragraph, name), lessThanOrEqualTo(3), reason: name);
        expect(tester.widget<Text>(find.text(name)).maxLines, 3);
      }
      // O sobrenome final aparece inteiro: as duas pacientes são distintas.
      expect(find.text(extremeName), findsOneWidget);
      expect(find.text(longName), findsOneWidget);
    },
  );

  testWidgets('a legenda da alta cabe numa linha em 390px x1.0', (
    tester,
  ) async {
    await pumpList(
      tester,
      [
        patient(
          'Maria Oliveira',
          discharge: Discharge(
            date: DateTime(2026, 7, 15),
            reason: DischargeReason.referred,
          ),
        ),
      ],
      size: const Size(390, 844),
      textScale: 1,
    );

    expect(
      find.text('(62) 99999-0000\nEncaminhamento · 15/07/2026'),
      findsOneWidget,
    );
  });

  testWidgets(
    '360px x1.3: "Encaminhamento" e a data vão para linhas separadas, sem "·"',
    (tester) async {
      await pumpList(
        tester,
        [
          patient(
            'Maria Oliveira',
            discharge: Discharge(
              date: DateTime(2026, 7, 15),
              reason: DischargeReason.referred,
            ),
          ),
        ],
        size: const Size(360, 800),
        textScale: 1.3,
      );

      expect(
        find.text('(62) 99999-0000\nEncaminhamento\n15/07/2026'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AppListRow),
          matching: find.textContaining('·'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('360px x1.3: legenda curta ("Alta · data") continua numa linha', (
    tester,
  ) async {
    await pumpList(
      tester,
      [
        patient(
          'Maria Oliveira',
          discharge: Discharge(
            date: DateTime(2026, 9, 3),
            reason: DischargeReason.completed,
          ),
        ),
      ],
      size: const Size(360, 800),
      textScale: 1.3,
    );

    expect(find.text('(62) 99999-0000\nAlta · 03/09/2026'), findsOneWidget);
  });
}
