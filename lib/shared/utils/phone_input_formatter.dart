import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  static String format(String digits) {
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    if (limited.isEmpty) return '';
    final buffer = StringBuffer('(');
    buffer.write(limited.substring(0, limited.length < 2 ? limited.length : 2));
    if (limited.length <= 2) return buffer.toString();
    buffer.write(') ');
    buffer.write(limited.substring(2, limited.length < 3 ? limited.length : 3));
    if (limited.length <= 3) return buffer.toString();
    buffer.write(' ');
    final middleEnd = limited.length < 7 ? limited.length : 7;
    buffer.write(limited.substring(3, middleEnd));
    if (limited.length <= 7) return buffer.toString();
    buffer.write('-');
    buffer.write(limited.substring(7, limited.length));
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
