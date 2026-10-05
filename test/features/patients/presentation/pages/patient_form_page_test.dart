import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_consent.dart';
import 'package:la_pelve/features/patients/domain/repositories/attachment_repository.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_consent_repository.dart';
import 'package:la_pelve/features/patients/presentation/pages/patient_form_page.dart';

class _MockPatientConsentRepository extends Mock
    implements PatientConsentRepository {}

class _MockAttachmentRepository extends Mock implements AttachmentRepository {}

/// NUNCA pumpAndSettle() enquanto o consentimento carrega: a tela mostra um
/// CircularProgressIndicator indeterminado, cuja animação nunca "se
/// estabiliza" — pumpAndSettle() ficaria girando para sempre. Alguns pumps
/// fixos bastam: o mock resolve a chamada em 1-2 microtasks.
Future<void> _pumpPastLoading(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _MockPatientConsentRepository consentRepository;

  final patient = Patient(
    id: 'p1',
    createdAt: DateTime.utc(2026, 1, 1),
    personalInfo: const PersonalInfo(name: 'Joao Silva', phone: '62999999999'),
  );

  Future<GoRouter> pumpFormPage(WidgetTester tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) =>
              const Scaffold(body: Text('tela anterior')),
        ),
        GoRoute(
          path: '/form',
          builder: (context, state) => PatientFormPage(patient: patient),
        ),
      ],
    );

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => LocaleCubit(),
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    // Nota: GoRouter.push() devolve um Future que só resolve quando a rota
    // empurrada é fechada (pop) — igual Navigator.push(). Não dar await
    // aqui: só precisamos que a navegação aconteça, não que a tela feche.
    unawaited(router.push('/form'));
    await _pumpPastLoading(tester);
    return router;
  }

  setUp(() {
    consentRepository = _MockPatientConsentRepository();
    if (sl.isRegistered<PatientConsentRepository>()) {
      sl.unregister<PatientConsentRepository>();
    }
    if (sl.isRegistered<AttachmentRepository>()) {
      sl.unregister<AttachmentRepository>();
    }
    sl.registerLazySingleton<PatientConsentRepository>(
      () => consentRepository,
    );
    sl.registerLazySingleton<AttachmentRepository>(
      () => _MockAttachmentRepository(),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  group('PatientFormPage — falha ao carregar o consentimento ativo', () {
    testWidgets(
      'getActive() retornando Error mostra o estado de erro, não o '
      'formulário, com os botões Tentar novamente e Voltar',
      (tester) async {
        when(
          () => consentRepository.getActive(
            patientId: patient.id,
            channel: kWhatsappChannel,
            purpose: kAppointmentReminderPurpose,
          ),
        ).thenAnswer((_) async => Error(ServerFailure()));

        await pumpFormPage(tester);

        // Estado de erro visível.
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
        expect(find.text('Tentar novamente'), findsOneWidget);
        expect(find.text('Voltar'), findsOneWidget);

        // O formulário (wizard com os campos do passo "Dados pessoais") NÃO
        // aparece: nenhum campo de nome/telefone é montado.
        expect(find.text('Dados pessoais'), findsNothing);
        expect(find.byType(TextFormField), findsNothing);
      },
    );

    testWidgets(
      'tocar "Tentar novamente" refaz a chamada e, se a segunda tiver '
      'sucesso, monta o formulário normalmente',
      (tester) async {
        var callCount = 0;
        when(
          () => consentRepository.getActive(
            patientId: patient.id,
            channel: kWhatsappChannel,
            purpose: kAppointmentReminderPurpose,
          ),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return Error(ServerFailure());
          return const Success(null);
        });

        await pumpFormPage(tester);
        expect(find.text('Tentar novamente'), findsOneWidget);

        await tester.tap(find.text('Tentar novamente'));
        await _pumpPastLoading(tester);

        expect(callCount, 2);
        // Estado de erro sumiu e o formulário foi montado.
        expect(find.text('Tentar novamente'), findsNothing);
        expect(find.text('Dados pessoais'), findsOneWidget);
      },
    );

    testWidgets(
      'tocar "Tentar novamente" e a segunda chamada retornar um '
      'consentimento ativo também monta o formulário',
      (tester) async {
        final consent = PatientConsent(
          id: 'c1',
          patientId: patient.id,
          channel: kWhatsappChannel,
          purpose: kAppointmentReminderPurpose,
          contactValue: '+5562999999999',
          grantedAt: DateTime.utc(2026, 1, 1),
        );
        var callCount = 0;
        when(
          () => consentRepository.getActive(
            patientId: patient.id,
            channel: kWhatsappChannel,
            purpose: kAppointmentReminderPurpose,
          ),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return Error(ServerFailure());
          return Success(consent);
        });

        await pumpFormPage(tester);
        await tester.tap(find.text('Tentar novamente'));
        await _pumpPastLoading(tester);

        expect(callCount, 2);
        expect(find.text('Tentar novamente'), findsNothing);
        expect(find.text('Dados pessoais'), findsOneWidget);
      },
    );

    testWidgets('tocar "Voltar" fecha a tela normalmente', (tester) async {
      when(
        () => consentRepository.getActive(
          patientId: patient.id,
          channel: kWhatsappChannel,
          purpose: kAppointmentReminderPurpose,
        ),
      ).thenAnswer((_) async => Error(ServerFailure()));

      await pumpFormPage(tester);
      expect(find.text('Voltar'), findsOneWidget);

      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();

      // Voltou para a rota anterior; o estado de erro não está mais na tela.
      expect(find.text('tela anterior'), findsOneWidget);
      expect(find.text('Voltar'), findsNothing);
      expect(find.text('Tentar novamente'), findsNothing);
    });
  });
}
