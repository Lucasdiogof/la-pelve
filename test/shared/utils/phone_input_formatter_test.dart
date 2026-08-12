import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/shared/utils/phone_input_formatter.dart';

void main() {
  group('PhoneInputFormatter.format', () {
    test('returns an empty string for no digits', () {
      expect(PhoneInputFormatter.format(''), '');
    });

    test('formats a partial DDD', () {
      expect(PhoneInputFormatter.format('1'), '(1');
    });

    test('formats a complete DDD without closing it yet', () {
      expect(PhoneInputFormatter.format('11'), '(11');
    });

    test('formats a mobile number in progress', () {
      expect(PhoneInputFormatter.format('119333'), '(11) 9 333');
    });

    test('formats a complete 11-digit mobile number', () {
      expect(PhoneInputFormatter.format('11933334444'), '(11) 9 3333-4444');
    });

    test('formats a complete 10-digit landline number', () {
      expect(PhoneInputFormatter.format('1133334444'), '(11) 3 3334-444');
    });

    test('truncates input beyond 11 digits', () {
      expect(
        PhoneInputFormatter.format('119333344445555'),
        '(11) 9 3333-4444',
      );
    });
  });
}
