import 'package:la_pelve/core/offline/local/key_vault.dart';
import 'package:la_pelve/core/offline/local/local_store.dart';

/// Web/PWA: sem armazenamento clínico local. IndexedDB não é um banco
/// criptografado no aparelho com chave em hardware; por política (LGPD,
/// minimização) prontuários e dados de pacientes ficam só no mobile.
bool get offlineStoreSupported => false;

String scopeOf(String userId) => userId;

Future<LocalStore> openUserStore({
  required String userId,
  required KeyVault vault,
  Object? directory,
}) => throw UnsupportedError('Offline store is not available on this platform');

Future<void> wipeUserStore({
  required String userId,
  required KeyVault vault,
  Object? directory,
}) async {}

Future<void> purgeOtherStores({
  required String keepUserId,
  required KeyVault vault,
  Object? directory,
}) async {}
