import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_theme.dart';
import 'package:la_pelve/features/profile/domain/entities/whatsapp_connection.dart';
import 'package:la_pelve/features/profile/domain/repositories/whatsapp_connection_repository.dart';
import 'package:la_pelve/features/profile/presentation/pages/whatsapp_connection_page.dart';
import 'package:la_pelve/shared/widgets/primary_button.dart';

class _MockWhatsappConnectionRepository extends Mock
    implements WhatsappConnectionRepository {}

/// NUNCA pumpAndSettle() enquanto o estado está carregando: a tela mostra
/// um CircularProgressIndicator indeterminado. Pumps fixos bastam porque o
/// mock resolve em 1-2 microtasks.
Future<void> _pumpPastLoading(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _MockWhatsappConnectionRepository repository;

  WhatsappConnection connectionWith(
    WhatsappConnectionStatus status, {
    String? displayPhoneNumber,
    DateTime? connectedAt,
    DateTime? disconnectedAt,
    Map<String, dynamic>? lastError,
  }) => WhatsappConnection(
    id: 'c1',
    fisioterapeutaId: 'f1',
    status: status,
    displayPhoneNumber: displayPhoneNumber,
    connectedAt: connectedAt,
    disconnectedAt: disconnectedAt,
    lastError: lastError,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  Future<void> pumpWhatsappPage(WidgetTester tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) =>
              const Scaffold(body: Text('tela anterior')),
        ),
        GoRoute(
          path: '/whatsapp',
          builder: (context, state) => const WhatsappConnectionPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => LocaleCubit(),
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    // GoRouter.push() só resolve quando a rota é fechada (pop) — nunca dar
    // await nisso aqui.
    unawaited(router.push('/whatsapp'));
    await _pumpPastLoading(tester);
  }

  setUp(() {
    repository = _MockWhatsappConnectionRepository();
    if (sl.isRegistered<WhatsappConnectionRepository>()) {
      sl.unregister<WhatsappConnectionRepository>();
    }
    sl.registerLazySingleton<WhatsappConnectionRepository>(() => repository);
  });

  tearDown(() async {
    await sl.reset();
  });

  group('WhatsappConnectionPage — não conectado', () {
    testWidgets(
      'mostra o botão Conectar WhatsApp desabilitado, sem disparar nada',
      (tester) async {
        when(
          () => repository.getCurrentConnection(),
        ).thenAnswer((_) async => const Success(null));

        await pumpWhatsappPage(tester);

        expect(find.text('WhatsApp não conectado'), findsOneWidget);
        expect(find.text('Integração em configuração'), findsOneWidget);

        final buttonFinder = find.widgetWithText(
          PrimaryButton,
          'Conectar WhatsApp',
        );
        expect(buttonFinder, findsOneWidget);
        final button = tester.widget<PrimaryButton>(buttonFinder);
        expect(
          button.onPressed,
          isNull,
          reason: 'o botão não deve disparar nenhum fluxo da Meta nesta etapa',
        );

        await tester.tap(buttonFinder, warnIfMissed: false);
        await tester.pump();
        // Nenhuma segunda consulta, nenhuma navegação: só o load inicial.
        verify(() => repository.getCurrentConnection()).called(1);
      },
    );
  });

  group('WhatsappConnectionPage — pending', () {
    testWidgets(
      'mostra "Conexão em andamento" com botão de atualizar, sem spinner '
      'preso',
      (tester) async {
        when(() => repository.getCurrentConnection()).thenAnswer(
          (_) async => Success(connectionWith(WhatsappConnectionStatus.pending)),
        );

        await pumpWhatsappPage(tester);

        expect(find.text('Conexão em andamento'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.tap(find.text('Atualizar status'));
        await _pumpPastLoading(tester);

        verify(() => repository.getCurrentConnection()).called(2);
      },
    );
  });

  group('WhatsappConnectionPage — connected', () {
    testWidgets(
      'mostra o número conectado e a data, nunca o Desconectar (omitido)',
      (tester) async {
        when(() => repository.getCurrentConnection()).thenAnswer(
          (_) async => Success(
            connectionWith(
              WhatsappConnectionStatus.connected,
              displayPhoneNumber: '+55 62 99999-9999',
              connectedAt: DateTime.utc(2026, 1, 15),
            ),
          ),
        );

        await pumpWhatsappPage(tester);

        expect(find.text('Conectado'), findsOneWidget);
        expect(find.text('+55 62 99999-9999'), findsOneWidget);
        expect(find.text('Conectado desde 15/01/2026'), findsOneWidget);
        expect(find.text('Desconectar'), findsNothing);
      },
    );
  });

  group('WhatsappConnectionPage — disconnected', () {
    testWidgets('mostra WhatsApp desconectado e a data', (tester) async {
      when(() => repository.getCurrentConnection()).thenAnswer(
        (_) async => Success(
          connectionWith(
            WhatsappConnectionStatus.disconnected,
            disconnectedAt: DateTime.utc(2026, 2, 1),
          ),
        ),
      );

      await pumpWhatsappPage(tester);

      expect(find.text('WhatsApp desconectado'), findsOneWidget);
      expect(find.text('Desconectado em 01/02/2026'), findsOneWidget);
    });
  });

  group('WhatsappConnectionPage — status error (vindo do banco)', () {
    testWidgets(
      'mostra mensagem amigável e NUNCA o last_error bruto',
      (tester) async {
        when(() => repository.getCurrentConnection()).thenAnswer(
          (_) async => Success(
            connectionWith(
              WhatsappConnectionStatus.error,
              lastError: {
                'code': 'META_REJECTED_SECRET_CODE',
                'message': 'raw internal detail that must never render',
              },
            ),
          ),
        );

        await pumpWhatsappPage(tester);

        expect(
          find.text('Não foi possível concluir a conexão com o WhatsApp.'),
          findsOneWidget,
        );
        expect(find.textContaining('META_REJECTED_SECRET_CODE'), findsNothing);
        expect(
          find.textContaining('raw internal detail'),
          findsNothing,
        );

        await tester.tap(find.text('Atualizar status'));
        await _pumpPastLoading(tester);
        verify(() => repository.getCurrentConnection()).called(2);
      },
    );
  });

  group('WhatsappConnectionPage — falha ao carregar (loadFailure)', () {
    testWidgets(
      'mostra erro de carregamento separado, nunca "não conectado", com '
      'Tentar novamente e Voltar',
      (tester) async {
        when(
          () => repository.getCurrentConnection(),
        ).thenAnswer((_) async => Error(ServerFailure()));

        await pumpWhatsappPage(tester);

        expect(
          find.text(
            'Não foi possível carregar o status da conexão com o WhatsApp.',
          ),
          findsOneWidget,
        );
        expect(find.text('WhatsApp não conectado'), findsNothing);
        expect(find.text('Tentar novamente'), findsOneWidget);
        expect(find.text('Voltar'), findsOneWidget);
      },
    );

    testWidgets('Tentar novamente refaz a consulta', (tester) async {
      var callCount = 0;
      when(() => repository.getCurrentConnection()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return Error(ServerFailure());
        return const Success(null);
      });

      await pumpWhatsappPage(tester);
      await tester.tap(find.text('Tentar novamente'));
      await _pumpPastLoading(tester);

      expect(callCount, 2);
      expect(find.text('WhatsApp não conectado'), findsOneWidget);
    });

    testWidgets('Voltar fecha a tela normalmente', (tester) async {
      when(
        () => repository.getCurrentConnection(),
      ).thenAnswer((_) async => Error(ServerFailure()));

      await pumpWhatsappPage(tester);
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();

      expect(find.text('tela anterior'), findsOneWidget);
      expect(find.text('Voltar'), findsNothing);
    });
  });
}
