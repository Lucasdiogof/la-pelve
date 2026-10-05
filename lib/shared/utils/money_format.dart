import 'package:la_pelve/core/l10n/app_language.dart';

/// Formata um valor em reais (BRL) para exibição.
///
/// A moeda é sempre BRL, porque é nela que os valores estão guardados; o
/// idioma de exibição só decide os separadores:
/// - português e espanhol: `R$ 1.450,00`;
/// - inglês: `R$ 1,450.00`.
///
/// Só apresentação: não arredonda nem altera o valor guardado além das duas
/// casas decimais exibidas.
String formatBrl(
  double value, {
  AppLanguage language = AppLanguage.portuguese,
}) {
  final (thousands, decimal) = switch (language) {
    AppLanguage.english => (',', '.'),
    AppLanguage.portuguese || AppLanguage.spanish => ('.', ','),
  };
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final intDigits = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < intDigits.length; i++) {
    if (i > 0 && (intDigits.length - i) % 3 == 0) buffer.write(thousands);
    buffer.write(intDigits[i]);
  }
  final sign = value < 0 && fixed != '0.00' ? '-' : '';
  return '${sign}R\$ $buffer$decimal${parts[1]}';
}
