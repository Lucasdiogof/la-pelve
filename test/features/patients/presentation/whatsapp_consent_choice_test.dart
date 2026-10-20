import 'package:flutter_test/flutter_test.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_consent.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patient_form_state.dart';
import 'package:la_pelve/features/patients/presentation/cubit/whatsapp_consent_choice.dart';

void main() {
  const phone = '11933334444';
  const e164 = '+5511933334444';

  PatientFormState formState(
    String rawPhone, {
    Map<String, bool> manual = const {},
  }) => PatientFormState(
    patient: Patient(
      id: 'p1',
      createdAt: DateTime.utc(2026, 1, 1),
      personalInfo: PersonalInfo(phone: rawPhone),
    ),
    manualConsentChoices: manual,
  );

  PatientConsent consent(String contactValue) => PatientConsent(
    id: 'c1',
    patientId: 'p1',
    channel: 'whatsapp',
    purpose: 'reminders',
    contactValue: contactValue,
    grantedAt: DateTime.utc(2026, 1, 1),
  );

  group('resolveWhatsappConsentChoice', () {
    test('is off when the phone is not a valid mobile', () {
      expect(
        resolveWhatsappConsentChoice(
          originalConsent: consent(e164),
          formState: formState('123', manual: {e164: true}),
        ),
        isFalse,
      );
    });

    test('is on when the phone matches the original consent', () {
      expect(
        resolveWhatsappConsentChoice(
          originalConsent: consent(e164),
          formState: formState(phone),
        ),
        isTrue,
      );
    });

    test('is off when there is no original consent', () {
      expect(
        resolveWhatsappConsentChoice(
          originalConsent: null,
          formState: formState(phone),
        ),
        isFalse,
      );
    });

    test('is off when the original consent was for another number', () {
      expect(
        resolveWhatsappConsentChoice(
          originalConsent: consent('+5511911112222'),
          formState: formState(phone),
        ),
        isFalse,
      );
    });

    test('manual choice wins over the original consent', () {
      expect(
        resolveWhatsappConsentChoice(
          originalConsent: consent(e164),
          formState: formState(phone, manual: {e164: false}),
        ),
        isFalse,
      );
      expect(
        resolveWhatsappConsentChoice(
          originalConsent: null,
          formState: formState(phone, manual: {e164: true}),
        ),
        isTrue,
      );
    });

    test('manual choice for another number is ignored', () {
      expect(
        resolveWhatsappConsentChoice(
          originalConsent: consent(e164),
          formState: formState(phone, manual: {'+5511911112222': false}),
        ),
        isTrue,
      );
    });
  });
}
