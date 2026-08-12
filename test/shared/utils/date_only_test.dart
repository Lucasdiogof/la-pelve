import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/shared/utils/date_only.dart';

void main() {
  group('dateOnly', () {
    test('formats as yyyy-MM-dd ignoring time', () {
      expect(dateOnly(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
    });

    test('pads single-digit month and day', () {
      expect(dateOnly(DateTime(2026, 1, 2)), '2026-01-02');
    });
  });
}
