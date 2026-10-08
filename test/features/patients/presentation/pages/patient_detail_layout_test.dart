// Testes da REFORMA VISUAL do detalhe do paciente (Etapa B): cabeçalho fixo,
// um painel por seção, linhas horizontais/verticais, TRATAMENTO e exclusão no
// fim, "Ver evolução" só em Informações e comportamento em telas pequenas.
//
// Carregam a Poppins REAL do app: as larguras da fonte padrão de teste (Ahem)
// não representam o que o usuário vê. O comportamento de dados/fluxos está em
// patient_detail_page_test.dart (caracterização, Etapa A).

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
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_consent.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_enums.dart';
import 'package:la_pelve/features/patients/domain/entities/pregnancy.dart';
import 'package:la_pelve/features/patients/domain/repositories/attachment_repository.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_consent_repository.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_repository.dart';
import 'package:la_pelve/features/patients/l10n/patients_strings.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/features/patients/presentation/pages/patient_detail_page.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';
import 'package:la_pelve/shared/widgets/app_bottom_action_bar.dart';
import 'package:la_pelve/shared/widgets/app_list_row.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';

class _FakePatientRepository extends Mock implements PatientRepository {}

class _FakeConsentRepository extends Mock implements PatientConsentRepository {}

class _FakeAttachmentRepository extends Mock implements AttachmentRepository {}

const _t = PatientsStrings(AppLanguage.portuguese);
const _extremeName = 'Maria Aparecida Fernandes de Albuquerque Souza';
const _longText =
    'Perda involuntária de urina aos esforços (tosse, espirro, riso) com '
    'piora progressiva nos últimos seis meses, associada a sensação de peso '
    'na região pélvica ao final do dia e desconforto após longos períodos '
    'em pé.';

Patient _patient({
  PersonalInfo personalInfo = const PersonalInfo(
    name: 'Rubia Fernandes',
    age: 41,
    phone: '(62) 99999-0000',
    occupation: 'Funcionária pública',
    gender: Gender.female,
  ),
  MedicalHistory medicalHistory = const MedicalHistory(
    chiefComplaint: 'Dor pélvica',
  ),
  ObstetricHistory obstetricHistory = const ObstetricHistory(),
  TreatmentPlan treatmentPlan = const TreatmentPlan(),
  Discharge? discharge,
}) => Patient(
  id: 'p1',
  createdAt: DateTime(2026, 1, 1),
  personalInfo: personalInfo,
  medicalHistory: medicalHistory,
  obstetricHistory: obstetricHistory,
  treatmentPlan: treatmentPlan,
  discharge: discharge,
  consultationFee: 250,
);

/// Paciente "pior caso": nome extremo, textos longos, várias gestações e alta
/// com observação final longa.
Patient _worstCase() => _patient(
  personalInfo: const PersonalInfo(
    name: _extremeName,
    age: 58,
    phone: '(62) 99999-0000',
    occupation:
        'Professora aposentada de educação básica e coordenadora pedagógica',
    gender: Gender.female,
  ),
  medicalHistory: const MedicalHistory(
    chiefComplaint: _longText,
    hasMedicalDiagnosis: true,
    medicalDiagnosis: _longText,
  ),
  obstetricHistory: const ObstetricHistory(
    hasBeenPregnant: true,
    pregnancyCount: 3,
    pregnancies: [
      Pregnancy(pregnancyLoss: true, lossDescription: _longText),
      Pregnancy(
        pregnancyLoss: false,
        deliveryMethod: DeliveryMethod.vaginal,
        deliveryComplication: DeliveryComplication.laceration,
        forcepsOrVacuumUse: true,
        approximateBabyWeight: '3,8 kg',
        hadComplications: true,
        complicationDescription: _longText,
      ),
      Pregnancy(
        pregnancyLoss: false,
        deliveryMethod: DeliveryMethod.cesarean,
        approximateBabyWeight: '3,1 kg',
        hadComplications: false,
      ),
    ],
  ),
  treatmentPlan: const TreatmentPlan(
    physiotherapyDiagnosis: _longText,
    treatmentGoal: _longText,
    treatmentApproach: _longText,
    suggestedFrequency: 'Duas vezes por semana nas primeiras oito semanas',
  ),
  discharge: Discharge(
    date: DateTime(2026, 8, 20),
    reason: DischargeReason.referred,
    finalNote: _longText,
  ),
);

void main() {
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

  setUp(() async {
    await sl.reset();
    final consent = _FakeConsentRepository();
    when(
      () => consent.getActive(
        patientId: any(named: 'patientId'),
        channel: any(named: 'channel'),
        purpose: any(named: 'purpose'),
      ),
    ).thenAnswer((_) async => const Success<PatientConsent?>(null));
    final attachments = _FakeAttachmentRepository();
    when(
      () => attachments.getForPatient(any()),
    ).thenAnswer((_) async => const Success([]));
    sl
      ..registerSingleton<PatientConsentRepository>(consent)
      ..registerSingleton<AttachmentRepository>(attachments);
  });

  tearDown(() async => sl.reset());

  Future<void> pumpDetail(
    WidgetTester tester,
    Patient patient, {
    Size size = const Size(390, 20000),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    SharedPreferences.setMockInitialValues({});

    final repository = _FakePatientRepository();
    when(() => repository.getAll()).thenAnswer((_) async => Success([patient]));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('LISTA')),
        ),
        GoRoute(
          path: '/pacientes/:id',
          builder: (_, state) =>
              PatientDetailPage(patient: state.extra! as Patient),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        key: UniqueKey(),
        providers: [
          BlocProvider(
            create: (_) => PatientsCubit(repository)..ensureLoaded(),
          ),
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true,
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.push('/pacientes/${patient.id}', extra: patient));
    await tester.pumpAndSettle();
  }

  Finder inHeader(Finder f) =>
      find.descendant(of: find.byType(PatientHeader), matching: f);

  InfoRow row(WidgetTester tester, String label) => tester
      .widgetList<InfoRow>(find.byType(InfoRow))
      .firstWhere((r) => r.label == label);

  Finder rowFinder(String label) => find.byWidgetPredicate(
    (w) => w is InfoRow && w.label == label,
    description: 'InfoRow "$label"',
  );

  int lines(WidgetTester tester, Finder textFinder) {
    final paragraph = tester.renderObject<RenderParagraph>(textFinder);
    final length = paragraph.text.toPlainText().length;
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: length),
    );
    return boxes.map((b) => b.top.round()).toSet().length;
  }

  group('cabeçalho', () {
    testWidgets('mostra avatar, nome, idade · sexo e telefone', (tester) async {
      await pumpDetail(tester, _patient());

      expect(inHeader(find.text('Rubia Fernandes')), findsOneWidget);
      expect(inHeader(find.text('41 anos · Feminino')), findsOneWidget);
      expect(inHeader(find.text('(62) 99999-0000')), findsOneWidget);
      expect(inHeader(find.text('R')), findsOneWidget);
    });

    testWidgets('fica fora da rolagem (acima das abas e do conteúdo)', (
      tester,
    ) async {
      await pumpDetail(tester, _patient(), size: const Size(390, 700));
      final before = tester.getTopLeft(find.byType(PatientHeader));
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.byType(PatientHeader)), before);
    });

    testWidgets('campos ausentes são omitidos (nunca "Não informado")', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _patient(personalInfo: const PersonalInfo(name: 'Sem Dados')),
      );

      expect(inHeader(find.text('Sem Dados')), findsOneWidget);
      expect(inHeader(find.textContaining('Não informado')), findsNothing);
      expect(inHeader(find.textContaining('anos')), findsNothing);
      expect(inHeader(find.textContaining('·')), findsNothing);
      // Só inicial do avatar + nome: nenhuma linha vazia para campo ausente.
      expect(inHeader(find.byType(Text)), findsNWidgets(2));
    });

    testWidgets('só idade ou só sexo não deixa "·" pendurado', (tester) async {
      await pumpDetail(
        tester,
        _patient(personalInfo: const PersonalInfo(name: 'So Idade', age: 30)),
      );
      expect(inHeader(find.text('30 anos')), findsOneWidget);
      expect(inHeader(find.textContaining('·')), findsNothing);
    });

    testWidgets('alta aparece no cabeçalho; sem alta, não aparece', (
      tester,
    ) async {
      await pumpDetail(tester, _patient());
      expect(inHeader(find.textContaining('Com alta')), findsNothing);

      await pumpDetail(
        tester,
        _patient(
          discharge: Discharge(
            date: DateTime(2026, 8, 20),
            reason: DischargeReason.referred,
          ),
        ),
      );
      expect(inHeader(find.text('Com alta · 20/08/2026')), findsOneWidget);
    });

    testWidgets('telefone só no cabeçalho (fora de Dados pessoais)', (
      tester,
    ) async {
      await pumpDetail(tester, _patient());

      expect(find.text('(62) 99999-0000'), findsOneWidget);
      expect(rowFinder(_t.fieldPhone), findsNothing);
    });

    testWidgets('AppBar com título "Paciente" e só a ação de editar', (
      tester,
    ) async {
      await pumpDetail(tester, _patient());

      expect(find.text(_t.patientFallbackTitle), findsOneWidget);
      expect(find.byTooltip(_t.editPatientTooltip), findsOneWidget);
      expect(find.byTooltip(_t.deletePatientTooltip), findsNothing);
    });

    testWidgets('nome extremo cabe em até 3 linhas, sem reticências', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _worstCase(),
        size: const Size(360, 640),
        textScale: 1.3,
      );
      final name = inHeader(find.text(_extremeName));

      expect(lines(tester, name), lessThanOrEqualTo(3));
      expect(
        tester.renderObject<RenderParagraph>(name).didExceedMaxLines,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('header compacto', () {
    double avatarSize(WidgetTester tester) =>
        tester.getSize(find.byType(AppInitialAvatar)).height;

    testWidgets('390x844 em escala normal mantém o header atual', (
      tester,
    ) async {
      await pumpDetail(tester, _worstCase(), size: const Size(390, 844));

      expect(avatarSize(tester), 48);
      final style = tester
          .widget<Text>(inHeader(find.text(_extremeName)))
          .style;
      expect(style?.fontSize, 20);
    });

    testWidgets('texto 1,3x em tela larga (390) não entra no modo compacto', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _worstCase(),
        size: const Size(390, 844),
        textScale: 1.3,
      );
      expect(avatarSize(tester), 48);
    });

    testWidgets('360x640 com 1,3x entra no compacto sem perder informação', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _worstCase(),
        size: const Size(360, 640),
        textScale: 1.3,
      );

      expect(avatarSize(tester), 40);
      final name = inHeader(find.text(_extremeName));
      expect(tester.widget<Text>(name).style?.fontSize, 16);
      expect(lines(tester, name), lessThanOrEqualTo(3));
      expect(
        tester.renderObject<RenderParagraph>(name).didExceedMaxLines,
        isFalse,
      );
      expect(inHeader(find.text('58 anos · Feminino')), findsOneWidget);
      expect(inHeader(find.text('(62) 99999-0000')), findsOneWidget);
      expect(inHeader(find.text('Com alta · 20/08/2026')), findsOneWidget);
      expect(inHeader(find.text('M')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('compacto devolve altura útil à ficha', (tester) async {
      await pumpDetail(
        tester,
        _worstCase(),
        size: const Size(360, 640),
        textScale: 1.3,
      );
      final compactHeader = tester.getSize(find.byType(PatientHeader)).height;
      final compactList = tester.getSize(find.byType(ListView).first).height;

      await pumpDetail(
        tester,
        _worstCase(),
        size: const Size(390, 640),
        textScale: 1.3,
      );
      expect(
        compactHeader,
        lessThan(tester.getSize(find.byType(PatientHeader)).height),
      );
      expect(
        compactList,
        greaterThan(tester.getSize(find.byType(ListView).first).height),
      );
    });
  });

  group('painéis e linhas', () {
    testWidgets('Lembretes pelo WhatsApp usa layout vertical', (tester) async {
      await pumpDetail(tester, _patient(), size: const Size(360, 800));
      final finder = rowFinder(_t.whatsappReminderFieldLabel);

      expect(tester.widget<InfoRow>(finder).vertical, isTrue);
      final label = find.descendant(
        of: finder,
        matching: find.text(_t.whatsappReminderFieldLabel),
      );
      final value = find.descendant(
        of: finder,
        matching: find.text(_t.whatsappReminderInactive),
      );
      expect(tester.getTopLeft(value).dx, tester.getTopLeft(label).dx);
      expect(
        tester.getTopLeft(value).dy,
        greaterThan(tester.getBottomLeft(label).dy - 1),
      );
    });

    testWidgets('cada seção é UM painel (AppSection) e nenhum Card por dado', (
      tester,
    ) async {
      await pumpDetail(tester, _patient());

      final sections = tester.widgetList<InfoSection>(find.byType(InfoSection));
      expect(sections, isNotEmpty);
      for (final section in sections) {
        final panels = find.descendant(
          of: find.byWidget(section),
          matching: find.byType(AppSection),
        );
        expect(panels, findsOneWidget, reason: section.title);
      }
      expect(find.byType(Card), findsNothing);
      expect(find.byType(InfoRow), findsWidgets);
      for (final element in find.byType(InfoRow).evaluate()) {
        final insideCard = find.ancestor(
          of: find.byWidget(element.widget),
          matching: find.byType(Card),
        );
        expect(insideCard, findsNothing);
      }
    });

    testWidgets('linha horizontal: rótulo à esquerda, valor à direita', (
      tester,
    ) async {
      await pumpDetail(tester, _patient());
      final finder = rowFinder(_t.fieldAge);

      final label = tester.getTopLeft(
        find.descendant(of: finder, matching: find.text(_t.fieldAge)),
      );
      final value = tester.getTopRight(
        find.descendant(of: finder, matching: find.text('41')),
      );
      final rowRight = tester.getTopRight(finder).dx;

      expect(label.dy, closeTo(value.dy, 6));
      expect(value.dx, closeTo(rowRight - 16, 0.5));
      expect(label.dx, lessThan(value.dx));
      expect(row(tester, _t.fieldAge).vertical, isFalse);
    });

    testWidgets('linha vertical: valor abaixo do rótulo, alinhado à esquerda', (
      tester,
    ) async {
      await pumpDetail(tester, _patient());
      final finder = rowFinder(_t.fieldChiefComplaint);

      final label = find.descendant(
        of: finder,
        matching: find.text(_t.fieldChiefComplaint),
      );
      final value = find.descendant(
        of: finder,
        matching: find.text('Dor pélvica'),
      );

      expect(row(tester, _t.fieldChiefComplaint).vertical, isTrue);
      expect(
        tester.getTopLeft(value).dy,
        greaterThan(tester.getBottomLeft(label).dy - 1),
      );
      expect(tester.getTopLeft(value).dx, tester.getTopLeft(label).dx);
    });

    testWidgets('valor vertical curto também fica à esquerda (profissão)', (
      tester,
    ) async {
      await pumpDetail(tester, _patient());
      final finder = rowFinder(_t.fieldOccupation);
      final label = find.descendant(
        of: finder,
        matching: find.text(_t.fieldOccupation),
      );
      final value = find.descendant(
        of: finder,
        matching: find.text('Funcionária pública'),
      );

      expect(tester.getTopLeft(value).dx, tester.getTopLeft(label).dx);
    });

    testWidgets(
      'a escolha é semântica: sim/não, número e data são horizontais',
      (tester) async {
        await pumpDetail(tester, _patient());

        expect(row(tester, _t.fieldSex).vertical, isFalse);
        expect(row(tester, _t.fieldAge).vertical, isFalse);
        expect(row(tester, _t.fieldFirstConsultationFee).vertical, isFalse);
        expect(row(tester, _t.fieldOccupation).vertical, isTrue);
      },
    );

    testWidgets('gestações viram blocos leves "Gestação N", sem card', (
      tester,
    ) async {
      await pumpDetail(tester, _worstCase());

      expect(find.byType(PregnancyBlock), findsNWidgets(3));
      expect(find.text(_t.pregnancyNumber(1)), findsOneWidget);
      expect(find.text(_t.pregnancyNumber(2)), findsOneWidget);
      expect(find.text(_t.pregnancyNumber(3)), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });
  });

  group('ordem e ações', () {
    testWidgets('TRATAMENTO é a última seção e "Excluir paciente" vem depois', (
      tester,
    ) async {
      await pumpDetail(tester, _patient());

      final titles = tester
          .widgetList<InfoSection>(find.byType(InfoSection))
          .map((s) => s.title)
          .toList();
      expect(titles.last, _t.sectionTreatmentStatus);

      final treatmentY = tester
          .getTopLeft(find.text(_t.sectionTreatmentStatus.toUpperCase()))
          .dy;
      for (final title in titles.where((t) => t != titles.last)) {
        expect(
          tester.getTopLeft(find.text(title.toUpperCase())).dy,
          lessThan(treatmentY),
          reason: title,
        );
      }
      expect(
        tester.getTopLeft(find.text(_t.deletePatientTitle)).dy,
        greaterThan(treatmentY),
      );
    });

    testWidgets('"Ver evolução" só na aba Informações; Anexos fica sem barra', (
      tester,
    ) async {
      await pumpDetail(tester, _patient(), size: const Size(390, 844));

      expect(find.text(_t.viewEvolutionButton), findsOneWidget);
      expect(find.byType(AppBottomActionBar), findsOneWidget);
      expect(find.byTooltip(_t.editPatientTooltip), findsOneWidget);

      await tester.tap(find.text(_t.tabAttachments));
      await tester.pumpAndSettle();
      expect(find.text(_t.viewEvolutionButton), findsNothing);
      expect(find.byType(AppBottomActionBar), findsNothing);

      await tester.tap(find.text(_t.tabInformation));
      await tester.pumpAndSettle();
      expect(find.text(_t.viewEvolutionButton), findsOneWidget);
    });

    testWidgets('com alta: TRATAMENTO mostra status, motivo, data e reabrir', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _patient(
          discharge: Discharge(
            date: DateTime(2026, 8, 20),
            reason: DischargeReason.referred,
            finalNote: 'Nota final',
          ),
        ),
      );

      expect(find.text(_t.reopenTreatmentTitle), findsOneWidget);
      expect(find.text(_t.closeTreatmentButton), findsNothing);
      expect(row(tester, _t.fieldFinalNote).vertical, isTrue);
      expect(find.text('Nota final'), findsOneWidget);
    });
  });

  group('telas pequenas e texto grande', () {
    for (final size in const [Size(360, 640), Size(360, 800)]) {
      testWidgets('pior caso em ${size.width.toInt()}x${size.height.toInt()} '
          'com texto 1.3 não estoura', (tester) async {
        await pumpDetail(tester, _worstCase(), size: size, textScale: 1.3);

        expect(tester.takeException(), isNull);
        // Cabeçalho + abas + barra inferior deixam área útil para a ficha.
        final listHeight = tester.getSize(find.byType(ListView).first).height;
        expect(listHeight, greaterThan(size.height * 0.35));

        // Rola a ficha inteira: nada pode estourar em nenhum trecho.
        for (var i = 0; i < 40; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -300));
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
        expect(find.text(_t.deletePatientTitle), findsOneWidget);
      });
    }

    testWidgets('texto clínico longo aparece inteiro, sem reticências', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _worstCase(),
        size: const Size(360, 20000),
        textScale: 1.3,
      );

      final texts = find.descendant(
        of: find.byType(InfoRow),
        matching: find.byType(Text),
      );
      var checked = 0;
      for (final element in texts.evaluate()) {
        final paragraph = element.renderObject! as RenderParagraph;
        expect(paragraph.didExceedMaxLines, isFalse);
        final text = (element.widget as Text).data ?? '';
        if (text == _longText) checked++;
        final overflow = (element.widget as Text).overflow;
        expect(overflow == null || overflow == TextOverflow.clip, isTrue);
      }
      expect(checked, greaterThanOrEqualTo(6));
      expect(find.text(_longText), findsWidgets);
    });
  });
}
