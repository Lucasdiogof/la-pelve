import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/offline/offline_session.dart';
import 'package:la_pelve/core/state/resource_cubit.dart';
import 'package:la_pelve/features/agenda/presentation/cubit/agenda_cubit.dart';
import 'package:la_pelve/features/financial/presentation/cubit/financial_cubit.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/features/profile/presentation/cubit/profile_cubit.dart';

/// Dono do ciclo de vida dos dados do usuário logado.
///
/// - [ensureLoaded]: bootstrap da sessão. Carrega em paralelo os dados
///   CRÍTICOS (usados de imediato pela Home e pelas abas: pacientes, agenda e
///   financeiro). O perfil vai junto, mas não segura a entrada (só a foto do
///   cabeçalho depende dele). Chamadas simultâneas compartilham a mesma carga.
/// - [refreshAll]: revalidação (pull-to-refresh, volta do background) sem
///   esconder os dados atuais.
/// - [onSessionUser] / [clear]: troca de usuário e logout. Os cubits são
///   singletons do processo; sem isso a conta B veria a lista da conta A até
///   a primeira recarga. RLS protege o banco, não a memória do app.
class SessionDataController {
  SessionDataController({
    required this.patients,
    required this.agenda,
    required this.financial,
    required this.profile,
    this.offline,
  }) {
    _offlineChanges = offline?.dataChanged.listen(_onLocalDataChanged);
  }

  final PatientsCubit patients;
  final AgendaCubit agenda;
  final FinancialCubit financial;
  final ProfileCubit profile;

  /// Armazenamento offline da sessão (null na Web ou nos testes).
  final OfflineSession? offline;
  // Vive tanto quanto o controlador (singleton do processo).
  // ignore: cancel_subscriptions
  StreamSubscription<Set<String>>? _offlineChanges;

  Future<void> dispose() async => _offlineChanges?.cancel();

  String? _userId;
  Future<void>? _bootstrap;

  /// Muda a cada [clear], de forma SÍNCRONA. Os cubits notificam por stream
  /// (assíncrono); o gate escuta isto para desmontar a área logada já no
  /// próximo frame depois de um logout/troca de usuário, sem depender da
  /// ordem das microtasks.
  final ValueNotifier<int> sessionVersion = ValueNotifier(0);

  List<ResourceCubit<Object>> get criticalResources => [
    patients,
    agenda,
    financial,
  ];

  /// Todos os dados críticos carregaram ao menos uma vez nesta sessão.
  bool get isReady => criticalResources.every((c) => c.state.hasData);

  /// Algum dado crítico falhou sem nunca ter carregado (tela de erro).
  bool get hasBlockingFailure =>
      criticalResources.any((c) => c.state.isFailureWithoutData);

  /// A falha que bloqueia a entrada é de rede (sem conexão/tempo esgotado):
  /// a sessão continua válida e a tela explica isso em vez de um erro genérico.
  bool get blockingFailureIsNetwork => criticalResources.any(
    (c) => c.state.isFailureWithoutData && c.state.failure is NetworkFailure,
  );

  Future<void> ensureLoaded() {
    return _bootstrap ??= _runBootstrap().whenComplete(() {
      _bootstrap = null;
    });
  }

  Future<void> _runBootstrap() async {
    final total = Stopwatch()..start();
    unawaited(profile.ensureLoaded());
    await Future.wait([
      for (final resource in criticalResources) _timed(resource),
    ]);
    if (kDebugMode) {
      debugPrint(
        '[DataLoad] bootstrap ${isReady ? 'pronto' : 'com falha'} em '
        '${total.elapsedMilliseconds}ms',
      );
    }
  }

  Future<void> _timed(ResourceCubit<Object> resource) async {
    final stopwatch = Stopwatch()..start();
    final hadData = resource.state.hasData;
    await resource.ensureLoaded();
    if (kDebugMode && !hadData) {
      debugPrint(
        '[DataLoad] bootstrap/${resource.debugName}: '
        '${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  Future<void> refreshAll() => Future.wait([
    for (final resource in criticalResources) resource.refresh(),
  ]);

  /// O espelho local mudou (pull do servidor, fim de envio, conflito
  /// resolvido): as telas releem o local, o que é instantâneo.
  void _onLocalDataChanged(Set<String> kinds) {
    if (kinds.contains('patients') || kinds.contains('evolution_entries')) {
      unawaited(patients.refresh());
    }
    if (kinds.contains('appointments')) unawaited(agenda.refresh());
    if (kinds.contains('financial_entries')) unawaited(financial.refresh());
  }

  /// Sincroniza com o servidor agora (pull-to-refresh, volta do background).
  /// Sem armazenamento offline não faz nada: os cubits já leem o servidor.
  Future<void> syncNow({Duration timeout = const Duration(seconds: 20)}) async {
    final engine = offline?.active?.engine;
    if (engine == null) return;
    try {
      await engine.sync(force: true).timeout(timeout);
    } on Object {
      // Falha de rede aparece no indicador de sincronização.
    }
  }

  /// Chamado a cada evento de autenticação com o usuário da sessão atual
  /// (`null` sem sessão). Usuário diferente do anterior apaga tudo antes de
  /// qualquer tela autenticada ser montada para o novo usuário.
  void onSessionUser(String? userId) {
    if (userId == _userId) return;
    clear();
    _userId = userId;
    // Antes de qualquer leitura: o banco local deste usuário (e só dele).
    unawaited(offline?.onUser(userId));
    if (userId != null) agenda.startRealtime(userId);
  }

  void clear() {
    _userId = null;
    _bootstrap = null;
    for (final resource in criticalResources) {
      resource.reset();
    }
    profile.reset();
    sessionVersion.value++;
  }
}
