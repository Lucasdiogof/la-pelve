import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda a chave do banco local no Keychain (iOS) / Keystore (Android).
/// Uma chave aleatória por usuário: apagar a chave torna o arquivo ilegível.
abstract class KeyVault {
  Future<String> getOrCreateKey(String scope);

  Future<void> deleteKey(String scope);
}

class SecureStorageKeyVault implements KeyVault {
  SecureStorageKeyVault([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              // Só depois do primeiro desbloqueio e nunca em backup/iCloud.
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  static String _name(String scope) => 'lapelve_offline_key_$scope';

  @override
  Future<String> getOrCreateKey(String scope) async {
    final existing = await _storage.read(key: _name(scope));
    if (existing != null && existing.length == 64) return existing;
    final random = Random.secure();
    final key = List.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _storage.write(key: _name(scope), value: key);
    return key;
  }

  @override
  Future<void> deleteKey(String scope) => _storage.delete(key: _name(scope));
}

class InMemoryKeyVault implements KeyVault {
  final Map<String, String> keys = {};

  @override
  Future<String> getOrCreateKey(String scope) async => keys.putIfAbsent(
    scope,
    () => List.generate(64, (i) => (i % 16).toRadixString(16)).join(),
  );

  @override
  Future<void> deleteKey(String scope) async => keys.remove(scope);
}
