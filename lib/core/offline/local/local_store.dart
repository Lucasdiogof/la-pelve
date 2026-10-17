import 'dart:convert';

/// Estado de sincronização de um registro local.
enum RecordState {
  /// Igual ao último estado conhecido do servidor.
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete,

  /// Alteração local e alteração remota incompatíveis: exige decisão da
  /// profissional (nada é sobrescrito sem ela).
  conflict,
}

enum OpType { create, update, delete }

enum OpStatus { pending, syncing, synced, conflict, failed }

/// Um registro de uma tabela espelhada localmente.
///
/// [data] é a visão local (servidor + alterações pendentes). [base] é o último
/// snapshot conhecido do servidor: serve de ancestral comum para detectar
/// alteração concorrente (merge de 3 vias). [remote] guarda a versão do
/// servidor que colidiu, enquanto o estado for [RecordState.conflict].
class LocalRecord {
  const LocalRecord({
    required this.kind,
    required this.id,
    required this.data,
    required this.state,
    this.base,
    this.remote,
    this.conflictKeys = const [],
  });

  final String kind;
  final String id;
  final Map<String, Object?> data;
  final Map<String, Object?>? base;
  final Map<String, Object?>? remote;
  final List<String> conflictKeys;
  final RecordState state;

  bool get isPending =>
      state == RecordState.pendingCreate ||
      state == RecordState.pendingUpdate ||
      state == RecordState.pendingDelete;

  LocalRecord copyWith({
    Map<String, Object?>? data,
    Map<String, Object?>? base,
    bool clearBase = false,
    Map<String, Object?>? remote,
    bool clearRemote = false,
    List<String>? conflictKeys,
    RecordState? state,
  }) => LocalRecord(
    kind: kind,
    id: id,
    data: data ?? this.data,
    base: clearBase ? null : (base ?? this.base),
    remote: clearRemote ? null : (remote ?? this.remote),
    conflictKeys: conflictKeys ?? this.conflictKeys,
    state: state ?? this.state,
  );
}

/// Operação da fila de saída (outbox). Persistida: sobrevive ao app fechado.
///
/// O id da entidade é gerado no cliente e é o mesmo no servidor, então não há
/// "id local x remoto" a reconciliar: a criação é idempotente por id.
class SyncOp {
  const SyncOp({
    required this.seq,
    required this.opId,
    required this.userId,
    required this.kind,
    required this.entityId,
    required this.type,
    required this.payload,
    required this.status,
    required this.attempts,
    required this.createdAt,
    required this.idempotencyKey,
    this.dependsOn,
    this.lastError,
    this.nextAttemptAt,
  });

  final int seq;
  final String opId;
  final String userId;
  final String kind;
  final String entityId;

  /// "kind:id" da entidade que precisa existir no servidor antes desta
  /// operação (ex.: o paciente de uma consulta criada offline).
  final String? dependsOn;
  final OpType type;
  final Map<String, Object?> payload;
  final OpStatus status;
  final int attempts;
  final String? lastError;
  final DateTime? nextAttemptAt;
  final DateTime createdAt;
  final String idempotencyKey;

  String get entityKey => '$kind:$entityId';

  SyncOp copyWith({
    Map<String, Object?>? payload,
    OpStatus? status,
    int? attempts,
    String? lastError,
    bool clearError = false,
    DateTime? nextAttemptAt,
    bool clearNextAttempt = false,
  }) => SyncOp(
    seq: seq,
    opId: opId,
    userId: userId,
    kind: kind,
    entityId: entityId,
    type: type,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    createdAt: createdAt,
    idempotencyKey: idempotencyKey,
    dependsOn: dependsOn,
    lastError: clearError ? null : (lastError ?? this.lastError),
    nextAttemptAt: clearNextAttempt
        ? null
        : (nextAttemptAt ?? this.nextAttemptAt),
  );
}

/// Contagens para o indicador de sincronização.
class SyncCounts {
  const SyncCounts({this.pending = 0, this.failed = 0, this.conflicts = 0});

  final int pending;
  final int failed;
  final int conflicts;

  int get total => pending + failed + conflicts;
}

/// Armazenamento local (abstração única). As telas e os cubits nunca o veem;
/// só os repositórios offline e o motor de sincronização.
abstract class LocalStore {
  String get userId;

  /// Executa [body] de forma atômica: ou tudo é gravado, ou nada.
  T transaction<T>(T Function() body);

  LocalRecord? getRecord(String kind, String id);

  /// Registros visíveis (exclui os marcados para exclusão).
  List<LocalRecord> listRecords(String kind);

  /// Todos, inclusive pendingDelete (para o motor).
  List<LocalRecord> allRecords(String kind);

  void putRecord(LocalRecord record);

  void deleteRecord(String kind, String id);

  SyncOp enqueue({
    required String opId,
    required String kind,
    required String entityId,
    required OpType type,
    required Map<String, Object?> payload,
    String? dependsOn,
    String? idempotencyKey,
  });

  /// Operações vivas (não concluídas), em ordem de criação.
  List<SyncOp> liveOps();

  List<SyncOp> opsForEntity(String kind, String entityId);

  void updateOp(SyncOp op);

  void removeOp(String opId);

  SyncCounts counts();

  String? meta(String key);

  void setMeta(String key, String? value);

  void close();
}

String encodeJson(Object? value) => jsonEncode(value);

Map<String, Object?> decodeJsonMap(String source) =>
    (jsonDecode(source) as Map).cast<String, Object?>();
