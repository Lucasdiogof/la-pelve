import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/pregnancy.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';

void main() {
  group('Pregnancy.toJson/fromJson', () {
    test('round-trips a fully populated value', () {
      const pregnancy = Pregnancy(
        pregnancyLoss: false,
        deliveryMethod: DeliveryMethod.cesarean,
        deliveryComplication: DeliveryComplication.laceration,
        hadComplications: true,
        complicationDescription: 'Sangramento leve',
        approximateBabyWeight: '3.2kg',
        forcepsOrVacuumUse: false,
      );

      final restored = Pregnancy.fromJson(pregnancy.toJson());

      expect(restored, pregnancy);
    });

    test('fromJson defaults to nulls for an empty map', () {
      final restored = Pregnancy.fromJson(const {});

      expect(restored, const Pregnancy());
    });
  });

  group('Pregnancy.copyWith', () {
    test('clears a nullable bool when explicitly passed null', () {
      const original = Pregnancy(hadComplications: true);
      final updated = original.copyWith(hadComplications: null);

      expect(updated.hadComplications, isNull);
    });

    test('keeps the field when the argument is omitted', () {
      const original = Pregnancy(hadComplications: true);
      final updated = original.copyWith(approximateBabyWeight: '3kg');

      expect(updated.hadComplications, isTrue);
      expect(updated.approximateBabyWeight, '3kg');
    });
  });
}
