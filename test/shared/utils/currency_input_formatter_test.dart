import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/shared/utils/currency_input_formatter.dart';

void main() {
  group('CurrencyInputFormatter.format', () {
    test('formats a value below a thousand', () {
      expect(CurrencyInputFormatter.format(150.5), 'R\$ 150,50');
    });

    test('adds thousands separators', () {
      expect(CurrencyInputFormatter.format(1234567.89), 'R\$ 1.234.567,89');
    });

    test('formats zero', () {
      expect(CurrencyInputFormatter.format(0), 'R\$ 0,00');
    });
  });

  group('CurrencyInputFormatter.parse', () {
    test('parses a formatted string back to cents-precision double', () {
      expect(CurrencyInputFormatter.parse('R\$ 1.234,56'), 1234.56);
    });

    test('returns 0 for a string with no digits', () {
      expect(CurrencyInputFormatter.parse('R\$ '), 0);
    });

    test('round-trips through format', () {
      const value = 987.65;
      final formatted = CurrencyInputFormatter.format(value);
      expect(CurrencyInputFormatter.parse(formatted), value);
    });
  });

  group('CurrencyInputFormatter.formatEditUpdate', () {
    final formatter = CurrencyInputFormatter();

    test('clears the field when all digits are removed', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: 'R\$ 1,00'),
        const TextEditingValue(text: ''),
      );
      expect(result.text, '');
    });

    test('formats raw digit input as currency', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '15050'),
      );
      expect(result.text, 'R\$ 150,50');
    });

    test('places the cursor at the end of the formatted text', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '500'),
      );
      expect(result.selection.baseOffset, result.text.length);
    });
  });
}
