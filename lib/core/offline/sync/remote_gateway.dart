import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:la_pelve/core/error/network_errors.dart';
import 'package:la_pelve/core/offline/sync/entity_config.dart';

enum RemoteErrorKind {
  /// Sem rede / tempo esgotado: tentar de novo mais tarde, sem perder nada.
  network,

  /// Sessão inválida/expirada: parar e tentar quando houver sessão.
  auth,

  /// Violação de unicidade (id já existe).
  duplicate,

  /// Erro 5xx do servidor: transitório.
  server,

  /// Rejeição definitiva (validação, RLS, FK): não adianta repetir igual.
  permanent,
}

class RemoteException implements Exception {
  const RemoteException(this.kind, {this.code, this.message});

  final RemoteErrorKind kind;
  final String? code;
  final String? message;

  /// Texto curto para o log/diagnóstico: nunca inclui dado clínico.
  String get summary => '${kind.name}${code == null ? '' : ':$code'}';

  @override
  String toString() => 'RemoteException($summary)';
}

/// Porta do motor de sincronização para o Supabase. Só fala em linhas JSON
/// por tabela: o motor não conhece SQL, e os testes usam um servidor fake.
abstract class RemoteGateway {
  Future<List<Map<String, Object?>>> fetchAll(EntityConfig config);

  Future<Map<String, Object?>?> fetchById(EntityConfig config, String id);

  /// Insere e devolve a linha gravada (com defaults do servidor).
  Future<Map<String, Object?>> insert(
    EntityConfig config,
    Map<String, Object?> row,
  );

  /// Atualiza só as colunas de [patch]. Devolve a linha resultante, ou null
  /// quando nenhuma linha casou (apagada, ou [guard] não bateu).
  Future<Map<String, Object?>?> update(
    EntityConfig config,
    String id,
    Map<String, Object?> patch, {
    Map<String, Object?> guard = const {},
  });

  Future<void> delete(EntityConfig config, String id);

  /// Fotos completas da tabela, filtradas ao usuário, via Realtime.
  Stream<List<Map<String, Object?>>> watch(EntityConfig config, String userId);
}

class SupabaseRemoteGateway implements RemoteGateway {
  SupabaseRemoteGateway(this._client);

  final SupabaseClient _client;

  /// Sem teto, uma requisição pendurada seguraria a fila inteira.
  static const _timeout = Duration(seconds: 25);

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body().timeout(_timeout);
    } on PostgrestException catch (e) {
      throw _map(e);
    } on AuthException catch (e) {
      if (e is AuthRetryableFetchException) {
        throw const RemoteException(RemoteErrorKind.network);
      }
      throw RemoteException(RemoteErrorKind.auth, code: e.statusCode);
    } on RemoteException {
      rethrow;
    } on Object catch (e) {
      if (isNetworkError(e)) {
        throw const RemoteException(RemoteErrorKind.network);
      }
      debugPrint('[Offline] remote ${e.runtimeType}');
      throw const RemoteException(RemoteErrorKind.server);
    }
  }

  RemoteException _map(PostgrestException e) {
    final code = e.code ?? '';
    final status = int.tryParse(code);
    if (code == '23505') {
      return RemoteException(RemoteErrorKind.duplicate, code: code);
    }
    if (code == 'PGRST301' || code == '401' || code == 'PGRST303') {
      return RemoteException(RemoteErrorKind.auth, code: code);
    }
    if (status != null && status >= 500 || code.startsWith('08')) {
      return RemoteException(RemoteErrorKind.server, code: code);
    }
    return RemoteException(RemoteErrorKind.permanent, code: code);
  }

  @override
  Future<List<Map<String, Object?>>> fetchAll(EntityConfig config) =>
      _guard(() async {
        var query = _client.from(config.table).select();
        final soft = config.softDeleteColumn;
        if (soft != null) query = query.filter(soft, 'is', null);
        final rows = await query.order(config.orderBy);
        return rows.map((r) => r.cast<String, Object?>()).toList();
      });

  @override
  Future<Map<String, Object?>?> fetchById(EntityConfig config, String id) =>
      _guard(() async {
        final row = await _client
            .from(config.table)
            .select()
            .eq('id', id)
            .maybeSingle();
        return row?.cast<String, Object?>();
      });

  @override
  Future<Map<String, Object?>> insert(
    EntityConfig config,
    Map<String, Object?> row,
  ) => _guard(() async {
    final result = await _client
        .from(config.table)
        .insert(row)
        .select()
        .single();
    return result.cast<String, Object?>();
  });

  @override
  Future<Map<String, Object?>?> update(
    EntityConfig config,
    String id,
    Map<String, Object?> patch, {
    Map<String, Object?> guard = const {},
  }) => _guard(() async {
    var query = _client.from(config.table).update(patch).eq('id', id);
    guard.forEach((column, value) => query = query.eq(column, value!));
    final rows = await query.select();
    return rows.isEmpty ? null : rows.first.cast<String, Object?>();
  });

  @override
  Future<void> delete(EntityConfig config, String id) =>
      _guard(() => _client.from(config.table).delete().eq('id', id));

  @override
  Stream<List<Map<String, Object?>>> watch(
    EntityConfig config,
    String userId,
  ) => _client
      .from(config.table)
      .stream(primaryKey: ['id'])
      .eq('fisioterapeuta_id', userId)
      .map((rows) => rows.map((r) => r.cast<String, Object?>()).toList());
}
