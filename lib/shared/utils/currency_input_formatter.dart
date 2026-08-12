import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  static String format(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intDigits = parts[0].replaceAll('-', '');
    final buffer = StringBuffer();
    for (var i = 0; i < intDigits.length; i++) {
      if (i > 0 && (intDigits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intDigits[i]);
    }
    return 'R\$ $buffer,${parts[1]}';
  }

  static double parse(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.parse(digits) / 100;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = format(int.parse(digits) / 100);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
