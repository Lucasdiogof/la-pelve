import 'package:flutter/foundation.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/offline/local/local_store.dart';
import 'package:la_pelve/core/offline/local_writer.dart';
import 'package:la_pelve/core/offline/offline_session.dart';

/// Leitura offline-first: lê SEMPRE o espelho local. Só a primeiríssima carga
/// (nunca sincronizado neste aparelho) precisa do servidor; sem rede nesse
/// caso o erro é [NetworkFailure], nunca um loading infinito. Depois disso a
/// leitura é local e instantânea, e a atualização vem pelo motor de
/// sincronização (que avisa as telas quando algo mudou).
///
/// Sem contexto offline (Web, falha de Keystore) cai em [fallback]: o
/// comportamento online de antes.
Future<Result<T>> offlineRead<T>({
  required OfflineSession session,
  required String kind,
  required Future<Result<T>> Function() fallback,
  required T Function(LocalStore store) read,
}) async {
  final ctx = await session.context();
  if (ctx == null) return fallback();
  try {
    if (!ctx.engine.hasPulled(kind)) {
      final status = await ctx.engine.joinOrSync();
      if (!ctx.engine.hasPulled(kind)) {
        return Error(status.isOnline ? ServerFailure() : NetworkFailure());
      }
    }
    return Success(read(ctx.store));
  } on Object catch (e) {
    debugPrint('[Offline] leitura de $kind falhou (${e.runtimeType})');
    return Error(CacheFailure());
  }
}

/// Gravação offline-first: persiste localmente (alteração + pendência, de
/// forma atômica) e só então devolve sucesso, que aqui significa "salvo
/// NESTE aparelho". O envio ao servidor é assíncrono.
Future<Result<void>> offlineWrite({
  required OfflineSession session,
  required Future<Result<void>> Function() fallback,
  required void Function(LocalWriter writer) body,
}) async {
  final ctx = await session.context();
  if (ctx == null) return fallback();
  try {
    body(LocalWriter(ctx));
    return const Success(null);
  } on LocalWriteException catch (e) {
    return Error(
      e.error == LocalWriteError.conflictPending
          ? SyncConflictFailure()
          : CacheFailure(),
    );
  } on Object catch (e) {
    debugPrint('[Offline] gravação local falhou (${e.runtimeType})');
    return Error(CacheFailure());
  }
}

Map<String, dynamic> asJson(Map<String, Object?> data) =>
    Map<String, dynamic>.from(data);
