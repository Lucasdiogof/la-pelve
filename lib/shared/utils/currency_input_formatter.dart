import 'package:flutter/services.dart';
import 'package:la_pelve/shared/utils/money_format.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  /// Campo de valor é sempre no formato brasileiro e sem sinal.
  static String format(double value) => formatBrl(value.abs());

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
