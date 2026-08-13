import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';
import 'package:fisioterapia_pelvica/shared/l10n/shared_strings.dart';

final _emailRegExp = RegExp(
  r'^[\w.!#$%&’*+/=?^`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
);

bool isValidEmail(String value) {
  final email = value.trim();
  if (email.isEmpty) return false;
  return _emailRegExp.hasMatch(email);
}

const int kMinPasswordLength = 8;

bool isValidPassword(String value) => value.length >= kMinPasswordLength;

const int kMinAge = 1;
const int kMaxAge = 120;

String? ageErrorText(
  String value, {
  AppLanguage language = AppLanguage.portuguese,
}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final age = int.tryParse(trimmed);
  if (age == null || age < kMinAge || age > kMaxAge) {
    return SharedStrings(language).invalidAge;
  }
  return null;
}

bool isValidPhone(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.length == 10 || digits.length == 11;
}

String? phoneErrorText(
  String value, {
  AppLanguage language = AppLanguage.portuguese,
}) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty || isValidPhone(value)) return null;
  return SharedStrings(language).invalidPhone;
}

final _crefitoRegExp = RegExp(r'^\d{3,7}[-/\s]?[FfTt]\d{1,2}$');

bool isValidCrefito(String value) => _crefitoRegExp.hasMatch(value.trim());

String? crefitoErrorText(
  String value, {
  AppLanguage language = AppLanguage.portuguese,
}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || isValidCrefito(trimmed)) return null;
  return SharedStrings(language).invalidCrefito;
}
