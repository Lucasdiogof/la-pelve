import 'dart:async';

import 'package:flutter/material.dart';
import 'package:la_pelve/core/session/session_data_controller.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/shared/l10n/app_strings.dart';
import 'package:la_pelve/shared/widgets/app_error_state.dart';
import 'package:la_pelve/shared/widgets/pulsing_logo.dart';

/// Só monta [child] (Home, abas, formulários) quando os dados críticos da
/// sessão já carregaram. Enquanto isso mostra o logo (o mesmo da abertura do
/// app); se algum dado crítico falhar sem nunca ter carregado, mostra erro +
/// tentar novamente, e nunca uma clínica "vazia".
///
/// Depois da primeira carga o gate não volta a bloquear: refresh, volta do
/// background, troca de aba e retorno de formulário mantêm os dados na tela.
/// Só um [SessionDataController.clear] (logout/troca de usuário) o faz
/// voltar ao loading, e aí o usuário anterior já não tem nada visível.
class SessionDataGate extends StatefulWidget {
  const SessionDataGate({
    required this.controller,
    required this.child,
    super.key,
    this.autoRetryInterval = const Duration(seconds: 8),
  });

  final SessionDataController controller;
  final Widget child;

  /// Enquanto a tela de falha estiver visível, tenta carregar de novo sozinha
  /// nesse intervalo, para a conexão que volta destravar a entrada sem toque.
  final Duration autoRetryInterval;

  @override
  State<SessionDataGate> createState() => _SessionDataGateState();
}

class _SessionDataGateState extends State<SessionDataGate> {
  final _subscriptions = <StreamSubscription<Object?>>[];
  bool _retrying = false;
  Timer? _autoRetry;

  @override
  void initState() {
    super.initState();
    for (final resource in widget.controller.criticalResources) {
      _subscriptions.add(resource.stream.listen((_) => _onDataChanged()));
    }
    widget.controller.sessionVersion.addListener(_onDataChanged);
    widget.controller.ensureLoaded();
    _syncAutoRetry();
  }

  @override
  void dispose() {
    _autoRetry?.cancel();
    widget.controller.sessionVersion.removeListener(_onDataChanged);
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _onDataChanged() {
    if (!mounted) return;
    setState(() {});
    _syncAutoRetry();
  }

  void _syncAutoRetry() {
    if (!widget.controller.hasBlockingFailure) {
      _autoRetry?.cancel();
      _autoRetry = null;
      return;
    }
    _autoRetry ??= Timer.periodic(widget.autoRetryInterval, (_) {
      if (mounted && widget.controller.hasBlockingFailure && !_retrying) {
        _retry();
      }
    });
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await widget.controller.ensureLoaded();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) => _content(context);

  Widget _content(BuildContext context) {
    final controller = widget.controller;
    if (controller.isReady) return widget.child;
    if (controller.hasBlockingFailure && !_retrying) {
      final t = context.strings.shared;
      final offline = controller.blockingFailureIsNetwork;
      return Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          child: AppErrorState(
            title: offline ? t.offlineTitle : t.sessionLoadErrorTitle,
            message: offline ? t.offlineMessage : t.loadErrorMessage,
            retryLabel: t.retry,
            onRetry: _retry,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: context.colors.background,
      body: const Center(child: PulsingLogo(size: 64)),
    );
  }
}
