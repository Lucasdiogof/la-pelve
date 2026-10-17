import 'dart:convert';

import 'package:sqlite3/common.dart';
import 'package:la_pelve/core/offline/local/local_store.dart';

/// [LocalStore] sobre SQLite (SQLite3 Multiple Ciphers no aparelho: o arquivo
/// é cifrado em repouso; a chave fica no Keychain/Keystore, ver KeyVault).
///
/// Esquema documental (JSON por registro): as entidades já têm toJson/fromJson
/// espelhando as colunas do Supabase, então o espelho local guarda a mesma
/// forma e as telas não dependem de um segundo modelo.
class SqliteLocalStore implements LocalStore {
  SqliteLocalStore(this._db, {required this.userId, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _migrate();
  }

  final CommonDatabase _db;
  final DateTime Function() _clock;

  @override
  final String userId;

  static const _schemaVersion = 1;
  int _txDepth = 0;

  void _migrate() {
    final version = _db.select('pragma user_version').first.values.first as int;
    if (version >= _schemaVersion) return;
    _db.execute('''
      create table if not exists records(
        kind text not null,
        id text not null,
        data text not null,
        base text,
        remote text,
        conflict_keys text,
        state text not null,
        primary key(kind, id)
      );
      create table if not exists outbox(
        seq integer primary key autoincrement,
        op_id text not null unique,
        user_id text not null,
        kind text not null,
        entity_id text not null,
        depends_on text,
        type text not null,
        payload text not null,
        status text not null,
        attempts integer not null default 0,
        last_error text,
        next_attempt_at integer,
        created_at integer not null,
        idempotency_key text not null
      );
      create index if not exists outbox_entity on outbox(kind, entity_id);
      create table if not exists meta(key text primary key, value text);
    ''');
    _db.execute('pragma user_version = $_schemaVersion');
  }

  @override
  T transaction<T>(T Function() body) {
    if (_txDepth > 0) return body();
    _db.execute('begin immediate');
    _txDepth++;
    try {
      final result = body();
      _db.execute('commit');
      return result;
    } on Object {
      _db.execute('rollback');
      rethrow;
    } finally {
      _txDepth--;
    }
  }

  LocalRecord _record(Row row) => LocalRecord(
    kind: row['kind'] as String,
    id: row['id'] as String,
    data: decodeJsonMap(row['data'] as String),
    base: row['base'] == null ? null : decodeJsonMap(row['base'] as String),
    remote: row['remote'] == null
        ? null
        : decodeJsonMap(row['remote'] as String),
    conflictKeys: row['conflict_keys'] == null
        ? const []
        : (jsonDecode(row['conflict_keys'] as String) as List).cast<String>(),
    state: RecordState.values.byName(row['state'] as String),
  );

  @override
  LocalRecord? getRecord(String kind, String id) {
    final rows = _db.select(
      'select * from records where kind = ? and id = ?',
      [kind, id],
    );
    return rows.isEmpty ? null : _record(rows.first);
  }

  @override
  List<LocalRecord> listRecords(String kind) => _db
      .select('select * from records where kind = ? and state != ?', [
        kind,
        RecordState.pendingDelete.name,
      ])
      .map(_record)
      .toList();

  @override
  List<LocalRecord> allRecords(String kind) => _db
      .select('select * from records where kind = ?', [kind])
      .map(_record)
      .toList();

  @override
  void putRecord(LocalRecord r) {
    _db.execute(
      'insert or replace into records'
      '(kind, id, data, base, remote, conflict_keys, state) '
      'values (?, ?, ?, ?, ?, ?, ?)',
      [
        r.kind,
        r.id,
        encodeJson(r.data),
        r.base == null ? null : encodeJson(r.base),
        r.remote == null ? null : encodeJson(r.remote),
        r.conflictKeys.isEmpty ? null : encodeJson(r.conflictKeys),
        r.state.name,
      ],
    );
  }

  @override
  void deleteRecord(String kind, String id) => _db.execute(
    'delete from records where kind = ? and id = ?',
    [kind, id],
  );

  SyncOp _op(Row row) => SyncOp(
    seq: row['seq'] as int,
    opId: row['op_id'] as String,
    userId: row['user_id'] as String,
    kind: row['kind'] as String,
    entityId: row['entity_id'] as String,
    dependsOn: row['depends_on'] as String?,
    type: OpType.values.byName(row['type'] as String),
    payload: decodeJsonMap(row['payload'] as String),
    status: OpStatus.values.byName(row['status'] as String),
    attempts: row['attempts'] as int,
    lastError: row['last_error'] as String?,
    nextAttemptAt: row['next_attempt_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row['next_attempt_at'] as int),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    idempotencyKey: row['idempotency_key'] as String,
  );

  @override
  SyncOp enqueue({
    required String opId,
    required String kind,
    required String entityId,
    required OpType type,
    required Map<String, Object?> payload,
    String? dependsOn,
    String? idempotencyKey,
  }) {
    _db.execute(
      'insert into outbox(op_id, user_id, kind, entity_id, depends_on, type, '
      'payload, status, attempts, created_at, idempotency_key) '
      'values (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?)',
      [
        opId,
        userId,
        kind,
        entityId,
        dependsOn,
        type.name,
        encodeJson(payload),
        OpStatus.pending.name,
        _clock().millisecondsSinceEpoch,
        idempotencyKey ?? opId,
      ],
    );
    return _op(
      _db.select('select * from outbox where op_id = ?', [opId]).first,
    );
  }

  @override
  List<SyncOp> liveOps() =>
      _db.select('select * from outbox order by seq').map(_op).toList();

  @override
  List<SyncOp> opsForEntity(String kind, String entityId) => _db
      .select(
        'select * from outbox where kind = ? and entity_id = ? order by seq',
        [kind, entityId],
      )
      .map(_op)
      .toList();

  @override
  void updateOp(SyncOp op) => _db.execute(
    'update outbox set payload = ?, status = ?, attempts = ?, last_error = ?, '
    'next_attempt_at = ? where op_id = ?',
    [
      encodeJson(op.payload),
      op.status.name,
      op.attempts,
      op.lastError,
      op.nextAttemptAt?.millisecondsSinceEpoch,
      op.opId,
    ],
  );

  @override
  void removeOp(String opId) =>
      _db.execute('delete from outbox where op_id = ?', [opId]);

  @override
  SyncCounts counts() {
    int count(String where) =>
        _db.select('select count(*) c from outbox where $where').first['c']
            as int;
    return SyncCounts(
      pending: count("status in ('pending','syncing')"),
      failed: count("status = 'failed'"),
      conflicts: count("status = 'conflict'"),
    );
  }

  @override
  String? meta(String key) {
    final rows = _db.select('select value from meta where key = ?', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  @override
  void setMeta(String key, String? value) {
    if (value == null) {
      _db.execute('delete from meta where key = ?', [key]);
    } else {
      _db.execute('insert or replace into meta(key, value) values (?, ?)', [
        key,
        value,
      ]);
    }
  }

  @override
  void close() => _db.close();
}
