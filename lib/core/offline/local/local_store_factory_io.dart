import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:la_pelve/core/offline/local/key_vault.dart';
import 'package:la_pelve/core/offline/local/local_store.dart';
import 'package:la_pelve/core/offline/local/sqlite_local_store.dart';

/// Android/iOS (e desktop): banco SQLite cifrado em repouso, um arquivo por
/// usuário, com chave própria no Keychain/Keystore.
bool get offlineStoreSupported => true;

/// Id do usuário em hash: o nome do arquivo não revela o usuário.
String scopeOf(String userId) =>
    sha256.convert(userId.codeUnits).toString().substring(0, 16);

Future<Directory> _dir() async {
  final base = await getApplicationSupportDirectory();
  final dir = Directory(p.join(base.path, 'offline'));
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir;
}

File _file(Directory dir, String scope) =>
    File(p.join(dir.path, 'lp_$scope.db'));

Future<LocalStore> openUserStore({
  required String userId,
  required KeyVault vault,
  Directory? directory,
}) async {
  final dir = directory ?? await _dir();
  final scope = scopeOf(userId);
  final file = _file(dir, scope);
  final key = await vault.getOrCreateKey(scope);
  try {
    return SqliteLocalStore(_open(file.path, key), userId: userId);
  } on SqliteException catch (e) {
    // Chave perdida/arquivo corrompido: o cache é descartável (o servidor é a
    // fonte da verdade). Recria vazio em vez de travar o app.
    debugPrint(
      '[Offline] banco local ilegível (${e.extendedResultCode}); '
      'recriando',
    );
    await _deleteFiles(file);
    return SqliteLocalStore(_open(file.path, key), userId: userId);
  }
}

Database _open(String path, String hexKey) {
  final db = sqlite3.open(path);
  try {
    db.execute("pragma key = \"x'$hexKey'\"");
    // Força a leitura da primeira página: com chave errada falha aqui.
    db.select('select count(*) from sqlite_master');
    db.execute('pragma journal_mode = wal');
    db.execute('pragma secure_delete = on');
    return db;
  } on Object {
    db.close();
    rethrow;
  }
}

Future<void> _deleteFiles(File db) async {
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    final f = File('${db.path}$suffix');
    if (f.existsSync()) f.deleteSync();
  }
}

/// Apaga o banco e a chave do usuário (logout explícito, exclusão de conta).
Future<void> wipeUserStore({
  required String userId,
  required KeyVault vault,
  Directory? directory,
}) async {
  final dir = directory ?? await _dir();
  final scope = scopeOf(userId);
  await _deleteFiles(_file(dir, scope));
  await vault.deleteKey(scope);
}

/// Apaga o banco de qualquer outro usuário (troca de conta no aparelho).
Future<void> purgeOtherStores({
  required String keepUserId,
  required KeyVault vault,
  Directory? directory,
}) async {
  final dir = directory ?? await _dir();
  final keep = 'lp_${scopeOf(keepUserId)}.db';
  for (final entity in dir.listSync()) {
    final name = p.basename(entity.path);
    if (!name.startsWith('lp_') || name.startsWith(keep)) continue;
    final scope = name.substring(3, 19);
    if (entity is File) entity.deleteSync();
    await vault.deleteKey(scope);
  }
}
