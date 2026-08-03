import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
///
/// Repositories catch exceptions from data sources and convert them into
/// a [Failure], so the domain/presentation layers never depend on
/// infrastructure-specific error types (e.g. PostgrestException).
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
  const CacheFailure([super.message = 'Erro ao ler os dados salvos localmente.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Falha de autenticação.']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Erro inesperado.']);
}
