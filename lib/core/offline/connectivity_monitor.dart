import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Conectividade do aparelho (interface de rede). Saber que há Wi-Fi não
/// prova que o servidor responde: o motor de sincronização também marca o
/// servidor como inalcançável quando uma chamada falha por rede.
abstract class ConnectivityMonitor {
  bool get isOnline;

  Stream<bool> get changes;

  Future<void> start();

  Future<void> dispose();
}

class PlatformConnectivityMonitor implements ConnectivityMonitor {
  PlatformConnectivityMonitor([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _online = true;

  @override
  bool get isOnline => _online;

  @override
  Stream<bool> get changes => _controller.stream;

  static bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<void> start() async {
    if (_subscription != null) return;
    try {
      _online = _hasNetwork(await _connectivity.checkConnectivity());
    } on Object {
      _online = true;
    }
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _hasNetwork(results);
      if (online == _online) return;
      _online = online;
      _controller.add(online);
    });
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _controller.close();
  }
}

class FakeConnectivityMonitor implements ConnectivityMonitor {
  FakeConnectivityMonitor({this.initiallyOnline = true})
    : _online = initiallyOnline;

  final bool initiallyOnline;
  final _controller = StreamController<bool>.broadcast();
  bool _online;

  @override
  bool get isOnline => _online;

  set online(bool value) {
    if (value == _online) return;
    _online = value;
    _controller.add(value);
  }

  @override
  Stream<bool> get changes => _controller.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> dispose() => _controller.close();
}
