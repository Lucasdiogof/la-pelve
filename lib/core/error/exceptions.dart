/// Exceptions thrown by data sources (Supabase, local cache, etc).
///
/// Repositories catch these and map them to a [Failure] before returning
/// a [Result] to the domain layer.
class ServerException implements Exception {
  const ServerException([this.message = 'Erro no servidor.']);

  final String message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Erro ao ler os dados salvos localmente.']);

  final String message;
}

class AuthException implements Exception {
  const AuthException([this.message = 'Falha de autenticação.']);

  final String message;
}
