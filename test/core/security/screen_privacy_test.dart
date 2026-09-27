import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/security/screen_privacy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('isSensitiveLocation', () {
    test('telas com dado clínico/financeiro são protegidas', () {
      for (final path in [
        '/home',
        '/pacientes/novo',
        '/pacientes/abc',
        '/pacientes/abc/editar',
        '/pacientes/abc/evolucao',
        '/pacientes/abc/evolucao/novo',
        '/pacientes/abc/evolucao/e1/editar',
        '/agenda/novo',
        '/agenda/a1/editar',
        '/financeiro/novo',
        '/financeiro/f1/editar',
      ]) {
        expect(isSensitiveLocation(path), isTrue, reason: path);
      }
    });

    test('login, cadastro e configurações não são bloqueados', () {
      for (final path in [
        '/',
        '/cadastro',
        '/redefinir-senha',
        '/perfil',
        '/perfil/tema',
        '/perfil/idioma',
        '/perfil/biometria',
        '/perfil/alterar-senha',
        '/perfil/editar-nome',
        '/homepage',
      ]) {
        expect(isSensitiveLocation(path), isFalse, reason: path);
      }
    });
  });

  group('SensitiveContentGuard', () {
    const channel = MethodChannel('la_pelve/screen_privacy');
    late List<bool> calls;

    setUp(() {
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'setProtected') {
              calls.add(call.arguments as bool);
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    testWidgets('liga no prontuário, desliga no perfil e religa ao voltar', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/home', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/perfil', builder: (_, _) => const SizedBox()),
          GoRoute(
            path: '/pacientes/:id/evolucao',
            builder: (_, _) => const SizedBox(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        WidgetsApp.router(
          routerConfig: router,
          color: const Color(0xFF000000),
          builder: (context, child) => SensitiveContentGuard(
            router: router,
            privacy: ScreenPrivacy(channel: channel),
            child: child!,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, [false]);

      router.go('/home');
      await tester.pumpAndSettle();
      unawaited(router.push('/pacientes/p1/evolucao'));
      await tester.pumpAndSettle();
      expect(calls, [false, true], reason: 'sem chamada repetida');

      unawaited(router.push('/perfil'));
      await tester.pumpAndSettle();
      expect(calls.last, isFalse);

      router.pop();
      await tester.pumpAndSettle();
      expect(calls.last, isTrue);
    });
  });
}
