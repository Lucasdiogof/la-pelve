import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  static String format(String digits) {
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    if (limited.isEmpty) return '';
    final buffer = StringBuffer('(');
    buffer.write(limited.substring(0, limited.length < 2 ? limited.length : 2));
    if (limited.length <= 2) return buffer.toString();
    buffer.write(') ');
    final firstBlockLength = limited.length >= 11 ? 5 : 4;
    final firstBlockEnd = limited.length < 2 + firstBlockLength
        ? limited.length
        : 2 + firstBlockLength;
    buffer.write(limited.substring(2, firstBlockEnd));
    if (limited.length <= 2 + firstBlockLength) return buffer.toString();
    buffer.write('-');
    buffer.write(limited.substring(2 + firstBlockLength, limited.length));
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = format(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
