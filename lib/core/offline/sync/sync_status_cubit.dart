import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/offline/connectivity_monitor.dart';
import 'package:la_pelve/core/offline/offline_session.dart';
import 'package:la_pelve/core/offline/sync/sync_engine.dart';

enum SyncUiKind {
  /// Sem armazenamento offline (Web) ou sem sessão: nada a mostrar.
  hidden,
  synced,
  offline,
  pending,
  syncing,
  error,
  conflict,
}

class SyncUiState {
  const SyncUiState({
    this.kind = SyncUiKind.hidden,
    this.pending = 0,
    this.failed = 0,
    this.conflicts = 0,
    this.justSynced = false,
  });

  final SyncUiKind kind;
  final int pending;
  final int failed;
  final int conflicts;

  /// Acabou de voltar a "tudo sincronizado": confirmação breve e discreta.
  final bool justSynced;

  /// A faixa só aparece quando há algo que a profissional precise saber.
  bool get visible =>
      kind != SyncUiKind.hidden && (kind != SyncUiKind.synced || justSynced);

  SyncUiState copyWith({bool? justSynced}) => SyncUiState(
    kind: kind,
    pending: pending,
    failed: failed,
    conflicts: conflicts,
    justSynced: justSynced ?? this.justSynced,
  );

  @override
  bool operator ==(Object other) =>
      other is SyncUiState &&
      other.kind == kind &&
      other.pending == pending &&
      other.failed == failed &&
      other.conflicts == conflicts &&
      other.justSynced == justSynced;

  @override
  int get hashCode => Object.hash(kind, pending, failed, conflicts, justSynced);
}

/// Traduz o estado do motor (e da conectividade) no estado do indicador.
class SyncStatusCubit extends Cubit<SyncUiState> {
  SyncStatusCubit(this._session, this._monitor) : super(const SyncUiState()) {
    _contexts = _session.contextChanges.listen(_attach);
    _network = _monitor.changes.listen((_) => _recompute());
    _attach(_session.active);
  }

  final OfflineSession _session;
  final ConnectivityMonitor _monitor;
  StreamSubscription<OfflineContext?>? _contexts;
  StreamSubscription<bool>? _network;
  StreamSubscription<SyncStatus>? _engine;
  SyncStatus? _last;
  Timer? _confirmTimer;
  bool _hadWork = false;

  void _attach(OfflineContext? ctx) {
    unawaited(_engine?.cancel());
    _engine = null;
    _last = null;
    _hadWork = false;
    if (ctx == null) {
      emit(const SyncUiState());
      return;
    }
    _last = ctx.engine.status;
    _engine = ctx.engine.statusStream.listen((s) {
      _last = s;
      _recompute();
    });
    _recompute();
  }

  void _recompute() {
    final s = _last;
    if (s == null) return;
    final c = s.counts;
    final SyncUiKind kind;
    if (c.conflicts > 0) {
      kind = SyncUiKind.conflict;
    } else if (c.failed > 0) {
      kind = SyncUiKind.error;
    } else if (!_monitor.isOnline || !s.isOnline) {
      kind = SyncUiKind.offline;
    } else if (s.isSyncing && c.pending > 0) {
      kind = SyncUiKind.syncing;
    } else if (c.pending > 0) {
      kind = SyncUiKind.pending;
    } else {
      kind = SyncUiKind.synced;
    }
    final hasWork = kind != SyncUiKind.synced;
    final justSynced = kind == SyncUiKind.synced && _hadWork;
    _hadWork = hasWork;
    emit(
      SyncUiState(
        kind: kind,
        pending: c.pending,
        failed: c.failed,
        conflicts: c.conflicts,
        justSynced: justSynced,
      ),
    );
    _confirmTimer?.cancel();
    if (justSynced) {
      _confirmTimer = Timer(const Duration(seconds: 3), () {
        if (!isClosed) emit(state.copyWith(justSynced: false));
      });
    }
  }

  @override
  Future<void> close() async {
    _confirmTimer?.cancel();
    await _contexts?.cancel();
    await _network?.cancel();
    await _engine?.cancel();
    return super.close();
  }
}
