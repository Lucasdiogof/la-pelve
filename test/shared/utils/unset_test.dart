import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/shared/utils/unset.dart';

void main() {
  group('unsetOr', () {
    test('returns the fallback when value is kUnset', () {
      expect(unsetOr<String>(kUnset, 'fallback'), 'fallback');
    });

    test('returns the given value when it is not kUnset', () {
      expect(unsetOr<String>('explicit', 'fallback'), 'explicit');
    });

    test('returns null when explicitly passed null (clearing the field)', () {
      expect(unsetOr<String>(null, 'fallback'), isNull);
    });
  });
}
