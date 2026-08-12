class ServerException implements Exception {
  const ServerException([this.message = 'Erro no servidor.']);

  final String message;
}

class CacheException implements Exception {
  const CacheException([
    this.message = 'Erro ao ler os dados salvos localmente.',
  ]);

  final String message;
}

class AuthException implements Exception {
  const AuthException([this.message = 'Falha de autenticação.']);

  final String message;
}
