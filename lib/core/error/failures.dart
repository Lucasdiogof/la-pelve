import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:la_pelve/core/l10n/app_language.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';

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
    AppLanguage.spanish => 'Error en el servidor. Inténtalo de nuevo.',
  };
}

/// A conta tem pacientes, prontuários ou outros registros cuja guarda precisa
/// ser assegurada: o app não exclui; o encerramento é assistido.
class AccountHasDataFailure extends Failure {
  AccountHasDataFailure([String? message])
    : super(message ?? _defaultMessage());

  static String _defaultMessage() => switch (_currentLanguage()) {
    AppLanguage.portuguese =>
      'Sua conta ainda tem pacientes, prontuários ou outros registros que '
          'precisam ser preservados, por isso ela não pode ser excluída pelo '
          'aplicativo. Exporte seus dados em Perfil > Exportar meus dados e '
          'fale com o suporte do La Pelve para o encerramento assistido. '
          'Nada foi apagado.',
    AppLanguage.english =>
      'Your account still has patients, medical records or other data that '
          'must be preserved, so it cannot be deleted from the app. Export '
          'your data in Profile > Export my data and contact La Pelve support '
          'for assisted closure. Nothing was deleted.',
    AppLanguage.spanish =>
      'Tu cuenta aún tiene pacientes, historias clínicas u otros registros '
          'que deben conservarse, por lo que no se puede eliminar desde la '
          'app. Exporta tus datos en Perfil > Exportar mis datos y contacta '
          'al soporte de La Pelve para el cierre asistido. No se borró nada.',
  };
}

class NetworkFailure extends Failure {
  NetworkFailure([String? message]) : super(message ?? _defaultMessage());

  static String _defaultMessage() => switch (_currentLanguage()) {
    AppLanguage.portuguese => 'Sem conexão com a internet.',
    AppLanguage.english => 'No internet connection.',
    AppLanguage.spanish => 'Sin conexión a internet.',
  };
}

class CacheFailure extends Failure {
  CacheFailure([String? message]) : super(message ?? _defaultMessage());

  static String _defaultMessage() => switch (_currentLanguage()) {
    AppLanguage.portuguese => 'Erro ao ler os dados salvos localmente.',
    AppLanguage.english => 'Error reading locally saved data.',
    AppLanguage.spanish => 'Error al leer los datos guardados localmente.',
  };
}

class AuthFailure extends Failure {
  AuthFailure([String? message, this.isInvalidCredentials = false])
    : super(message ?? _defaultMessage());

  final bool isInvalidCredentials;

  static String _defaultMessage() => switch (_currentLanguage()) {
    AppLanguage.portuguese => 'Falha de autenticação.',
    AppLanguage.english => 'Authentication failed.',
    AppLanguage.spanish => 'Fallo de autenticación.',
  };

  @override
  List<Object?> get props => [message, isInvalidCredentials];
}

class UnexpectedFailure extends Failure {
  UnexpectedFailure([String? message]) : super(message ?? _defaultMessage());

  static String _defaultMessage() => switch (_currentLanguage()) {
    AppLanguage.portuguese => 'Erro inesperado.',
    AppLanguage.english => 'Unexpected error.',
    AppLanguage.spanish => 'Error inesperado.',
  };
}

/// O registro tem um conflito de sincronização em aberto: a profissional
/// precisa escolher qual versão manter antes de editar de novo.
class SyncConflictFailure extends Failure {
  SyncConflictFailure([String? message]) : super(message ?? _defaultMessage());

  static String _defaultMessage() => switch (_currentLanguage()) {
    AppLanguage.portuguese =>
      'Este registro tem um conflito de sincronização. Resolva-o antes de editar.',
    AppLanguage.english =>
      'This record has a sync conflict. Resolve it before editing.',
    AppLanguage.spanish =>
      'Este registro tiene un conflicto de sincronización. Resuélvelo antes de editar.',
  };
}
