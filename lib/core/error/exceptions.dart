import 'package:get_it/get_it.dart';
import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';

AppLanguage _currentLanguage() {
  if (!GetIt.instance.isRegistered<LocaleCubit>()) {
    return AppLanguage.portuguese;
  }
  return GetIt.instance<LocaleCubit>().state;
}

class ServerException implements Exception {
  ServerException([String? message]) : message = message ?? _defaultMessage();

  final String message;

  static String _defaultMessage() => switch (_currentLanguage()) {
    AppLanguage.portuguese => 'Erro no servidor.',
    AppLanguage.english => 'Server error.',
  };
}

class CacheException implements Exception {
  CacheException([String? message]) : message = message ?? _defaultMessage();

  final String message;

  static String _defaultMessage() => switch (_currentLanguage()) {
    AppLanguage.portuguese => 'Erro ao ler os dados salvos localmente.',
    AppLanguage.english => 'Error reading locally saved data.',
  };
}

class AuthException implements Exception {
  AuthException([String? message]) : message = message ?? _defaultMessage();

  final String message;

  static String _defaultMessage() => switch (_currentLanguage()) {
    AppLanguage.portuguese => 'Falha de autenticação.',
    AppLanguage.english => 'Authentication failed.',
  };
}
