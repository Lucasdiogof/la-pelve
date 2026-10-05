import 'package:flutter_test/flutter_test.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_consent.dart';
import 'package:la_pelve/features/patients/domain/patient_consent_decision.dart';

void main() {
  final activeConsent = PatientConsent(
    id: 'c1',
    patientId: 'p1',
    channel: kWhatsappChannel,
    purpose: kAppointmentReminderPurpose,
    contactValue: '+5562999999999',
    grantedAt: DateTime.utc(2026, 1, 1),
  );

  group('PatientConsentDecision.compute', () {
    test('no original consent, switch off: does nothing', () {
      final decision = PatientConsentDecision.compute(
        original: null,
        newContactValue: '+5562999999999',
        choice: false,
      );

      expect(decision.mustRevokeOriginal, isFalse);
      expect(decision.mustGrantNew, isFalse);
    });

    test('no original consent, switch on: grants a new consent', () {
      final decision = PatientConsentDecision.compute(
        original: null,
        newContactValue: '+5562999999999',
        choice: true,
      );

      expect(decision.mustRevokeOriginal, isFalse);
      expect(decision.mustGrantNew, isTrue);
    });

    test(
      'active consent, same number, switch on: stays untouched',
      () {
        final decision = PatientConsentDecision.compute(
          original: activeConsent,
          newContactValue: activeConsent.contactValue,
          choice: true,
        );

        expect(decision.mustRevokeOriginal, isFalse);
        expect(decision.mustGrantNew, isFalse);
      },
    );

    test('active consent, same number, switch off: revokes only', () {
      final decision = PatientConsentDecision.compute(
        original: activeConsent,
        newContactValue: activeConsent.contactValue,
        choice: false,
      );

      expect(decision.mustRevokeOriginal, isTrue);
      expect(decision.mustGrantNew, isFalse);
    });

    test(
      'active consent, number changed, switch off: revokes the old one, grants nothing',
      () {
        final decision = PatientConsentDecision.compute(
          original: activeConsent,
          newContactValue: '+5562988888888',
          choice: false,
        );

        expect(decision.mustRevokeOriginal, isTrue);
        expect(decision.mustGrantNew, isFalse);
      },
    );

    test(
      'active consent, number changed, switch re-enabled: revokes the old '
      'one and grants a new consent for the new number',
      () {
        final decision = PatientConsentDecision.compute(
          original: activeConsent,
          newContactValue: '+5562988888888',
          choice: true,
        );

        expect(decision.mustRevokeOriginal, isTrue);
        expect(decision.mustGrantNew, isTrue);
      },
    );
  });
}
