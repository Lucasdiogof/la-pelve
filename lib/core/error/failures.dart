import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';

AppLanguage _currentLanguage() {
  if (!GetIt.instance.isRegistered<LocaleCubit>()) {
    return AppLanguage.portuguese;
  }
  return GetIt.instance<LocaleCubit>().state;
}

abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  ServerFailure([String? message]) : super(message ?? _defaultMessage());

  static String _defaultMessage() => switch (_currentLanguage()) {
    AppLanguage.portuguese => 'Erro no servidor. Tente novamente.',
    AppLanguage.english => 'Server error. Please try again.',
  };
}

class NetworkFailure extends Failure {
  NetworkFailure([String? message]) : super(message ?? _defaultMessage());

  static String _defaultMessage() => switch (_currentLanguage()) {
    AppLanguage.portuguese => 'Sem conexão com a internet.',
    AppLanguage.english => 'No internet connection.',
  };
}

class CacheFailure extends Failure {
  CacheFailure([String? message]) : super(message ?? _defaultMessage());

  static String _defaultMessage() => switch (_currentLanguage()) {
    AppLanguage.portuguese => 'Erro ao ler os dados salvos localmente.',
    AppLanguage.english => 'Error reading locally saved data.',
  };
}

class AuthFailure extends Failure {
  AuthFailure([String? message, this.isInvalidCredentials = false])
    : super(message ?? _defaultMessage());

  final bool isInvalidCredentials;

  static String _defaultMessage() => switch (_currentLanguage()) {
    AppLanguage.portuguese => 'Falha de autenticação.',
    AppLanguage.english => 'Authentication failed.',
  };

  @override
  List<Object?> get props => [message, isInvalidCredentials];
}

class UnexpectedFailure extends Failure {
  UnexpectedFailure([String? message]) : super(message ?? _defaultMessage());

  static String _defaultMessage() => switch (_currentLanguage()) {
    AppLanguage.portuguese => 'Erro inesperado.',
    AppLanguage.english => 'Unexpected error.',
  };
}
