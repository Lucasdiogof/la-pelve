import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:la_pelve/core/offline/connectivity_monitor.dart';
import 'package:la_pelve/core/offline/local/local_store.dart';
import 'package:la_pelve/core/offline/sync/conflict_resolver.dart';
import 'package:la_pelve/core/offline/sync/entity_config.dart';
import 'package:la_pelve/core/offline/sync/remote_gateway.dart';
import 'package:la_pelve/core/offline/sync/op_id.dart';
import 'package:la_pelve/shared/utils/id_generator.dart';

/// Estado agregado para o indicador de sincronização.
class SyncStatus {
  const SyncStatus({
    this.counts = const SyncCounts(),
    this.isSyncing = false,
    this.isOnline = true,
    this.lastSyncAt,
    this.lastError,
  });

  final SyncCounts counts;
  final bool isSyncing;

  /// Aparelho com rede E servidor alcançável na última tentativa.
  final bool isOnline;
  final DateTime? lastSyncAt;

  /// Código curto do último erro (sem dado clínico).
  final String? lastError;

  SyncStatus copyWith({
    SyncCounts? counts,
    bool? isSyncing,
    bool? isOnline,
    DateTime? lastSyncAt,
    String? lastError,
    bool clearError = false,
  }) => SyncStatus(
    counts: counts ?? this.counts,
    isSyncing: isSyncing ?? this.isSyncing,
    isOnline: isOnline ?? this.isOnline,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    lastError: clearError ? null : (lastError ?? this.lastError),
  );
}

/// Item de conflito para a tela de resolução.
class ConflictItem {
  const ConflictItem({
    required this.kind,
    required this.id,
    required this.local,
    required this.remote,
    required this.keys,
    required this.opType,
  });

  final String kind;
  final String id;
  final Map<String, Object?> local;

  /// null = o registro foi apagado no servidor.
  final Map<String, Object?>? remote;
  final List<String> keys;
  final OpType opType;
}

enum _Step { next, stop }

/// Motor de sincronização: esvazia a fila de saída em ordem, aplica o
/// servidor ao espelho local (pull) e detecta conflitos. Nunca roda duas
/// vezes ao mesmo tempo; chamadas concorrentes compartilham a execução.
class SyncEngine {
  SyncEngine({
    required this.store,
    required this.remote,
    required this.monitor,
    required this.currentUserId,
    this.entities = offlineEntities,
    DateTime Function()? clock,
    this.periodic = const Duration(seconds: 60),
    this.autoSync = true,
  }) : _clock = clock ?? DateTime.now {
    _status = SyncStatus(
      counts: store.counts(),
      isOnline: monitor.isOnline,
      lastSyncAt: _parse(store.meta('lastSyncAt')),
    );
    _connectivity = monitor.changes.listen((online) {
      _emit(_status.copyWith(isOnline: online));
      if (online) requestSync();
    });
  }

  final LocalStore store;
  final RemoteGateway remote;
  final ConnectivityMonitor monitor;
  final List<EntityConfig> entities;

  /// Usuário autenticado agora. Se diferir do dono do banco, NADA é enviado.
  final String? Function() currentUserId;
  final DateTime Function() _clock;
  final Duration periodic;

  /// Falso nos testes: só sincroniza quando chamado explicitamente.
  final bool autoSync;

  late SyncStatus _status;
  final _statusController = StreamController<SyncStatus>.broadcast();
  final _dataChanged = StreamController<Set<String>>.broadcast();
  StreamSubscription<bool>? _connectivity;
  Timer? _timer;
  Future<SyncStatus>? _inFlight;
  bool _again = false;
  bool _closed = false;

  SyncStatus get status => _status;
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Tipos de registro cujo espelho local mudou (pull ou fim de operação).
  Stream<Set<String>> get dataChanged => _dataChanged.stream;

  EntityConfig _config(String kind) =>
      entities.firstWhere((e) => e.kind == kind);

  bool hasPulled(String kind) => store.meta('pulled:$kind') != null;

  static DateTime? _parse(String? s) => s == null ? null : DateTime.tryParse(s);

  void _emit(SyncStatus next) {
    _status = next;
    if (!_statusController.isClosed) _statusController.add(next);
  }

  /// Chamar depois de qualquer gravação local ou evento que justifique
  /// sincronizar. Não bloqueia.
  void requestSync() {
    if (_closed) return;
    _refreshCounts();
    if (!autoSync) return;
    if (_inFlight != null) {
      _again = true;
      return;
    }
    unawaited(sync());
  }

  /// Liga a sincronização periódica (enquanto o app está ativo).
  void startPeriodic() {
    _timer ??= Timer.periodic(periodic, (_) => requestSync());
  }

  void stopPeriodic() {
    _timer?.cancel();
    _timer = null;
  }

  void _refreshCounts() => _emit(_status.copyWith(counts: store.counts()));

  /// Para a primeira carga das telas: junta-se à sincronização em andamento
  /// (sem agendar outra) ou inicia uma.
  Future<SyncStatus> joinOrSync() => _inFlight ?? sync();

  /// Tenta levar ao servidor TUDO que está pendente para a entidade e diz se
  /// conseguiu (sem pendência restante). Usado só para decidir o que dizer à
  /// profissional ("salvo no servidor" x "salvo neste dispositivo"): nunca
  /// bloqueia além de [timeout] e não insiste após uma falha.
  Future<bool> flush(
    String kind,
    String id, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    bool clean() => store.opsForEntity(kind, id).isEmpty;
    if (clean()) return true;
    final deadline = _clock().add(timeout);
    try {
      while (!clean() && _clock().isBefore(deadline) && monitor.isOnline) {
        await sync().timeout(deadline.difference(_clock()));
        final ops = store.opsForEntity(kind, id);
        // Falha (rede, erro definitivo, conflito): não insistir em loop.
        if (ops.any((o) => o.lastError != null || o.status != OpStatus.pending)) {
          break;
        }
      }
    } on TimeoutException {
      // Segue como "só neste dispositivo"; o envio continua em segundo plano.
    }
    return clean();
  }

  /// Sincroniza agora. [force] ignora o backoff (botão "tentar agora").
  Future<SyncStatus> sync({bool force = false}) {
    if (_closed) return Future.value(_status);
    final running = _inFlight;
    if (running != null) {
      _again = true;
      return running;
    }
    late final Future<SyncStatus> run;
    run = _run(force).whenComplete(() {
      if (identical(_inFlight, run)) _inFlight = null;
      if (_again && !_closed) {
        _again = false;
        unawaited(sync());
      }
    });
    _inFlight = run;
    return run;
  }

  Future<SyncStatus> _run(bool force) async {
    if (!monitor.isOnline) {
      _emit(_status.copyWith(isOnline: false, counts: store.counts()));
      return _status;
    }
    if (currentUserId() != store.userId) {
      // Escopo errado (sessão trocada): jamais enviar ou aplicar nada.
      _emit(_status.copyWith(lastError: 'scope', counts: store.counts()));
      return _status;
    }
    _emit(_status.copyWith(isSyncing: true, clearError: true));
    final changed = <String>{};
    var reachable = true;
    String? error;
    try {
      _recoverInterrupted();
      _stopped = null;
      await _push(force, changed);
      final stop = _stopped;
      if (stop != null) {
        // Falha de rede/servidor/sessão: o restante espera a próxima rodada.
        reachable = stop.kind == RemoteErrorKind.auth;
        error = stop.summary;
      } else {
        // Uma operação com falha definitiva não impede de baixar o servidor.
        await _pull(changed);
        store.setMeta('lastSyncAt', _clock().toIso8601String());
      }
    } on RemoteException catch (e) {
      reachable = e.kind != RemoteErrorKind.network;
      error = e.summary;
    } on Object catch (e) {
      error = e.runtimeType.toString();
      debugPrint('[Sync] erro inesperado: $error');
    }
    if (changed.isNotEmpty && !_dataChanged.isClosed) {
      _dataChanged.add(changed);
    }
    _emit(
      SyncStatus(
        counts: store.counts(),
        isSyncing: false,
        isOnline: reachable && monitor.isOnline,
        lastSyncAt: _parse(store.meta('lastSyncAt')),
        lastError: error,
      ),
    );
    return _status;
  }

  void _recoverInterrupted() {
    for (final op in store.liveOps()) {
      if (op.status == OpStatus.syncing) {
        store.updateOp(op.copyWith(status: OpStatus.pending));
      }
    }
  }

  Duration backoffFor(int attempts) {
    final exp = (attempts - 1).clamp(0, 8);
    return Duration(seconds: (5 * (1 << exp)).clamp(5, 900));
  }

  RemoteException? _stopped;

  /// Esvazia a fila em ordem. Para na primeira falha transitória
  /// (registrada em [_stopped]); falhas definitivas só marcam a operação.
  Future<void> _push(bool force, Set<String> changed) async {
    final attempted = <String>{};
    while (true) {
      final ops = store.liveOps();
      final now = _clock();
      SyncOp? next;
      for (final op in ops) {
        if (attempted.contains(op.opId)) continue;
        if (op.status != OpStatus.pending) continue;
        if (!force &&
            op.nextAttemptAt != null &&
            op.nextAttemptAt!.isAfter(now)) {
          continue;
        }
        if (_blocked(op, ops)) continue;
        next = op;
        break;
      }
      if (next == null) return;
      attempted.add(next.opId);
      final step = await _execute(next, changed);
      if (step == _Step.stop) return;
    }
  }

  /// Uma operação espera enquanto houver outra mais antiga da mesma entidade
  /// ou qualquer operação viva da entidade pai (ex.: paciente criado offline).
  bool _blocked(SyncOp op, List<SyncOp> ops) {
    for (final other in ops) {
      if (other.opId == op.opId) continue;
      if (other.entityKey == op.entityKey && other.seq < op.seq) return true;
      if (op.dependsOn != null && other.entityKey == op.dependsOn) return true;
    }
    return false;
  }

  Future<_Step> _execute(SyncOp op, Set<String> changed) async {
    if (op.userId != store.userId || currentUserId() != op.userId) {
      store.updateOp(
        op.copyWith(status: OpStatus.failed, lastError: 'scope'),
      );
      return _Step.next;
    }
    final config = _config(op.kind);
    store.updateOp(
      op.copyWith(status: OpStatus.syncing, attempts: op.attempts + 1),
    );
    final running = op.copyWith(attempts: op.attempts + 1);
    try {
      switch (op.type) {
        case OpType.create:
          await _create(config, running, changed);
        case OpType.update:
          await _update(config, running, changed, isDelete: false);
        case OpType.delete:
          await _update(config, running, changed, isDelete: true);
      }
      return _Step.next;
    } on RemoteException catch (e) {
      switch (e.kind) {
        case RemoteErrorKind.network:
        case RemoteErrorKind.server:
        case RemoteErrorKind.auth:
          _stopped = e;
          store.updateOp(
            running.copyWith(
              status: OpStatus.pending,
              lastError: e.summary,
              nextAttemptAt: _clock().add(backoffFor(running.attempts)),
            ),
          );
          return _Step.stop;
        case RemoteErrorKind.duplicate:
        case RemoteErrorKind.permanent:
          store.updateOp(
            running.copyWith(status: OpStatus.failed, lastError: e.summary),
          );
          return _Step.next;
      }
    }
  }

  // --- create -------------------------------------------------------------

  Future<void> _create(
    EntityConfig config,
    SyncOp op,
    Set<String> changed,
  ) async {
    Map<String, Object?> row;
    try {
      row = await remote.insert(config, op.payload);
    } on RemoteException catch (e) {
      if (e.kind != RemoteErrorKind.duplicate) rethrow;
      // Reenvio depois de resposta perdida: a linha já existe. Só é a "mesma"
      // se tiver o conteúdo desta operação; senão é colisão de id.
      final existing = await remote.fetchById(config, op.entityId);
      if (existing == null || !alreadyApplied(existing, op.payload)) {
        throw const RemoteException(
          RemoteErrorKind.permanent,
          code: 'id_collision',
        );
      }
      row = existing;
    }
    _complete(op, row, changed);
  }

  // --- update / delete ----------------------------------------------------

  Future<void> _update(
    EntityConfig config,
    SyncOp op,
    Set<String> changed, {
    required bool isDelete,
  }) async {
    final record = store.getRecord(op.kind, op.entityId);
    if (record == null) {
      store.removeOp(op.opId);
      return;
    }
    for (var attempt = 0; attempt < 3; attempt++) {
      final current = await remote.fetchById(config, op.entityId);
      if (current == null) {
        if (isDelete) {
          // Já não existe no servidor: o objetivo da exclusão foi atingido.
          _completeDelete(op, changed);
          return;
        }
        _markConflict(op, record, null, const [], changed);
        return;
      }
      final soft = config.softDeleteColumn;
      if (isDelete && soft != null && current[soft] != null) {
        _completeDelete(op, changed);
        return;
      }
      final payload = isDelete && soft != null
          ? <String, Object?>{soft: _clock().toUtc().toIso8601String()}
          : op.payload;
      // Exclusão de dado comum não pede conflito; de dado clínico estrito sim.
      final check = (isDelete && !config.strict)
          ? const ConflictCheck.none()
          : detectConflict(
              config: config,
              base: record.base,
              remote: current,
              payload: isDelete ? const {} : payload,
            );
      if (check.hasConflict) {
        _markConflict(op, record, current, check.keys, changed);
        return;
      }
      if (isDelete) {
        if (soft == null) {
          await remote.delete(config, op.entityId);
          _completeDelete(op, changed);
        } else {
          await remote.update(config, op.entityId, payload);
          _completeDelete(op, changed);
        }
        return;
      }
      if (alreadyApplied(current, payload)) {
        _complete(op, current, changed);
        return;
      }
      // Trava otimista quando o servidor expõe updated_at confiável
      // (ver migração de versionamento): fecha a janela entre ler e gravar.
      final guard = current['updated_at'] != null && !config.strict
          ? {'updated_at': current['updated_at']}
          : const <String, Object?>{};
      final row = await remote.update(
        config,
        op.entityId,
        payload,
        guard: guard,
      );
      if (row != null) {
        _complete(op, row, changed);
        return;
      }
      // Linha mudou entre a leitura e a gravação: reavalia do zero.
    }
    throw const RemoteException(RemoteErrorKind.server, code: 'race');
  }

  // --- finalização --------------------------------------------------------

  /// Operação aplicada no servidor: o registro local passa a refletir a
  /// resposta do servidor, reaplicando operações ainda pendentes da entidade.
  void _complete(SyncOp op, Map<String, Object?> serverRow, Set<String> changed) {
    store.transaction(() {
      store.removeOp(op.opId);
      final rest = store
          .opsForEntity(op.kind, op.entityId)
          .where((o) => o.opId != op.opId)
          .toList();
      var data = Map<String, Object?>.from(serverRow);
      var state = RecordState.synced;
      for (final o in rest) {
        if (o.type == OpType.delete) {
          state = RecordState.pendingDelete;
        } else {
          data = {...data, ...o.payload};
          state = o.type == OpType.create
              ? RecordState.pendingCreate
              : RecordState.pendingUpdate;
        }
      }
      store.putRecord(
        LocalRecord(
          kind: op.kind,
          id: op.entityId,
          data: data,
          base: serverRow,
          state: state,
        ),
      );
    });
    changed.add(op.kind);
  }

  void _completeDelete(SyncOp op, Set<String> changed) {
    store.transaction(() {
      store.removeOp(op.opId);
      store.deleteRecord(op.kind, op.entityId);
      // Operações subsequentes da entidade apagada perdem o sentido.
      for (final o in store.opsForEntity(op.kind, op.entityId)) {
        store.removeOp(o.opId);
      }
    });
    changed.add(op.kind);
  }

  void _markConflict(
    SyncOp op,
    LocalRecord record,
    Map<String, Object?>? current,
    List<String> keys,
    Set<String> changed,
  ) {
    store.transaction(() {
      store.updateOp(op.copyWith(status: OpStatus.conflict, lastError: 'conflict'));
      store.putRecord(
        record.copyWith(
          state: RecordState.conflict,
          remote: current,
          clearRemote: current == null,
          conflictKeys: keys,
        ),
      );
    });
    changed.add(op.kind);
  }

  // --- pull ---------------------------------------------------------------

  Future<void> _pull(Set<String> changed) async {
    for (final config in entities) {
      final rows = await remote.fetchAll(config);
      final didChange = store.transaction(() => applySnapshot(config, rows));
      if (didChange) changed.add(config.kind);
      store.setMeta('pulled:${config.kind}', _clock().toIso8601String());
    }
  }

  /// Aplica uma foto COMPLETA da tabela (do pull ou do Realtime) ao espelho.
  /// Registros com alteração local pendente ou em conflito nunca são
  /// sobrescritos; os demais passam a ser exatamente o que o servidor tem.
  bool applySnapshot(EntityConfig config, List<Map<String, Object?>> rows) {
    var changed = false;
    final existing = {
      for (final r in store.allRecords(config.kind)) r.id: r,
    };
    final seen = <String>{};
    for (final row in rows) {
      final id = row['id'] as String?;
      if (id == null) continue;
      seen.add(id);
      final local = existing[id];
      if (local == null) {
        store.putRecord(
          LocalRecord(
            kind: config.kind,
            id: id,
            data: row,
            base: row,
            state: RecordState.synced,
          ),
        );
        changed = true;
      } else if (local.state == RecordState.synced) {
        if (!jsonEquals(local.data, row)) {
          store.putRecord(local.copyWith(data: row, base: row));
          changed = true;
        }
      }
    }
    for (final local in existing.values) {
      if (local.state == RecordState.synced && !seen.contains(local.id)) {
        store.deleteRecord(config.kind, local.id);
        changed = true;
      }
    }
    return changed;
  }

  /// Entrada para snapshots vindos de fora do pull (Realtime da agenda).
  void applyExternalSnapshot(String kind, List<Map<String, Object?>> rows) {
    final config = _config(kind);
    final didChange = store.transaction(() => applySnapshot(config, rows));
    store.setMeta('pulled:$kind', _clock().toIso8601String());
    if (didChange && !_dataChanged.isClosed) _dataChanged.add({kind});
  }

  // --- conflitos e falhas --------------------------------------------------

  List<ConflictItem> conflicts() {
    final items = <ConflictItem>[];
    for (final config in entities) {
      for (final record in store.allRecords(config.kind)) {
        if (record.state != RecordState.conflict) continue;
        final ops = store
            .opsForEntity(config.kind, record.id)
            .where((o) => o.status == OpStatus.conflict);
        items.add(
          ConflictItem(
            kind: config.kind,
            id: record.id,
            local: record.data,
            remote: record.remote,
            keys: record.conflictKeys,
            opType: ops.isEmpty ? OpType.update : ops.first.type,
          ),
        );
      }
    }
    return items;
  }

  List<SyncOp> failedOps() =>
      store.liveOps().where((o) => o.status == OpStatus.failed).toList();

  /// Resolução explícita pela profissional. Nada é sobrescrito sem ela.
  Future<void> resolveConflict(
    String kind,
    String id,
    ConflictResolution resolution,
  ) async {
    final record = store.getRecord(kind, id);
    if (record == null || record.state != RecordState.conflict) return;
    final remoteRow = record.remote;
    store.transaction(() {
      final ops = store.opsForEntity(kind, id);
      SyncOp? conflicted;
      for (final o in ops) {
        if (o.status == OpStatus.conflict) conflicted = o;
      }
      switch (resolution) {
        case ConflictResolution.keepRemote:
          _discardOps(ops);
          _applyRemote(kind, id, remoteRow);
        case ConflictResolution.keepBoth:
          if (remoteRow != null && kind == evolutionsConfig.kind) {
            final copyId = generateId();
            final copy = {...record.data, 'id': copyId};
            store.putRecord(
              LocalRecord(
                kind: kind,
                id: copyId,
                data: copy,
                state: RecordState.pendingCreate,
              ),
            );
            store.enqueue(
              opId: newOpId(),
              kind: kind,
              entityId: copyId,
              type: OpType.create,
              payload: Map<String, Object?>.from(copy)
                ..remove('created_at')
                ..remove('physiotherapist_id'),
              dependsOn: _dependsOn(_config(kind), copy),
            );
          }
          _discardOps(ops);
          _applyRemote(kind, id, remoteRow);
        case ConflictResolution.keepLocal:
          if (conflicted == null) return;
          if (remoteRow == null) {
            // Apagado no servidor e a profissional quer manter: recria.
            final data = Map<String, Object?>.from(record.data)
              ..remove('created_at')
              ..remove('deleted_at');
            for (final o in ops) {
              store.removeOp(o.opId);
            }
            store.putRecord(
              LocalRecord(
                kind: kind,
                id: id,
                data: data,
                state: RecordState.pendingCreate,
              ),
            );
            store.enqueue(
              opId: newOpId(),
              kind: kind,
              entityId: id,
              type: OpType.create,
              payload: data,
              dependsOn: _dependsOn(_config(kind), data),
            );
          } else {
            store.updateOp(
              conflicted.copyWith(
                status: OpStatus.pending,
                attempts: 0,
                clearError: true,
                clearNextAttempt: true,
              ),
            );
            store.putRecord(
              record.copyWith(
                base: remoteRow,
                clearRemote: true,
                conflictKeys: const [],
                state: conflicted.type == OpType.delete
                    ? RecordState.pendingDelete
                    : RecordState.pendingUpdate,
              ),
            );
          }
      }
    });
    _dataChanged.add({kind});
    requestSync();
  }

  void _discardOps(List<SyncOp> ops) {
    for (final o in ops) {
      store.removeOp(o.opId);
    }
  }

  void _applyRemote(String kind, String id, Map<String, Object?>? remoteRow) {
    if (remoteRow == null) {
      store.deleteRecord(kind, id);
    } else {
      store.putRecord(
        LocalRecord(
          kind: kind,
          id: id,
          data: remoteRow,
          base: remoteRow,
          state: RecordState.synced,
        ),
      );
    }
  }

  /// Reenvia uma operação que falhou de forma definitiva.
  void retryOp(String opId) {
    for (final op in store.liveOps()) {
      if (op.opId == opId && op.status == OpStatus.failed) {
        store.updateOp(
          op.copyWith(
            status: OpStatus.pending,
            attempts: 0,
            clearError: true,
            clearNextAttempt: true,
          ),
        );
      }
    }
    requestSync();
  }

  /// Descarta uma operação que falhou, revertendo o registro local ao último
  /// estado do servidor (ou removendo-o, se nunca chegou ao servidor).
  void discardOp(String opId) {
    store.transaction(() {
      for (final op in store.liveOps()) {
        if (op.opId != opId) continue;
        final related = store.opsForEntity(op.kind, op.entityId);
        _discardOps(related);
        final record = store.getRecord(op.kind, op.entityId);
        if (record == null) continue;
        if (record.base == null) {
          store.deleteRecord(op.kind, op.entityId);
        } else {
          _applyRemote(op.kind, op.entityId, record.base);
        }
        // Filhos pendentes que dependiam desta entidade ficam sem pai.
        if (record.base == null) {
          for (final child in store.liveOps()) {
            if (child.dependsOn == op.entityKey) {
              store.removeOp(child.opId);
              store.deleteRecord(child.kind, child.entityId);
            }
          }
        }
        _dataChanged.add({op.kind});
      }
    });
    _refreshCounts();
  }

  /// Dependência de ordenação: o pai precisa ter sido criado antes.
  String? _dependsOn(EntityConfig config, Map<String, Object?> data) {
    final parentKind = config.parentKind;
    final column = config.parentColumn;
    if (parentKind == null || column == null) return null;
    final parentId = data[column] as String?;
    return parentId == null ? null : '$parentKind:$parentId';
  }

  String? dependsOnFor(String kind, Map<String, Object?> data) =>
      _dependsOn(_config(kind), data);

  Future<void> close() async {
    _closed = true;
    stopPeriodic();
    await _connectivity?.cancel();
    await _inFlight?.catchError((Object _) => _status);
    await _statusController.close();
    await _dataChanged.close();
  }
}
