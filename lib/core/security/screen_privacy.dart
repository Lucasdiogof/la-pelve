import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Rotas que exibem dado clínico/financeiro de paciente (dado de saúde,
/// sensível na LGPD): a home inteira (as 4 abas mostram pacientes, agenda
/// ou financeiro), pacientes + prontuário/evolução, agenda e financeiro.
///
/// Fora daqui, de propósito: login, cadastro, redefinir senha e as telas de
/// perfil/configuração — nada clínico, e o usuário pode querer print delas.
const _sensitiveRoots = ['/home', '/pacientes', '/agenda', '/financeiro'];

bool isSensitiveLocation(String path) {
  return _sensitiveRoots.any(
    (root) => path == root || path.startsWith('$root/'),
  );
}

/// Liga/desliga a proteção nativa da tela:
/// - Android: `FLAG_SECURE` (bloqueia screenshot, gravação e a miniatura no
///   app switcher).
/// - iOS: capa sobre o conteúdo no app switcher e enquanto a tela estiver
///   sendo gravada/espelhada. O iOS não oferece API para bloquear print.
class ScreenPrivacy {
  ScreenPrivacy({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('la_pelve/screen_privacy');

  final MethodChannel _channel;
  bool? _last;

  Future<void> setProtected(bool protected) async {
    if (kIsWeb || _last == protected) return;
    _last = protected;
    try {
      await _channel.invokeMethod<void>('setProtected', protected);
    } on MissingPluginException {
      // Plataforma sem implementação (desktop, testes): nada a proteger.
    } on PlatformException catch (e) {
      debugPrint('ScreenPrivacy: falha ao aplicar proteção: ${e.message}');
    }
  }
}

/// Acompanha a rota do topo e liga a proteção só nas telas sensíveis.
class SensitiveContentGuard extends StatefulWidget {
  const SensitiveContentGuard({
    required this.router,
    required this.child,
    this.privacy,
    super.key,
  });

  final GoRouter router;
  final Widget child;
  final ScreenPrivacy? privacy;

  @override
  State<SensitiveContentGuard> createState() => _SensitiveContentGuardState();
}

class _SensitiveContentGuardState extends State<SensitiveContentGuard> {
  late final ScreenPrivacy _privacy = widget.privacy ?? ScreenPrivacy();

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_sync);
    _sync();
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    // `uri` não muda com push(); o último match é a tela realmente no topo.
    final config = widget.router.routerDelegate.currentConfiguration;
    final path = config.isEmpty ? config.uri.path : config.last.matchedLocation;
    unawaited(_privacy.setProtected(isSensitiveLocation(path)));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
