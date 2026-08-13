import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';

void main() {
  group('Patient.toJson/fromJson', () {
    test('round-trips a fully populated patient', () {
      final patient = Patient(
        id: 'p1',
        createdAt: DateTime.utc(2026, 1, 10, 12),
        personalInfo: const PersonalInfo(
          name: 'Maria',
          age: 32,
          phone: '11933334444',
          occupation: 'Professora',
          gender: Gender.female,
        ),
        medicalHistory: const MedicalHistory(
          chiefComplaint: 'Dor pélvica',
          hasMedicalDiagnosis: true,
          smoking: false,
        ),
        treatmentPlan: const TreatmentPlan(
          physiotherapyDiagnosis: 'Disfunção do assoalho pélvico',
        ),
        discharge: Discharge(
          date: DateTime.utc(2026, 2, 1),
          reason: DischargeReason.completed,
          finalNote: 'Paciente evoluiu bem',
        ),
        consultationFee: 180.5,
      );

      final json = patient.toJson();
      final restored = Patient.fromJson(json);

      expect(restored, patient);
    });

    test('round-trips a patient with only required fields', () {
      final patient = Patient(id: 'p2', createdAt: DateTime.utc(2026, 1, 1));

      final restored = Patient.fromJson(patient.toJson());

      expect(restored, patient);
      expect(restored.discharge, isNull);
      expect(restored.personalInfo.gender, isNull);
    });

    test('fromJson tolerates missing nested sections', () {
      final json = {
        'id': 'p3',
        'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
      };

      final patient = Patient.fromJson(json);

      expect(patient.personalInfo.name, '');
      expect(patient.medicalHistory.chiefComplaint, '');
      expect(patient.discharge, isNull);
    });
  });

  group('Patient.copyWith', () {
    test('keeps the original id and createdAt', () {
      final original = Patient(id: 'p1', createdAt: DateTime.utc(2026, 1, 1));
      final updated = original.copyWith(
        personalInfo: const PersonalInfo(name: 'Ana'),
      );

      expect(updated.id, original.id);
      expect(updated.createdAt, original.createdAt);
      expect(updated.personalInfo.name, 'Ana');
    });

    test('clears encerramento when explicitly passed null', () {
      final withEncerramento = Patient(
        id: 'p1',
        createdAt: DateTime.utc(2026, 1, 1),
        discharge: Discharge(
          date: DateTime.utc(2026, 2, 1),
          reason: DischargeReason.dropOut,
        ),
      );

      final reopened = withEncerramento.copyWith(discharge: null);

      expect(reopened.discharge, isNull);
    });

    test('keeps encerramento when the argument is omitted', () {
      final encerramento = Discharge(
        date: DateTime.utc(2026, 2, 1),
        reason: DischargeReason.dropOut,
      );
      final withEncerramento = Patient(
        id: 'p1',
        createdAt: DateTime.utc(2026, 1, 1),
        discharge: encerramento,
      );

      final updated = withEncerramento.copyWith(consultationFee: 200);

      expect(updated.discharge, encerramento);
    });
  });

  group('MedicalHistory.copyWith', () {
    test('clears a nullable bool when explicitly passed null', () {
      const original = MedicalHistory(smoking: true);
      final updated = original.copyWith(smoking: null);

      expect(updated.smoking, isNull);
    });

    test('keeps the field when the argument is omitted', () {
      const original = MedicalHistory(smoking: true);
      final updated = original.copyWith(chiefComplaint: 'Nova queixa');

      expect(updated.smoking, isTrue);
      expect(updated.chiefComplaint, 'Nova queixa');
    });
  });

  group('Patient equality', () {
    test('two patients with the same values are equal', () {
      final a = Patient(id: 'p1', createdAt: DateTime.utc(2026, 1, 1));
      final b = Patient(id: 'p1', createdAt: DateTime.utc(2026, 1, 1));

      expect(a, b);
    });

    test('patients with different ids are not equal', () {
      final a = Patient(id: 'p1', createdAt: DateTime.utc(2026, 1, 1));
      final b = Patient(id: 'p2', createdAt: DateTime.utc(2026, 1, 1));

      expect(a == b, isFalse);
    });
  });
}
