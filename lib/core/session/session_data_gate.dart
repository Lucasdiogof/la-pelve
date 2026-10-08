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
  });

  final SessionDataController controller;
  final Widget child;

  @override
  State<SessionDataGate> createState() => _SessionDataGateState();
}

class _SessionDataGateState extends State<SessionDataGate> {
  final _subscriptions = <StreamSubscription<Object?>>[];
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    for (final resource in widget.controller.criticalResources) {
      _subscriptions.add(resource.stream.listen((_) => _onDataChanged()));
    }
    widget.controller.sessionVersion.addListener(_onDataChanged);
    widget.controller.ensureLoaded();
  }

  @override
  void dispose() {
    widget.controller.sessionVersion.removeListener(_onDataChanged);
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
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
      return Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          child: AppErrorState(
            title: t.sessionLoadErrorTitle,
            message: t.loadErrorMessage,
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
