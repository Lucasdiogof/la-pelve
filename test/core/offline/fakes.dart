import 'package:la_pelve/core/offline/connectivity_monitor.dart';
import 'package:la_pelve/core/offline/local/key_vault.dart';
import 'package:la_pelve/core/offline/local/local_store.dart';
import 'package:la_pelve/core/offline/local/sqlite_local_store.dart';
import 'package:la_pelve/core/offline/offline_session.dart';
import 'package:la_pelve/core/offline/sync/entity_config.dart';
import 'package:la_pelve/core/offline/sync/remote_gateway.dart';
import 'package:la_pelve/core/offline/sync/sync_engine.dart';
import 'package:sqlite3/sqlite3.dart';

/// Servidor em memória: o que o Supabase faria, com falhas injetáveis.
class FakeRemote implements RemoteGateway {
  final Map<String, Map<String, Map<String, Object?>>> tables = {};
  RemoteErrorKind? failWith;

  /// Aplica a escrita no "servidor" mas perde a resposta (rede cai).
  bool dropResponseOnce = false;
  final List<String> calls = [];

  Map<String, Map<String, Object?>> table(String name) =>
      tables.putIfAbsent(name, () => {});

  void seed(String tableName, Map<String, Object?> row) =>
      table(tableName)[row['id']! as String] = {...row};

  void _maybeFail() {
    final f = failWith;
    if (f != null) throw RemoteException(f, code: 'fake');
  }

  void _maybeDrop() {
    if (dropResponseOnce) {
      dropResponseOnce = false;
      throw const RemoteException(RemoteErrorKind.network);
    }
  }

  @override
  Future<List<Map<String, Object?>>> fetchAll(EntityConfig config) async {
    _maybeFail();
    calls.add('fetchAll ${config.table}');
    return [
      for (final r in table(config.table).values)
        if (config.softDeleteColumn == null ||
            r[config.softDeleteColumn!] == null)
          {...r},
    ];
  }

  @override
  Future<Map<String, Object?>?> fetchById(
    EntityConfig config,
    String id,
  ) async {
    _maybeFail();
    final r = table(config.table)[id];
    return r == null ? null : {...r};
  }

  @override
  Future<Map<String, Object?>> insert(
    EntityConfig config,
    Map<String, Object?> row,
  ) async {
    _maybeFail();
    calls.add('insert ${config.table}');
    final id = row['id']! as String;
    if (table(config.table).containsKey(id)) {
      throw const RemoteException(RemoteErrorKind.duplicate, code: '23505');
    }
    final stored = {'created_at': '2026-10-17T10:00:00+00:00', ...row};
    table(config.table)[id] = stored;
    _maybeDrop();
    return {...stored};
  }

  @override
  Future<Map<String, Object?>?> update(
    EntityConfig config,
    String id,
    Map<String, Object?> patch, {
    Map<String, Object?> guard = const {},
  }) async {
    _maybeFail();
    calls.add('update ${config.table}');
    final row = table(config.table)[id];
    if (row == null) return null;
    for (final e in guard.entries) {
      if (row[e.key] != e.value) return null;
    }
    row.addAll(patch);
    _maybeDrop();
    return {...row};
  }

  @override
  Stream<List<Map<String, Object?>>> watch(
    EntityConfig config,
    String userId,
  ) => const Stream.empty();

  @override
  Future<void> delete(EntityConfig config, String id) async {
    _maybeFail();
    calls.add('delete ${config.table}');
    table(config.table).remove(id);
  }
}

const testUser = 'user-a';

SqliteLocalStore memoryStore([String userId = testUser]) =>
    SqliteLocalStore(sqlite3.openInMemory(), userId: userId);

class Harness {
  Harness({String? Function()? current, LocalStore? store})
    : remote = FakeRemote(),
      monitor = FakeConnectivityMonitor(),
      store = store ?? memoryStore() {
    engine = SyncEngine(
      store: this.store,
      remote: remote,
      monitor: monitor,
      currentUserId: current ?? () => testUser,
      periodic: const Duration(days: 1),
      autoSync: false,
    );
    context = OfflineContext(testUser, this.store, engine);
  }

  final FakeRemote remote;
  final FakeConnectivityMonitor monitor;
  final LocalStore store;
  late final SyncEngine engine;
  late final OfflineContext context;
}

class FakeStoreProvider implements StoreProvider {
  final Map<String, LocalStore> opened = {};
  final List<String> wiped = [];
  final List<String> purged = [];

  @override
  Future<LocalStore> open(String userId, KeyVault vault) async =>
      opened[userId] = memoryStore(userId);

  @override
  Future<void> wipe(String userId, KeyVault vault) async =>
      wiped.add(userId);

  @override
  Future<void> purgeOthers(String keepUserId, KeyVault vault) async =>
      purged.add(keepUserId);
}
