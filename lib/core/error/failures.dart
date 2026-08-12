import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erro no servidor. Tente novamente.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Erro ao ler os dados salvos localmente.',
  ]);
}

class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Falha de autenticação.',
    this.isInvalidCredentials = false,
  ]);

  final bool isInvalidCredentials;

  @override
  List<Object?> get props => [message, isInvalidCredentials];
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Erro inesperado.']);
}
