// DDDs validos (Anatel). Fora dessa lista nao existe celular brasileiro.
const Set<int> _validBrazilianDdds = {
  11, 12, 13, 14, 15, 16, 17, 18, 19, //
  21, 22, 24, //
  27, 28, //
  31, 32, 33, 34, 35, 37, 38, //
  41, 42, 43, 44, 45, 46, 47, 48, 49, //
  51, 53, 54, 55, //
  61, //
  62, 64, //
  63, //
  65, 66, //
  67, //
  68, //
  69, //
  71, 73, 74, 75, 77, //
  79, //
  81, 87, //
  82, //
  83, //
  84, //
  85, 88, //
  86, 89, //
  91, 93, 94, //
  92, 97, //
  95, //
  96, //
  98, 99, //
};

/// Normaliza um celular brasileiro para E.164 (+55DDNXXXXXXXX).
///
/// Aceita apenas celular: DDD valido + 9 + 8 digitos (11 digitos no total).
/// Nao inventa nem corrige o numero (nao adiciona o 9 que falte, nao
/// transforma fixo em celular). Retorna null quando o telefone nao e um
/// celular brasileiro valido.
String? normalizeBrMobileToE164(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length != 11) return null;

  final ddd = int.parse(digits.substring(0, 2));
  if (!_validBrazilianDdds.contains(ddd)) return null;

  if (digits[2] != '9') return null;

  return '+55$digits';
}
