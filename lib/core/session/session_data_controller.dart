import 'dart:async';

import 'package:flutter/foundation.dart';
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
  });

  final PatientsCubit patients;
  final AgendaCubit agenda;
  final FinancialCubit financial;
  final ProfileCubit profile;

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

  /// Chamado a cada evento de autenticação com o usuário da sessão atual
  /// (`null` sem sessão). Usuário diferente do anterior apaga tudo antes de
  /// qualquer tela autenticada ser montada para o novo usuário.
  void onSessionUser(String? userId) {
    if (userId == _userId) return;
    clear();
    _userId = userId;
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
