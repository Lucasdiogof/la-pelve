import 'package:la_pelve/core/offline/sync/entity_config.dart';

enum ConflictResolution {
  /// Mantém a versão do servidor e descarta a alteração local.
  keepRemote,

  /// Reaplica a alteração local por cima da versão atual do servidor.
  keepLocal,

  /// Mantém a versão do servidor E salva a local como um novo registro
  /// (só para evoluções: nenhum texto clínico se perde).
  keepBoth,
}

/// Resultado da checagem de concorrência de uma operação de edição.
class ConflictCheck {
  const ConflictCheck.none() : keys = const [], remoteDeleted = false;

  const ConflictCheck.conflict(this.keys, {this.remoteDeleted = false});

  final List<String> keys;
  final bool remoteDeleted;

  bool get hasConflict => keys.isNotEmpty || remoteDeleted;
}

bool jsonEquals(Object? a, Object? b) {
  if (a == null || b == null) return a == b;
  if (a is num && b is num) return a == b;
  if (a is Map && b is Map) {
    final keys = {...a.keys, ...b.keys};
    return keys.every((k) => jsonEquals(a[k], b[k]));
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!jsonEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// Merge de 3 vias por coluna: [base] (último estado conhecido do servidor),
/// [remote] (servidor agora) e [payload] (o que esta operação quer gravar).
///
/// - Se o servidor já tem exatamente o que a operação quer gravar, não há
///   conflito (reenvio após resposta perdida é idempotente).
/// - Entidades comuns: conflito só nas colunas que a operação edita e que o
///   servidor também mudou para outro valor. Colunas diferentes se combinam
///   (a operação é um UPDATE parcial, o resto do servidor é preservado).
/// - Entidades estritas (evolução clínica): qualquer coluna do servidor que
///   mudou desde a base e difere do pretendido é conflito, mesmo que a
///   profissional não tenha editado essa coluna.
///
/// "Última gravação vence" nunca é aplicada: na dúvida, conflito.
ConflictCheck detectConflict({
  required EntityConfig config,
  required Map<String, Object?>? base,
  required Map<String, Object?> remote,
  required Map<String, Object?> payload,
}) {
  final softColumn = config.softDeleteColumn;
  if (softColumn != null && remote[softColumn] != null) {
    return const ConflictCheck.conflict([], remoteDeleted: true);
  }
  final keys = config.strict
      ? {...payload.keys, ...?base?.keys, ...remote.keys}
      : payload.keys.toSet();
  final conflicting = <String>[];
  for (final key in keys) {
    if (!config.compares(key)) continue;
    final remoteValue = remote[key];
    if (jsonEquals(remoteValue, payload[key]) && payload.containsKey(key)) {
      continue;
    }
    final remoteChanged = base == null
        ? payload.containsKey(key)
        : !jsonEquals(remoteValue, base[key]);
    if (remoteChanged) conflicting.add(key);
  }
  conflicting.sort();
  return conflicting.isEmpty
      ? const ConflictCheck.none()
      : ConflictCheck.conflict(conflicting);
}

/// Todas as colunas de [payload] já valem o mesmo no servidor?
bool alreadyApplied(
  Map<String, Object?> remote,
  Map<String, Object?> payload,
) => payload.entries.every((e) => jsonEquals(remote[e.key], e.value));
