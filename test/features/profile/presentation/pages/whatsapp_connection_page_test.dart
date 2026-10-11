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
import 'package:la_pelve/shared/widgets/app_error_state.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';
import 'package:la_pelve/shared/widgets/app_status_badge.dart';
import 'package:la_pelve/shared/widgets/modern_app_bar.dart';
import 'package:la_pelve/shared/widgets/primary_button.dart';

class _MockWhatsappConnectionRepository extends Mock
    implements WhatsappConnectionRepository {}

/// NUNCA pumpAndSettle() enquanto o estado está carregando: a área de status
/// mostra um indicador indeterminado. Pumps fixos bastam porque o mock
/// resolve em 1-2 microtasks.
Future<void> _pumpPastLoading(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

const _intro =
    'Conecte o WhatsApp da sua clínica para automatizar a comunicação com '
    'suas pacientes.';
const _benefits = [
  'Lembretes automáticos de consultas',
  'Confirmação de atendimento pelo WhatsApp',
  'Atualização automática da agenda após a confirmação',
];
const _preparingMessage =
    'Estamos finalizando a configuração para que você possa conectar o '
    'número da sua clínica com segurança.';

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

  Future<void> pumpWhatsappPage(
    WidgetTester tester, {
    ThemeData? theme,
    Size? size,
    double textScale = 1,
  }) async {
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
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
        child: MaterialApp.router(
          theme: theme ?? AppTheme.light,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
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
    when(
      () => repository.isSelfConnectAvailable(),
    ).thenAnswer((_) async => const Success(false));
    when(
      () => repository.refreshRemoteStatus(),
    ).thenAnswer((_) async => const Success(null));
  });

  tearDown(() async {
    await sl.reset();
  });

  void notConnected() => when(
    () => repository.getCurrentConnection(),
  ).thenAnswer((_) async => const Success(null));

  group('sem conexão (integração em preparação)', () {
    testWidgets('AppBar com título e subtítulo', (tester) async {
      notConnected();
      await pumpWhatsappPage(tester);

      final appBar = tester.widget<ModernAppBar>(find.byType(ModernAppBar));
      expect(appBar.title, 'WhatsApp');
      expect(appBar.subtitle, 'Lembretes e confirmações');
      expect(appBar.showBackButton, isTrue);
    });

    testWidgets('painel único com status, descrição e os três benefícios', (
      tester,
    ) async {
      notConnected();
      await pumpWhatsappPage(tester);

      expect(find.byType(AppSection), findsOneWidget);
      expect(find.text('WhatsApp da clínica'), findsOneWidget);
      final status = tester.widget<AppStatusBadge>(
        find.widgetWithText(AppStatusBadge, 'Em configuração'),
      );
      // Informativo, nunca com cara de erro.
      expect(status.tone, isNot(AppStatusTone.danger));
      expect(status.tone, isNot(AppStatusTone.warning));
      expect(find.text(_intro), findsOneWidget);
      for (final benefit in _benefits) {
        expect(find.text(benefit), findsOneWidget);
      }
    });

    testWidgets('mostra "Integração em preparação" + "Em breve", sem botão '
        'de conectar nem loading', (tester) async {
      notConnected();
      await pumpWhatsappPage(tester);

      expect(find.text('Integração em preparação'), findsOneWidget);
      expect(find.text(_preparingMessage), findsOneWidget);
      expect(find.widgetWithText(AppStatusBadge, 'Em breve'), findsOneWidget);

      expect(find.byType(PrimaryButton), findsNothing);
      expect(find.text('Conectar WhatsApp'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(AppErrorState), findsNothing);
    });

    testWidgets('o painel começa logo abaixo da AppBar (não centralizado)', (
      tester,
    ) async {
      notConnected();
      await pumpWhatsappPage(tester, size: const Size(390, 844));

      final appBarBottom = tester.getBottomLeft(find.byType(ModernAppBar)).dy;
      final panelTop = tester.getTopLeft(find.byType(AppSection)).dy;
      expect(panelTop - appBarBottom, lessThanOrEqualTo(24));
    });
  });

  testWidgets('carregando: só a área de status indica a verificação', (
    tester,
  ) async {
    final pending = Completer<Result<WhatsappConnection?>>();
    when(
      () => repository.getCurrentConnection(),
    ).thenAnswer((_) => pending.future);
    await pumpWhatsappPage(tester);

    expect(find.text('Verificando a conexão…'), findsOneWidget);
    expect(find.text('Em configuração'), findsNothing);
    expect(find.text(_benefits.first), findsOneWidget);

    pending.complete(const Success(null));
    await _pumpPastLoading(tester);
    expect(find.text('Verificando a conexão…'), findsNothing);
    expect(find.text('Em configuração'), findsOneWidget);
  });

  testWidgets('em andamento: mensagem e "Atualizar status" refaz a consulta', (
    tester,
  ) async {
    when(() => repository.getCurrentConnection()).thenAnswer(
      (_) async => Success(connectionWith(WhatsappConnectionStatus.pending)),
    );
    await pumpWhatsappPage(tester);

    expect(find.text('Em andamento'), findsOneWidget);
    expect(find.text('Conexão em andamento'), findsOneWidget);
    await tester.tap(find.text('Atualizar status'));
    await _pumpPastLoading(tester);
    // Pendente: cada carga relê o servidor (templates/webhook) e a conexão.
    verify(() => repository.refreshRemoteStatus()).called(2);
  });

  testWidgets('conectado: número e data, com ação de desconectar', (
    tester,
  ) async {
    when(() => repository.getCurrentConnection()).thenAnswer(
      (_) async => Success(
        connectionWith(
          WhatsappConnectionStatus.connected,
          displayPhoneNumber: '+55 62 99999-9999',
          connectedAt: DateTime(2026, 1, 15),
        ),
      ),
    );
    await pumpWhatsappPage(tester);

    expect(
      tester
          .widget<AppStatusBadge>(
            find.widgetWithText(AppStatusBadge, 'Conectado'),
          )
          .tone,
      AppStatusTone.success,
    );
    expect(find.text('+55 62 99999-9999'), findsOneWidget);
    expect(find.text('Conectado desde 15/01/2026'), findsOneWidget);
    expect(find.text('Desconectar'), findsOneWidget);
  });

  testWidgets('desconectado: status, data e a área de preparação', (
    tester,
  ) async {
    when(() => repository.getCurrentConnection()).thenAnswer(
      (_) async => Success(
        connectionWith(
          WhatsappConnectionStatus.disconnected,
          disconnectedAt: DateTime(2026, 2, 1),
        ),
      ),
    );
    await pumpWhatsappPage(tester);

    expect(find.text('Desconectado'), findsOneWidget);
    expect(find.text('Desconectado em 01/02/2026'), findsOneWidget);
    expect(find.text('Integração em preparação'), findsOneWidget);
  });

  testWidgets('erro vindo do banco: mensagem amigável, NUNCA o last_error', (
    tester,
  ) async {
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

    expect(find.text('Erro na conexão'), findsOneWidget);
    expect(
      find.text('Não foi possível concluir a conexão com o WhatsApp.'),
      findsOneWidget,
    );
    expect(find.textContaining('META_REJECTED_SECRET_CODE'), findsNothing);
    expect(find.textContaining('raw internal detail'), findsNothing);

    await tester.tap(find.text('Atualizar status'));
    await _pumpPastLoading(tester);
    verify(() => repository.getCurrentConnection()).called(2);
  });

  group('conexão pelo app (Embedded Signup liberado no backend)', () {
    void available() => when(
      () => repository.isSelfConnectAvailable(),
    ).thenAnswer((_) async => const Success(true));

    testWidgets('liberado: mostra "Conectar WhatsApp" e some a preparação', (
      tester,
    ) async {
      notConnected();
      available();
      await pumpWhatsappPage(tester);
      expect(find.widgetWithText(PrimaryButton, 'Conectar WhatsApp'), findsOne);
      expect(find.text('Integração em preparação'), findsNothing);
    });

    testWidgets('falha ao iniciar: mensagem, o botão continua e nada conecta', (
      tester,
    ) async {
      notConnected();
      available();
      when(
        () => repository.startConnection(),
      ).thenAnswer((_) async => Error(ServerFailure()));
      await pumpWhatsappPage(tester);
      await tester.tap(find.text('Conectar WhatsApp'));
      await _pumpPastLoading(tester);
      expect(
        find.text(
          'Não foi possível iniciar a conexão. Tente novamente em instantes.',
        ),
        findsOneWidget,
      );
      expect(find.text('Conectar WhatsApp'), findsOneWidget);
      expect(find.text('Conectado'), findsNothing);
    });

    testWidgets('desconectar pede confirmação e só então chama o servidor', (
      tester,
    ) async {
      when(() => repository.getCurrentConnection()).thenAnswer(
        (_) async => Success(
          connectionWith(
            WhatsappConnectionStatus.connected,
            displayPhoneNumber: '+55 62 99999-9999',
            connectedAt: DateTime(2026, 1, 15),
          ),
        ),
      );
      when(
        () => repository.disconnect(),
      ).thenAnswer((_) async => const Success(null));
      await pumpWhatsappPage(tester);

      await tester.tap(find.text('Desconectar'));
      await tester.pumpAndSettle();
      expect(find.text('Desconectar o WhatsApp?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      verifyNever(() => repository.disconnect());

      await tester.tap(find.text('Desconectar'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Desconectar'),
        ),
      );
      await _pumpPastLoading(tester);
      verify(() => repository.disconnect()).called(1);
    });

    testWidgets('falha ao desconectar: avisa e mantém conectado', (
      tester,
    ) async {
      when(() => repository.getCurrentConnection()).thenAnswer(
        (_) async => Success(
          connectionWith(
            WhatsappConnectionStatus.connected,
            displayPhoneNumber: '+55 62 99999-9999',
            connectedAt: DateTime(2026, 1, 15),
          ),
        ),
      );
      when(
        () => repository.disconnect(),
      ).thenAnswer((_) async => Error(ServerFailure()));
      await pumpWhatsappPage(tester);
      await tester.tap(find.text('Desconectar'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Desconectar'),
        ),
      );
      await _pumpPastLoading(tester);
      expect(
        find.text('Não foi possível desconectar. A conexão continua ativa.'),
        findsOneWidget,
      );
      expect(find.text('+55 62 99999-9999'), findsOneWidget);
    });
  });

  group('falha ao consultar (loadFailure)', () {
    testWidgets('erro + tentar novamente, nunca "em configuração"', (
      tester,
    ) async {
      when(
        () => repository.getCurrentConnection(),
      ).thenAnswer((_) async => Error(ServerFailure()));
      await pumpWhatsappPage(tester);

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(
        find.text(
          'Não foi possível carregar o status da conexão com o WhatsApp.',
        ),
        findsOneWidget,
      );
      expect(find.text('Em configuração'), findsNothing);
      expect(find.text('Integração em preparação'), findsNothing);
    });

    testWidgets('tentar novamente refaz a consulta', (tester) async {
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
      expect(find.text('Integração em preparação'), findsOneWidget);
    });

    testWidgets('voltar pela AppBar fecha a tela', (tester) async {
      when(
        () => repository.getCurrentConnection(),
      ).thenAnswer((_) async => Error(ServerFailure()));
      await pumpWhatsappPage(tester);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('tela anterior'), findsOneWidget);
    });
  });

  group('layout sem overflow', () {
    for (final (name, theme) in [
      ('claro', AppTheme.light),
      ('escuro', AppTheme.dark),
    ]) {
      for (final (label, size, scale) in [
        ('Android pequeno 320x568', const Size(320, 568), 1.0),
        ('iPhone 390x844', const Size(390, 844), 1.0),
        ('tablet 800x1280', const Size(800, 1280), 1.0),
        ('320 com texto 1.5x', const Size(320, 640), 1.5),
        ('360 com texto 2x', const Size(360, 780), 2.0),
      ]) {
        testWidgets('$name · $label', (tester) async {
          notConnected();
          await pumpWhatsappPage(
            tester,
            theme: theme,
            size: size,
            textScale: scale,
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Integração em preparação'), findsOneWidget);
        });
      }
    }
  });
}
