import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:la_pelve/core/offline/connectivity_monitor.dart';
import 'package:la_pelve/core/offline/local/key_vault.dart';
import 'package:la_pelve/core/offline/local/local_store.dart';
import 'package:la_pelve/core/offline/local/local_store_factory.dart'
    as local_factory;
import 'package:la_pelve/core/offline/sync/remote_gateway.dart';
import 'package:la_pelve/core/offline/sync/sync_engine.dart';

/// Banco local + motor de sincronização de UM usuário.
class OfflineContext {
  OfflineContext(this.userId, this.store, this.engine);

  final String userId;
  final LocalStore store;
  final SyncEngine engine;
}

/// Onde os bancos moram (arquivo cifrado no aparelho; fake nos testes).
abstract class StoreProvider {
  Future<LocalStore> open(String userId, KeyVault vault);

  Future<void> wipe(String userId, KeyVault vault);

  Future<void> purgeOthers(String keepUserId, KeyVault vault);
}

class FileStoreProvider implements StoreProvider {
  const FileStoreProvider();

  @override
  Future<LocalStore> open(String userId, KeyVault vault) =>
      local_factory.openUserStore(userId: userId, vault: vault);

  @override
  Future<void> wipe(String userId, KeyVault vault) =>
      local_factory.wipeUserStore(userId: userId, vault: vault);

  @override
  Future<void> purgeOthers(String keepUserId, KeyVault vault) =>
      local_factory.purgeOtherStores(keepUserId: keepUserId, vault: vault);
}

/// Dono do ciclo de vida do armazenamento offline, acompanhando a sessão:
///
/// - login/cold start com sessão: abre o banco DESSE usuário (e apaga os de
///   qualquer outro: troca de conta no aparelho nunca mistura dados);
/// - sem sessão: fecha tudo. O arquivo cifrado fica, ilegível sem a chave do
///   Keystore, para não perder alterações se a sessão só expirou;
/// - logout explícito / exclusão de conta: [wipeUser] apaga banco e chave.
///
/// Se o banco não abrir (plataforma sem suporte, falha de Keystore), [context]
/// devolve null e os repositórios operam direto no servidor, como antes.
class OfflineSession with WidgetsBindingObserver {
  OfflineSession({
    required this.vault,
    required this.remote,
    required this.monitor,
    required this.currentUserId,
    this.provider = const FileStoreProvider(),
    this.enabled = true,
    this.autoSync = true,
  });

  final KeyVault vault;
  final RemoteGateway remote;
  final ConnectivityMonitor monitor;
  final String? Function() currentUserId;
  final StoreProvider provider;
  final bool enabled;

  /// Falso nos testes: o motor só sincroniza quando chamado.
  final bool autoSync;

  Future<OfflineContext?> _current = Future.value();
  OfflineContext? _active;
  final _changes = StreamController<OfflineContext?>.broadcast();
  StreamSubscription<Set<String>>? _dataSub;
  final _dataChanged = StreamController<Set<String>>.broadcast();

  /// Contexto ativo agora (síncrono), ou null.
  OfflineContext? get active => _active;

  /// Mudou o usuário/contexto (abriu, fechou).
  Stream<OfflineContext?> get contextChanges => _changes.stream;

  /// Dados locais mudaram (pull, fim de operação). Reemite do motor ativo.
  Stream<Set<String>> get dataChanged => _dataChanged.stream;

  /// Aguarda a abertura em andamento e devolve o contexto do usuário atual.
  Future<OfflineContext?> context() => _current;

  /// Chamado a cada evento de autenticação. Operações são serializadas.
  Future<OfflineContext?> onUser(String? userId) {
    final previous = _current;
    return _current = previous.catchError((Object _) => null).then((_) async {
      if (!enabled) return null;
      final active = _active;
      if (active?.userId == userId) return active;
      await _close();
      if (userId == null) return null;
      try {
        await provider.purgeOthers(userId, vault);
        final store = await provider.open(userId, vault);
        final engine = SyncEngine(
          store: store,
          remote: remote,
          monitor: monitor,
          currentUserId: currentUserId,
          autoSync: autoSync,
        );
        _dataSub = engine.dataChanged.listen(_dataChanged.add);
        final ctx = OfflineContext(userId, store, engine);
        _active = ctx;
        WidgetsBinding.instance.addObserver(this);
        engine.startPeriodic();
        engine.requestSync();
        _changes.add(ctx);
        return ctx;
      } on Object catch (e) {
        // Falha de Keystore/banco: segue só online. Nada sensível no log.
        debugPrint('[Offline] indisponível (${e.runtimeType})');
        return null;
      }
    });
  }

  Future<void> _close() async {
    final ctx = _active;
    _active = null;
    if (ctx == null) return;
    WidgetsBinding.instance.removeObserver(this);
    await _dataSub?.cancel();
    _dataSub = null;
    await ctx.engine.close();
    ctx.store.close();
    _changes.add(null);
  }

  /// Logout explícito, exclusão de conta: fecha o banco do usuário (se estiver
  /// aberto) e apaga arquivo e chave. Serializado com [onUser].
  Future<void> wipeUser(String userId) {
    final previous = _current;
    final done = previous.catchError((Object _) => null).then((_) async {
      if (_active?.userId == userId) await _close();
      await provider.wipe(userId, vault);
      return null;
    });
    _current = done;
    return done;
  }

  /// Quantas alterações ainda não chegaram ao servidor (para avisar antes de
  /// sair da conta).
  int get unsyncedCount => _active?.store.counts().total ?? 0;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final engine = _active?.engine;
    if (engine == null) return;
    if (state == AppLifecycleState.resumed) {
      engine.startPeriodic();
      engine.requestSync();
    } else if (state == AppLifecycleState.paused) {
      engine.stopPeriodic();
    }
  }

  Future<void> dispose() async {
    await _close();
    await _changes.close();
    await _dataChanged.close();
  }
}
