import 'package:flutter_test/flutter_test.dart';
import 'package:la_pelve/shared/utils/br_phone_e164.dart';

void main() {
  group('normalizeBrMobileToE164', () {
    test('normalizes a masked valid mobile number', () {
      expect(normalizeBrMobileToE164('(62) 9 9999-9999'), '+5562999999999');
    });

    test('normalizes a valid mobile number with digits only', () {
      expect(normalizeBrMobileToE164('62999999999'), '+5562999999999');
    });

    test('returns null for a 10-digit landline', () {
      expect(normalizeBrMobileToE164('6233334444'), isNull);
    });

    test('returns null for 11 digits missing the 9 after the DDD', () {
      expect(normalizeBrMobileToE164('62833334444'), isNull);
    });

    test('returns null for the wrong amount of digits', () {
      expect(normalizeBrMobileToE164('6299999'), isNull);
      expect(normalizeBrMobileToE164('629999999999'), isNull);
    });

    test('ignores non-digit formatting characters', () {
      expect(normalizeBrMobileToE164('(62) 9.9999-9999'), '+5562999999999');
    });

    test('returns null for an invalid DDD', () {
      expect(normalizeBrMobileToE164('00999999999'), isNull);
      expect(normalizeBrMobileToE164('10999999999'), isNull);
    });

    test('does not invent a missing leading 9', () {
      // 10 digitos (DDD + 8): nunca e tratado como celular valido.
      expect(normalizeBrMobileToE164('6233334444'), isNull);
    });
  });
}
