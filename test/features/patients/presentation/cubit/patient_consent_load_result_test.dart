import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_consent.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_consent_repository.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patient_consent_load_result.dart';

class _MockPatientConsentRepository extends Mock
    implements PatientConsentRepository {}

void main() {
  late _MockPatientConsentRepository repository;

  setUp(() {
    repository = _MockPatientConsentRepository();
  });

  group('loadActiveWhatsappConsent', () {
    test('Success com um consentimento ativo é carregado como tal', () async {
      final consent = PatientConsent(
        id: 'c1',
        patientId: 'p1',
        channel: kWhatsappChannel,
        purpose: kAppointmentReminderPurpose,
        contactValue: '+5562999999999',
        grantedAt: DateTime.utc(2026, 1, 1),
      );
      when(
        () => repository.getActive(
          patientId: 'p1',
          channel: kWhatsappChannel,
          purpose: kAppointmentReminderPurpose,
        ),
      ).thenAnswer((_) async => Success(consent));

      final result = await loadActiveWhatsappConsent(
        repository: repository,
        patientId: 'p1',
      );

      expect(result, isA<PatientConsentLoadSucceeded>());
      expect((result as PatientConsentLoadSucceeded).consent, consent);
    });

    test(
      'Success(null) é carregado como "de fato não há consentimento", '
      'nunca como falha',
      () async {
        when(
          () => repository.getActive(
            patientId: 'p1',
            channel: kWhatsappChannel,
            purpose: kAppointmentReminderPurpose,
          ),
        ).thenAnswer((_) async => const Success(null));

        final result = await loadActiveWhatsappConsent(
          repository: repository,
          patientId: 'p1',
        );

        expect(result, isA<PatientConsentLoadSucceeded>());
        expect((result as PatientConsentLoadSucceeded).consent, isNull);
      },
    );

    test(
      'Error NUNCA é interpretado como ausência de consentimento: vira '
      'PatientConsentLoadFailed, não PatientConsentLoadSucceeded(null)',
      () async {
        when(
          () => repository.getActive(
            patientId: 'p1',
            channel: kWhatsappChannel,
            purpose: kAppointmentReminderPurpose,
          ),
        ).thenAnswer((_) async => Error(NetworkFailure()));

        final result = await loadActiveWhatsappConsent(
          repository: repository,
          patientId: 'p1',
        );

        expect(result, isA<PatientConsentLoadFailed>());
        expect(result, isNot(isA<PatientConsentLoadSucceeded>()));
      },
    );

    test(
      'um timeout do repositório (surfaced as Error) também vira '
      'PatientConsentLoadFailed, nunca um loading sem fim',
      () async {
        // O repositório real já traduz timeout em Error(NetworkFailure());
        // aqui simulamos exatamente esse contrato.
        when(
          () => repository.getActive(
            patientId: 'p1',
            channel: kWhatsappChannel,
            purpose: kAppointmentReminderPurpose,
          ),
        ).thenAnswer((_) async => Error(NetworkFailure()));

        final result = await loadActiveWhatsappConsent(
          repository: repository,
          patientId: 'p1',
        ).timeout(const Duration(seconds: 1));

        expect(result, isA<PatientConsentLoadFailed>());
      },
    );

    test('retry: uma segunda chamada após Error pode ter sucesso', () async {
      var callCount = 0;
      when(
        () => repository.getActive(
          patientId: 'p1',
          channel: kWhatsappChannel,
          purpose: kAppointmentReminderPurpose,
        ),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return Error(NetworkFailure());
        return const Success(null);
      });

      final firstAttempt = await loadActiveWhatsappConsent(
        repository: repository,
        patientId: 'p1',
      );
      expect(firstAttempt, isA<PatientConsentLoadFailed>());

      final retryAttempt = await loadActiveWhatsappConsent(
        repository: repository,
        patientId: 'p1',
      );
      expect(retryAttempt, isA<PatientConsentLoadSucceeded>());
      expect(callCount, 2);
    });
  });
}
