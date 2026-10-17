import 'package:la_pelve/core/offline/local/local_store.dart';
import 'package:la_pelve/core/offline/offline_session.dart';
import 'package:la_pelve/core/offline/sync/conflict_resolver.dart';
import 'package:la_pelve/core/offline/sync/entity_config.dart';
import 'package:la_pelve/core/offline/sync/op_id.dart';

enum LocalWriteError {
  /// O registro tem um conflito em aberto: resolver antes de editar de novo.
  conflictPending,
  notFound,
}

class LocalWriteException implements Exception {
  const LocalWriteException(this.error);

  final LocalWriteError error;

  @override
  String toString() => 'LocalWriteException(${error.name})';
}

/// Grava no espelho local e enfileira a operação, juntas e de forma atômica:
/// ou a alteração E a pendência são persistidas, ou nenhuma. Só depois disso
/// quem chamou pode dizer "salvo neste aparelho".
///
/// Várias edições seguidas do mesmo registro viram uma operação só (coalescem),
/// preservando a ordem entre registros diferentes (pai antes de filho).
class LocalWriter {
  LocalWriter(this.context, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final OfflineContext context;
  final DateTime Function() _clock;

  LocalStore get _store => context.store;

  EntityConfig _config(String kind) =>
      context.engine.entities.firstWhere((e) => e.kind == kind);

  void create(String kind, Map<String, Object?> row) {
    final id = row['id']! as String;
    _store.transaction(() {
      _store.putRecord(
        LocalRecord(
          kind: kind,
          id: id,
          data: {
            // Só para ordenar na tela até o servidor carimbar o real.
            'created_at': _clock().toUtc().toIso8601String(),
            ...row,
          },
          state: RecordState.pendingCreate,
        ),
      );
      _store.enqueue(
        opId: newOpId(),
        kind: kind,
        entityId: id,
        type: OpType.create,
        payload: row,
        dependsOn: context.engine.dependsOnFor(kind, row),
      );
    });
    context.engine.requestSync();
  }

  /// Aplica [fullRow] (colunas completas da entidade) como edição: só as
  /// colunas que realmente mudaram viram parte da operação.
  ///
  /// [current] é a visão atual normalizada pela própria entidade
  /// (`fromJson(...).toJson()`), para que diferenças só de representação
  /// (coluna JSONB esparsa x completa) não virem "edição" e, com isso, falso
  /// conflito com outro aparelho.
  void update(
    String kind,
    String id,
    Map<String, Object?> fullRow, {
    Map<String, Object?>? current,
  }) {
    final record = _store.getRecord(kind, id);
    if (record == null) {
      throw const LocalWriteException(LocalWriteError.notFound);
    }
    final patch = <String, Object?>{
      for (final e in fullRow.entries)
        if (e.key != 'id' &&
            !jsonEquals((current ?? record.data)[e.key], e.value))
          e.key: e.value,
    };
    updatePatch(kind, id, patch);
  }

  void updatePatch(String kind, String id, Map<String, Object?> patch) {
    final record = _store.getRecord(kind, id);
    if (record == null) {
      throw const LocalWriteException(LocalWriteError.notFound);
    }
    if (record.state == RecordState.conflict) {
      throw const LocalWriteException(LocalWriteError.conflictPending);
    }
    if (patch.isEmpty) return;
    _store.transaction(() {
      final ops = _store.opsForEntity(kind, id);
      final last = ops.isEmpty ? null : ops.last;
      final editable =
          last != null &&
          (last.status == OpStatus.pending || last.status == OpStatus.failed);
      if (editable && last.type == OpType.create) {
        _store.updateOp(
          last.copyWith(
            payload: {...last.payload, ...patch},
            status: OpStatus.pending,
            clearError: true,
            clearNextAttempt: true,
          ),
        );
      } else if (editable && last.type == OpType.update) {
        _store.updateOp(
          last.copyWith(
            payload: {...last.payload, ...patch},
            status: OpStatus.pending,
            clearError: true,
            clearNextAttempt: true,
          ),
        );
      } else {
        _store.enqueue(
          opId: newOpId(),
          kind: kind,
          entityId: id,
          type: OpType.update,
          payload: patch,
          dependsOn: context.engine.dependsOnFor(kind, {
            ...record.data,
            ...patch,
          }),
        );
      }
      _store.putRecord(
        record.copyWith(
          data: {...record.data, ...patch},
          state: record.state == RecordState.pendingCreate
              ? RecordState.pendingCreate
              : RecordState.pendingUpdate,
        ),
      );
    });
    context.engine.requestSync();
  }

  void delete(String kind, String id) {
    final record = _store.getRecord(kind, id);
    if (record == null) return;
    final config = _config(kind);
    _store.transaction(() {
      final ops = _store.opsForEntity(kind, id);
      final neverSynced =
          record.state == RecordState.pendingCreate &&
          ops.every((o) => o.status != OpStatus.syncing);
      // Folhas (consulta, evolução) criadas offline e apagadas offline nunca
      // precisam chegar ao servidor. Pais continuam (create + delete) porque
      // outros registros podem referenciá-los.
      if (neverSynced && config.parentKind != null) {
        for (final o in ops) {
          _store.removeOp(o.opId);
        }
        _store.deleteRecord(kind, id);
        return;
      }
      _store.enqueue(
        opId: newOpId(),
        kind: kind,
        entityId: id,
        type: OpType.delete,
        payload: const {},
      );
      _store.putRecord(record.copyWith(state: RecordState.pendingDelete));
    });
    context.engine.requestSync();
  }
}
