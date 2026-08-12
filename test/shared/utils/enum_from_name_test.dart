import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/shared/utils/enum_from_name.dart';

enum _Fruit { apple, banana }

void main() {
  group('enumFromName', () {
    test('resolves a matching name', () {
      expect(enumFromName(_Fruit.values, 'banana'), _Fruit.banana);
    });

    test('returns null for an unknown name', () {
      expect(enumFromName(_Fruit.values, 'grape'), isNull);
    });

    test('returns null for null input', () {
      expect(enumFromName(_Fruit.values, null), isNull);
    });

    test('returns null for a non-String input', () {
      expect(enumFromName(_Fruit.values, 42), isNull);
    });
  });
}
