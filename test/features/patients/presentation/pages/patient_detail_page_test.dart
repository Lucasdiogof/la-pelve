// Testes de CARACTERIZAÇÃO do detalhe do paciente: capturam o comportamento
// (dados exibidos, regras de visibilidade, valores ausentes e fluxos), não o
// visual. Servem para provar que a reforma visual não perde informação nem
// fluxo. Não verificam raio, padding, card antigo nem posição exata.
//
// Os testes usam uma viewport bem alta para que o ListView construa a ficha
// inteira de uma vez (ele é preguiçoso) e para que nenhum rolamento seja
// necessário. Para as AÇÕES, os localizadores aceitam a posição antiga e a
// nova (ex.: "Excluir paciente" como ícone do AppBar ou como botão no fim da
// ficha), porque o que se garante é o comportamento da ação.

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
import 'package:la_pelve/features/patients/presentation/widgets/patient_attachments_tab.dart';
import 'package:la_pelve/features/patients/presentation/widgets/patient_detail/patient_detail_shared.dart';
import 'package:la_pelve/shared/widgets/app_confirm_sheet.dart';
import 'package:la_pelve/shared/widgets/app_date_field.dart';
import 'package:la_pelve/shared/widgets/app_sheet.dart';

class _FakePatientRepository extends Mock implements PatientRepository {}

class _FakeConsentRepository extends Mock implements PatientConsentRepository {}

class _FakeAttachmentRepository extends Mock implements AttachmentRepository {}

const _t = PatientsStrings(AppLanguage.portuguese);

Patient _patient({
  String id = 'p1',
  PersonalInfo personalInfo = const PersonalInfo(
    name: 'Maria Teste',
    gender: Gender.female,
  ),
  MedicalHistory medicalHistory = const MedicalHistory(),
  GynecologicalHistory gynecologicalHistory = const GynecologicalHistory(),
  ObstetricHistory obstetricHistory = const ObstetricHistory(),
  SurgicalHistory surgicalHistory = const SurgicalHistory(),
  UrinaryFunction urinaryFunction = const UrinaryFunction(),
  SexualFunction sexualFunction = const SexualFunction(),
  BowelFunction bowelFunction = const BowelFunction(),
  TreatmentPlan treatmentPlan = const TreatmentPlan(),
  Discharge? discharge,
  double? consultationFee,
}) => Patient(
  id: id,
  createdAt: DateTime(2026, 1, 1),
  personalInfo: personalInfo,
  medicalHistory: medicalHistory,
  gynecologicalHistory: gynecologicalHistory,
  obstetricHistory: obstetricHistory,
  surgicalHistory: surgicalHistory,
  urinaryFunction: urinaryFunction,
  sexualFunction: sexualFunction,
  bowelFunction: bowelFunction,
  treatmentPlan: treatmentPlan,
  discharge: discharge,
  consultationFee: consultationFee,
);

/// Ficha totalmente preenchida, com marcadores únicos (-X) em todo texto livre.
Patient _fullPatient({Gender gender = Gender.female, Discharge? discharge}) =>
    _patient(
      personalInfo: PersonalInfo(
        name: 'Maria Teste',
        socialName: 'SOCIAL-X',
        age: 41,
        phone: '(62) 99999-0000',
        occupation: 'OCUPACAO-X',
        gender: gender,
      ),
      medicalHistory: const MedicalHistory(
        chiefComplaint: 'QUEIXA-X',
        symptomsOnset: 'INICIO-X',
        hasMedicalDiagnosis: true,
        medicalDiagnosis: 'DIAGNOSTICO-X',
        hadPreviousTreatment: true,
        treatmentDescription: 'TRATAMENTOANT-X',
        hasChronicDiseases: true,
        chronicDiseasesDescription: 'CRONICAS-X',
        takesContinuousMedication: true,
        medicationsDescription: 'MEDICACOES-X',
        smoking: false,
        consumesAlcohol: true,
        practicesPhysicalActivity: false,
        imagingExams: 'EXAMES-X',
      ),
      gynecologicalHistory: GynecologicalHistory(
        ageAtMenarche: 12,
        currentlyMenstruating: false,
        isInMenopause: true,
        approximateLastMenstruationDate: DateTime(2024, 5, 10),
        regularCycle: true,
        menopause: true,
        hormoneReplacementTherapy: true,
        hormoneReplacementTherapyDescription: 'TRH-X',
        menstrualFlow: MenstrualFlow.moderate,
        crampsScore0to10: 7,
        contraceptiveMethod: ContraceptiveMethod.pill,
        pelvicPainOutsidePeriod: true,
        bleedingOutsidePeriod: false,
        endometriosis: false,
        polycysticOvarySyndrome: true,
        recurrentUrinaryInfections: false,
        recurrentVaginalInfections: true,
      ),
      obstetricHistory: ObstetricHistory(
        hasBeenPregnant: true,
        pregnancyCount: 2,
        pregnancies: const [
          Pregnancy(pregnancyLoss: true, lossDescription: 'PERDA-X'),
          Pregnancy(
            pregnancyLoss: false,
            deliveryMethod: DeliveryMethod.vaginal,
            deliveryComplication: DeliveryComplication.laceration,
            forcepsOrVacuumUse: true,
            approximateBabyWeight: 'PESOBEBE-X',
            hadComplications: true,
            complicationDescription: 'COMPLICACAO-X',
          ),
        ],
        currentlyPregnant: true,
        desiredDeliveryMethod: DeliveryMethod.cesarean,
        gestationWeeks: 20,
        estimatedDeliveryDate: DateTime(2026, 12, 1),
        highRiskPregnancy: true,
        highRiskPregnancyDescription: 'ALTORISCO-X',
      ),
      surgicalHistory: const SurgicalHistory(
        surgeries: {GynecologicalSurgery.other},
        otherSurgeryDescription: 'CIRURGIA-X',
      ),
      urinaryFunction: const UrinaryFunction(
        urgency: true,
        urgencyDescription: 'URGENCIA-X',
        stressIncontinence: true,
        incontinenceTriggers: {IncontinenceTrigger.other},
        otherTriggerDescription: 'GATILHO-X',
        nocturnalEnuresis: true,
        enuresisDescription: 'ENURESE-X',
        hesitancy: true,
        hesitancyDescription: 'HESITACAO-X',
        urinaryStraining: true,
        urinaryStrainingDescription: 'ESFORCOURINA-X',
        postVoidDribbling: true,
        dribblingDescription: 'GOTEJAMENTO-X',
        incompleteEmptying: true,
        incompleteEmptyingDescription: 'INCOMPLETO-X',
        urgencyAssociatedLeakage: true,
        leakageAmount: LeakageAmount.small,
        usesPads: true,
        padsPerDay: 3,
        painOrBurningWhenUrinating: false,
        weakUrinaryStream: true,
      ),
      sexualFunction: const SexualFunction(
        sexuallyActive: true,
        needsLubricant: true,
        orgasmDifficulty: true,
        orgasmDifficultyDescription: 'ORGASMO-X',
        sexualDesire: SexualDesire.reduced,
        sexualActivityFrequency: 'FREQSEXUAL-X',
        painDuringPenetration: true,
        penetrationPainType: PenetrationPainType.deep,
        painDuringOrAfterIntercourse: true,
        painIntensity0to10: 6,
        dryness: true,
      ),
      bowelFunction: const BowelFunction(
        bowelFrequency: BowelFrequency.custom,
        customFrequencyValue: 4,
        usesLaxative: true,
        laxativeDescription: 'LAXANTE-X',
        strainsToDefecate: true,
        painToDefecate: false,
        incompleteEmptying: true,
        gasIncontinence: false,
        fecalIncontinence: false,
        bristolScale: BristolScale.type4,
        obstructionSensation: true,
        fecalUrgency: false,
        hemorrhoids: true,
      ),
      treatmentPlan: const TreatmentPlan(
        physiotherapyDiagnosis: 'DIAGFISIO-X',
        treatmentGoal: 'OBJETIVO-X',
        treatmentApproach: 'CONDUTA-X',
        suggestedFrequency: 'FREQSUGERIDA-X',
      ),
      discharge: discharge,
      consultationFee: 1450,
    );

void main() {
  late _FakePatientRepository repository;
  late _FakeConsentRepository consentRepository;
  late List<Patient> stored;

  setUpAll(() => registerFallbackValue(_patient()));

  setUp(() async {
    await sl.reset();
    consentRepository = _FakeConsentRepository();
    when(
      () => consentRepository.getActive(
        patientId: any(named: 'patientId'),
        channel: any(named: 'channel'),
        purpose: any(named: 'purpose'),
      ),
    ).thenAnswer((_) async => const Success<PatientConsent?>(null));
    final attachmentRepository = _FakeAttachmentRepository();
    when(
      () => attachmentRepository.getForPatient(any()),
    ).thenAnswer((_) async => const Success([]));
    sl
      ..registerSingleton<PatientConsentRepository>(consentRepository)
      ..registerSingleton<AttachmentRepository>(attachmentRepository);
  });

  tearDown(() async => sl.reset());

  /// Monta a lista falsa ("LISTA") e empilha o detalhe por cima, como no app.
  Future<GoRouter> pumpDetail(
    WidgetTester tester,
    Patient patient, {
    Size size = const Size(390, 20000),
    double textScale = 1,
    bool deleteFails = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    SharedPreferences.setMockInitialValues({});

    stored = [patient];
    repository = _FakePatientRepository();
    when(() => repository.getAll()).thenAnswer((_) async => Success(stored));
    when(() => repository.update(any())).thenAnswer((invocation) async {
      stored = [invocation.positionalArguments.first as Patient];
      return const Success(null);
    });
    when(() => repository.delete(any())).thenAnswer((_) async {
      if (deleteFails) return Error(ServerFailure());
      stored = [];
      return const Success(null);
    });

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
        GoRoute(
          path: '/pacientes/:id/editar',
          builder: (_, state) => Scaffold(
            body: Text(
              'EDITAR ${state.pathParameters['id']} '
              '${(state.extra! as Patient).personalInfo.name}',
            ),
          ),
        ),
        GoRoute(
          path: '/pacientes/:id/evolucao',
          builder: (_, state) =>
              Scaffold(body: Text('EVOLUCAO ${state.pathParameters['id']}')),
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
    return router;
  }

  InfoRow? rowOf(WidgetTester tester, String label) {
    final rows = tester
        .widgetList<InfoRow>(find.byType(InfoRow))
        .where((r) => r.label == label)
        .toList();
    return rows.isEmpty ? null : rows.first;
  }

  String valueOf(WidgetTester tester, String label) {
    final row = rowOf(tester, label);
    expect(row, isNotNull, reason: 'linha "$label" não encontrada');
    return row!.value;
  }

  Finder sectionTitle(String title) => find.text(title.toUpperCase());

  /// Toca na ação de excluir, esteja ela no AppBar (ícone) ou no fim da ficha.
  Future<void> tapDelete(WidgetTester tester) async {
    final byTooltip = find.byTooltip(_t.deletePatientTooltip);
    final target = byTooltip.evaluate().isNotEmpty
        ? byTooltip
        : find.text(_t.deletePatientTitle);
    await tester.ensureVisible(target.first);
    await tester.tap(target.first);
    await tester.pumpAndSettle();
  }

  Future<void> tapReopen(WidgetTester tester) async {
    final target = find.text('Reabrir').evaluate().isNotEmpty
        ? find.text('Reabrir')
        : find.text('Reabrir tratamento');
    await tester.ensureVisible(target.first);
    await tester.tap(target.first);
    await tester.pumpAndSettle();
  }

  Future<void> confirmSheet(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AppConfirmSheet),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  // -------------------------------------------------------------------
  // A, B, C: regra por sexo para as seções ginecológica e obstétrica
  // -------------------------------------------------------------------
  group('seções por sexo', () {
    testWidgets('masculino: sem ginecológico e sem obstétrico', (tester) async {
      await pumpDetail(tester, _fullPatient(gender: Gender.male));

      expect(sectionTitle(_t.sectionGynecologicalHistory), findsNothing);
      expect(sectionTitle(_t.sectionObstetricHistory), findsNothing);
      // As demais seções continuam presentes.
      expect(sectionTitle(_t.sectionAnamnesis), findsOneWidget);
      expect(sectionTitle(_t.sectionUrinaryFunction), findsOneWidget);
    });

    testWidgets('feminino: com ginecológico e com obstétrico', (tester) async {
      await pumpDetail(tester, _fullPatient());

      expect(sectionTitle(_t.sectionGynecologicalHistory), findsOneWidget);
      expect(sectionTitle(_t.sectionObstetricHistory), findsOneWidget);
    });

    testWidgets('Gender.other: a regra atual TAMBÉM mostra as duas seções', (
      tester,
    ) async {
      await pumpDetail(tester, _fullPatient(gender: Gender.other));

      expect(sectionTitle(_t.sectionGynecologicalHistory), findsOneWidget);
      expect(sectionTitle(_t.sectionObstetricHistory), findsOneWidget);
    });

    testWidgets('sexo não informado: as duas seções ficam ocultas', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _patient(personalInfo: const PersonalInfo(name: 'Maria Teste')),
      );

      expect(sectionTitle(_t.sectionGynecologicalHistory), findsNothing);
      expect(sectionTitle(_t.sectionObstetricHistory), findsNothing);
    });

    testWidgets('todas as seções clínicas existem e na ordem atual', (
      tester,
    ) async {
      await pumpDetail(tester, _fullPatient());

      final titles = [
        _t.sectionPersonalData,
        _t.sectionAnamnesis,
        _t.sectionGynecologicalHistory,
        _t.sectionObstetricHistory,
        _t.sectionSurgicalHistory,
        _t.sectionUrinaryFunction,
        _t.sectionSexualFunction,
        _t.sectionBowelFunction,
        _t.sectionTreatmentPlan,
        _t.sectionConsultationFee,
      ];
      final tops = [
        for (final title in titles) tester.getTopLeft(sectionTitle(title)).dy,
      ];
      expect(
        tops,
        orderedEquals([...tops]..sort()),
        reason: 'ordem das seções',
      );
    });
  });

  // -------------------------------------------------------------------
  // D: linhas condicionais (pergunta-mãe false/null esconde; true mostra)
  // -------------------------------------------------------------------
  group('linhas condicionais', () {
    testWidgets('anamnese: detalhe só aparece com a pergunta-mãe = true', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _patient(
          medicalHistory: const MedicalHistory(
            hasMedicalDiagnosis: false,
            medicalDiagnosis: 'ESCONDIDO-X',
            hadPreviousTreatment: false,
            treatmentDescription: 'ESCONDIDO-X',
            hasChronicDiseases: false,
            chronicDiseasesDescription: 'ESCONDIDO-X',
            takesContinuousMedication: false,
            medicationsDescription: 'ESCONDIDO-X',
          ),
        ),
      );

      expect(rowOf(tester, _t.fieldWhichDiagnosis), isNull);
      expect(rowOf(tester, _t.fieldWhichTreatment), isNull);
      expect(rowOf(tester, _t.fieldWhichDiseases), isNull);
      expect(rowOf(tester, _t.fieldWhichMedications), isNull);
      expect(find.textContaining('ESCONDIDO-X'), findsNothing);

      await pumpDetail(tester, _fullPatient());
      expect(valueOf(tester, _t.fieldWhichDiagnosis), 'DIAGNOSTICO-X');
      expect(valueOf(tester, _t.fieldWhichTreatment), 'TRATAMENTOANT-X');
      expect(valueOf(tester, _t.fieldWhichDiseases), 'CRONICAS-X');
      expect(valueOf(tester, _t.fieldWhichMedications), 'MEDICACOES-X');
    });

    testWidgets('função urinária: detalhes, gatilhos e absorventes', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _patient(
          urinaryFunction: const UrinaryFunction(
            urgency: false,
            urgencyDescription: 'ESCONDIDO-X',
            stressIncontinence: false,
            usesPads: false,
            padsPerDay: 9,
          ),
        ),
      );
      expect(rowOf(tester, _t.fieldUrgencyDetail), isNull);
      expect(rowOf(tester, _t.fieldTriggers), isNull);
      expect(rowOf(tester, _t.fieldHowManyPerDay), isNull);
      expect(rowOf(tester, _t.fieldLeakageAmount), isNull);

      await pumpDetail(tester, _fullPatient());
      expect(valueOf(tester, _t.fieldUrgencyDetail), 'URGENCIA-X');
      expect(rowOf(tester, _t.fieldTriggers), isNotNull);
      expect(valueOf(tester, _t.fieldHowManyPerDay), '3');
      expect(rowOf(tester, _t.fieldLeakageAmount), isNotNull);
    });

    testWidgets('função sexual: ativa mostra o bloco; inativa esconde', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _patient(
          sexualFunction: const SexualFunction(
            sexuallyActive: false,
            sexualActivityFrequency: 'ESCONDIDO-X',
          ),
        ),
      );
      expect(rowOf(tester, _t.fieldSexualActivityFrequency), isNull);
      expect(rowOf(tester, _t.fieldPainType), isNull);

      await pumpDetail(tester, _fullPatient());
      expect(valueOf(tester, _t.fieldSexualActivityFrequency), 'FREQSEXUAL-X');
      expect(rowOf(tester, _t.fieldPainType), isNotNull);
    });

    testWidgets('função intestinal: laxante e frequência personalizada', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _patient(
          bowelFunction: const BowelFunction(
            usesLaxative: false,
            laxativeDescription: 'ESCONDIDO-X',
            bowelFrequency: BowelFrequency.onceDaily,
          ),
        ),
      );
      expect(rowOf(tester, _t.fieldWhichLaxative), isNull);
      expect(rowOf(tester, _t.fieldTimesPerWeek), isNull);

      await pumpDetail(tester, _fullPatient());
      expect(valueOf(tester, _t.fieldWhichLaxative), 'LAXANTE-X');
      expect(valueOf(tester, _t.fieldTimesPerWeek), '4');
    });

    testWidgets('ginecológico: menopausa/TRH só com as condições certas', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _patient(
          gynecologicalHistory: const GynecologicalHistory(
            currentlyMenstruating: true,
            hormoneReplacementTherapy: false,
            hormoneReplacementTherapyDescription: 'ESCONDIDO-X',
          ),
        ),
      );
      expect(rowOf(tester, _t.fieldInMenopause), isNull);
      expect(rowOf(tester, _t.fieldApproxLastMenstruationDate), isNull);
      expect(rowOf(tester, _t.fieldHormoneReplacementDetail), isNull);

      await pumpDetail(tester, _fullPatient());
      expect(rowOf(tester, _t.fieldInMenopause), isNotNull);
      expect(valueOf(tester, _t.fieldApproxLastMenstruationDate), '10/05/2024');
      expect(valueOf(tester, _t.fieldHormoneReplacementDetail), 'TRH-X');
    });

    testWidgets('obstétrico: gestação atual e gestações anteriores', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _patient(
          obstetricHistory: const ObstetricHistory(
            currentlyPregnant: false,
            hasBeenPregnant: false,
            gestationWeeks: 30,
          ),
        ),
      );
      expect(rowOf(tester, _t.fieldGestationWeeks), isNull);
      expect(rowOf(tester, _t.fieldPregnancyCount), isNull);
      expect(find.text(_t.pregnancyNumber(1)), findsNothing);

      await pumpDetail(tester, _fullPatient());
      expect(valueOf(tester, _t.fieldGestationWeeks), '20');
      expect(valueOf(tester, _t.fieldPregnancyCount), '2');
      // Uma entrada por gestação cadastrada, com os dados de cada uma.
      expect(find.text(_t.pregnancyNumber(1)), findsOneWidget);
      expect(find.text(_t.pregnancyNumber(2)), findsOneWidget);
      expect(find.text('PERDA-X'), findsOneWidget);
      expect(find.text('PESOBEBE-X'), findsOneWidget);
      expect(find.text('COMPLICACAO-X'), findsOneWidget);
    });

    testWidgets('cirurgias: descrição só quando "outra" está marcada', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _patient(
          surgicalHistory: const SurgicalHistory(
            surgeries: {},
            otherSurgeryDescription: 'ESCONDIDO-X',
          ),
        ),
      );
      expect(rowOf(tester, _t.fieldWhichSurgery), isNull);
      expect(
        valueOf(tester, _t.fieldSurgeries),
        PatientDetailFormat.naoInformado(),
      );

      await pumpDetail(tester, _fullPatient());
      expect(valueOf(tester, _t.fieldWhichSurgery), 'CIRURGIA-X');
    });
  });

  // -------------------------------------------------------------------
  // E: valores ausentes / false / true / zero
  // -------------------------------------------------------------------
  group('valores', () {
    testWidgets('null e vazio viram "Não informado"', (tester) async {
      await pumpDetail(
        tester,
        _patient(personalInfo: const PersonalInfo(name: 'Maria Teste')),
      );

      for (final label in [
        _t.fieldSex,
        _t.fieldAge,
        _t.fieldOccupation,
        _t.fieldFirstConsultationFee,
        _t.fieldChiefComplaint,
        _t.fieldHasMedicalDiagnosis,
      ]) {
        expect(valueOf(tester, label), 'Não informado', reason: label);
      }
    });

    testWidgets('texto só com espaços também vira "Não informado"', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _patient(
          personalInfo: const PersonalInfo(
            name: 'Maria Teste',
            occupation: '   ',
          ),
          medicalHistory: const MedicalHistory(chiefComplaint: '  '),
        ),
      );

      expect(valueOf(tester, _t.fieldOccupation), 'Não informado');
      expect(valueOf(tester, _t.fieldChiefComplaint), 'Não informado');
    });

    testWidgets('false vira "Não", true vira "Sim" e null "Não informado"', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _patient(
          medicalHistory: const MedicalHistory(
            smoking: false,
            consumesAlcohol: true,
          ),
        ),
      );

      expect(valueOf(tester, _t.fieldSmoking), 'Não');
      expect(valueOf(tester, _t.fieldConsumesAlcohol), 'Sim');
      expect(valueOf(tester, _t.fieldPhysicalActivity), 'Não informado');
    });

    testWidgets('zero é mostrado como "0" (não vira "Não informado")', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _patient(
          personalInfo: const PersonalInfo(name: 'Bebê', age: 0),
          urinaryFunction: const UrinaryFunction(usesPads: true, padsPerDay: 0),
        ),
      );

      expect(valueOf(tester, _t.fieldAge), '0');
      expect(valueOf(tester, _t.fieldHowManyPerDay), '0');
    });

    testWidgets('valor da consulta usa o formatador BRL atual', (tester) async {
      await pumpDetail(tester, _fullPatient());
      expect(valueOf(tester, _t.fieldFirstConsultationFee), 'R\$ 1.450,00');

      await pumpDetail(tester, _patient(consultationFee: 0));
      expect(valueOf(tester, _t.fieldFirstConsultationFee), 'R\$ 0,00');
    });

    test('PatientDetailFormat: regras de formatação', () {
      expect(PatientDetailFormat.text(null), 'Não informado');
      expect(PatientDetailFormat.text('  '), 'Não informado');
      expect(PatientDetailFormat.text('  a  '), 'a');
      expect(PatientDetailFormat.yesNo(true), 'Sim');
      expect(PatientDetailFormat.yesNo(false), 'Não');
      expect(PatientDetailFormat.yesNo(null), 'Não informado');
      expect(PatientDetailFormat.intValue(0), '0');
      expect(PatientDetailFormat.intValue(null), 'Não informado');
      expect(PatientDetailFormat.dateValue(DateTime(2026, 9, 3)), '03/09/2026');
      expect(PatientDetailFormat.dateValue(null), 'Não informado');
    });
  });

  // -------------------------------------------------------------------
  // J: nenhum dado clínico some
  // -------------------------------------------------------------------
  group('completude dos dados', () {
    testWidgets('todo texto livre e dado pessoal aparece na tela', (
      tester,
    ) async {
      await pumpDetail(tester, _fullPatient());

      for (final marker in [
        'Maria Teste',
        'SOCIAL-X',
        '(62) 99999-0000',
        'OCUPACAO-X',
        'QUEIXA-X',
        'INICIO-X',
        'DIAGNOSTICO-X',
        'TRATAMENTOANT-X',
        'CRONICAS-X',
        'MEDICACOES-X',
        'EXAMES-X',
        'TRH-X',
        'PERDA-X',
        'PESOBEBE-X',
        'COMPLICACAO-X',
        'ALTORISCO-X',
        'CIRURGIA-X',
        'URGENCIA-X',
        'GATILHO-X',
        'ENURESE-X',
        'HESITACAO-X',
        'ESFORCOURINA-X',
        'GOTEJAMENTO-X',
        'INCOMPLETO-X',
        'ORGASMO-X',
        'FREQSEXUAL-X',
        'LAXANTE-X',
        'DIAGFISIO-X',
        'OBJETIVO-X',
        'CONDUTA-X',
        'FREQSUGERIDA-X',
      ]) {
        expect(find.textContaining(marker), findsWidgets, reason: marker);
      }
      expect(find.textContaining('41'), findsWidgets, reason: 'idade');
      expect(find.textContaining('Feminino'), findsWidgets, reason: 'sexo');
      expect(find.textContaining('1.450,00'), findsWidgets, reason: 'consulta');
    });

    testWidgets('nome social: linha própria só quando existe', (tester) async {
      await pumpDetail(tester, _fullPatient());
      expect(valueOf(tester, _t.fieldSocialName), 'SOCIAL-X');

      await pumpDetail(tester, _patient());
      expect(rowOf(tester, _t.fieldSocialName), isNull);
    });

    testWidgets('sexo e idade seguem como linhas dos dados pessoais', (
      tester,
    ) async {
      await pumpDetail(tester, _fullPatient());

      expect(valueOf(tester, _t.fieldSex), 'Feminino');
      expect(valueOf(tester, _t.fieldAge), '41');
      expect(valueOf(tester, _t.fieldOccupation), 'OCUPACAO-X');
    });

    testWidgets('lembretes pelo WhatsApp: sem consentimento ativo', (
      tester,
    ) async {
      await pumpDetail(tester, _fullPatient());

      expect(valueOf(tester, _t.whatsappReminderFieldLabel), 'desativados');
    });

    testWidgets('lembretes pelo WhatsApp: com consentimento ativo', (
      tester,
    ) async {
      when(
        () => consentRepository.getActive(
          patientId: any(named: 'patientId'),
          channel: any(named: 'channel'),
          purpose: any(named: 'purpose'),
        ),
      ).thenAnswer(
        (_) async => Success<PatientConsent?>(
          PatientConsent(
            id: 'c1',
            patientId: 'p1',
            channel: kWhatsappChannel,
            purpose: kAppointmentReminderPurpose,
            contactValue: '+5562999990000',
            grantedAt: DateTime(2026, 8, 20),
          ),
        ),
      );
      await pumpDetail(tester, _fullPatient());

      expect(
        valueOf(tester, _t.whatsappReminderFieldLabel),
        'ativados desde 20/08/2026',
      );
    });
  });

  // -------------------------------------------------------------------
  // F: alta
  // -------------------------------------------------------------------
  group('alta', () {
    final discharge = Discharge(
      date: DateTime(2026, 8, 20),
      reason: DischargeReason.referred,
      finalNote: 'NOTAFINAL-X',
    );

    testWidgets('sem alta: oferece encerrar e não oferece reabrir', (
      tester,
    ) async {
      await pumpDetail(tester, _fullPatient());

      expect(find.text('Encerrar tratamento'), findsWidgets);
      expect(find.text('Reabrir'), findsNothing);
      expect(find.text('Reabrir tratamento'), findsNothing);
      expect(find.textContaining('20/08/2026'), findsNothing);
    });

    testWidgets('com alta: motivo, data e observação final aparecem', (
      tester,
    ) async {
      await pumpDetail(tester, _fullPatient(discharge: discharge));

      expect(find.textContaining('20/08/2026'), findsWidgets);
      expect(find.textContaining('Encaminhamento'), findsWidgets);
      expect(find.textContaining('NOTAFINAL-X'), findsWidgets);
      // Já encerrado: não oferece encerrar de novo.
      expect(find.text('Encerrar tratamento'), findsNothing);
    });

    testWidgets('com alta sem observação final não mostra "null"', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _fullPatient(
          discharge: Discharge(
            date: DateTime(2026, 8, 20),
            reason: DischargeReason.completed,
          ),
        ),
      );

      expect(find.textContaining('null'), findsNothing);
      expect(find.textContaining('20/08/2026'), findsWidgets);
    });

    testWidgets('encerrar: sheet pede data e motivo e grava a alta', (
      tester,
    ) async {
      await pumpDetail(tester, _fullPatient());

      await tester.tap(find.text('Encerrar tratamento').first);
      await tester.pumpAndSettle();

      // O botão de confirmar só habilita com data e motivo.
      final confirm = find.widgetWithText(
        ElevatedButton,
        _t.confirmCloseTreatmentButton,
      );
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);

      await tester.tap(find.byType(AppDateField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppSheet),
          matching: find.text('Encaminhamento'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find
            .descendant(
              of: find.byType(AppSheet),
              matching: find.byType(TextField),
            )
            .last,
        'Nota digitada',
      );
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNotNull);

      await tester.tap(confirm);
      await tester.pumpAndSettle();

      final saved =
          verify(() => repository.update(captureAny())).captured.single
              as Patient;
      expect(saved.id, 'p1');
      expect(saved.discharge, isNotNull);
      expect(saved.discharge!.reason, DischargeReason.referred);
      expect(saved.discharge!.finalNote, 'Nota digitada');
      final today = DateUtils.dateOnly(DateTime.now());
      expect(DateUtils.dateOnly(saved.discharge!.date), today);
      // O resto da ficha não é alterado pelo encerramento.
      expect(saved.personalInfo.name, 'Maria Teste');
      expect(saved.treatmentPlan.treatmentGoal, 'OBJETIVO-X');
    });

    testWidgets('reabrir: confirma e grava discharge = null', (tester) async {
      await pumpDetail(tester, _fullPatient(discharge: discharge));

      await tapReopen(tester);
      await confirmSheet(tester, 'Reabrir');

      final saved =
          verify(() => repository.update(captureAny())).captured.single
              as Patient;
      expect(saved.discharge, isNull);
      expect(saved.personalInfo.name, 'Maria Teste');
    });

    testWidgets('reabrir: cancelar na confirmação não grava nada', (
      tester,
    ) async {
      await pumpDetail(tester, _fullPatient(discharge: discharge));

      await tapReopen(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AppConfirmSheet),
          matching: find.text('Cancelar'),
        ),
      );
      await tester.pumpAndSettle();

      verifyNever(() => repository.update(any()));
    });
  });

  // -------------------------------------------------------------------
  // G, H, I: ações, navegação e exclusão
  // -------------------------------------------------------------------
  group('ações e navegação', () {
    testWidgets('editar abre a edição com o paciente', (tester) async {
      await pumpDetail(tester, _fullPatient());

      await tester.tap(find.byTooltip(_t.editPatientTooltip));
      await tester.pumpAndSettle();

      expect(find.text('EDITAR p1 Maria Teste'), findsOneWidget);
    });

    testWidgets('ver evolução abre as evoluções do paciente', (tester) async {
      await pumpDetail(tester, _fullPatient());

      await tester.tap(find.text(_t.viewEvolutionButton));
      await tester.pumpAndSettle();

      expect(find.text('EVOLUCAO p1'), findsOneWidget);
    });

    testWidgets('começa na aba Informações e a aba Anexos abre os anexos', (
      tester,
    ) async {
      await pumpDetail(tester, _fullPatient());

      expect(sectionTitle(_t.sectionPersonalData), findsOneWidget);
      expect(find.byType(PatientAttachmentsTab), findsNothing);

      await tester.tap(find.text(_t.tabAttachments));
      await tester.pumpAndSettle();

      expect(find.byType(PatientAttachmentsTab), findsOneWidget);
    });

    testWidgets('na aba Anexos não há editar nem excluir', (tester) async {
      await pumpDetail(tester, _fullPatient());
      expect(find.byTooltip(_t.editPatientTooltip), findsOneWidget);

      await tester.tap(find.text(_t.tabAttachments));
      await tester.pumpAndSettle();

      expect(find.byTooltip(_t.editPatientTooltip), findsNothing);
      expect(find.byTooltip(_t.deletePatientTooltip), findsNothing);
    });

    testWidgets('excluir: confirma, faz soft delete e volta para a lista', (
      tester,
    ) async {
      await pumpDetail(tester, _fullPatient());

      await tapDelete(tester);
      expect(find.byType(AppConfirmSheet), findsOneWidget);
      expect(find.textContaining('Maria Teste'), findsWidgets);
      await confirmSheet(tester, _t.deleteLabel);

      verify(() => repository.delete('p1')).called(1);
      expect(find.text('LISTA'), findsOneWidget);
    });

    testWidgets('excluir: cancelar não apaga e permanece no detalhe', (
      tester,
    ) async {
      await pumpDetail(tester, _fullPatient());

      await tapDelete(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AppConfirmSheet),
          matching: find.text('Cancelar'),
        ),
      );
      await tester.pumpAndSettle();

      verifyNever(() => repository.delete(any()));
      expect(find.text('LISTA'), findsNothing);
      expect(find.textContaining('Maria Teste'), findsWidgets);
    });

    testWidgets('excluir com falha: não volta para a lista', (tester) async {
      await pumpDetail(tester, _fullPatient(), deleteFails: true);

      await tapDelete(tester);
      await confirmSheet(tester, _t.deleteLabel);

      verify(() => repository.delete('p1')).called(1);
      expect(find.text('LISTA'), findsNothing);
    });
  });
}
