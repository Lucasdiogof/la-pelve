import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/profile/domain/entities/whatsapp_connection.dart';
import 'package:la_pelve/features/profile/domain/repositories/whatsapp_connection_repository.dart';
import 'package:la_pelve/features/profile/presentation/cubit/whatsapp_connection_cubit.dart';
import 'package:la_pelve/features/profile/presentation/cubit/whatsapp_connection_state.dart';

class _MockWhatsappConnectionRepository extends Mock
    implements WhatsappConnectionRepository {}

void main() {
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

  setUp(() {
    repository = _MockWhatsappConnectionRepository();
    when(
      () => repository.isSelfConnectAvailable(),
    ).thenAnswer((_) async => const Success(false));
    when(
      () => repository.refreshRemoteStatus(),
    ).thenAnswer((_) async => const Success(WhatsappRemoteStatus()));
  });

  group('WhatsappConnectionCubit initial load — estado final', () {
    // O cubit já dispara load() no construtor; o emit(Loading) síncrono
    // desse primeiro load acontece antes do blocTest conseguir escutar o
    // stream (comportamento normal do bloc_test para side effects no
    // construtor). Por isso aqui comparamos o estado final (cubit.state)
    // em vez da sequência completa de emissões.

    blocTest<WhatsappConnectionCubit, WhatsappConnectionState>(
      'ausência de linha (Success(null)) resolve em notConnected',
      setUp: () => when(
        () => repository.getCurrentConnection(),
      ).thenAnswer((_) async => const Success(null)),
      build: () => WhatsappConnectionCubit(repository),
      wait: const Duration(milliseconds: 1),
      verify: (cubit) {
        expect(cubit.state, const WhatsappConnectionNotConnected());
      },
    );

    blocTest<WhatsappConnectionCubit, WhatsappConnectionState>(
      'status pending resolve em WhatsappConnectionPending',
      setUp: () {
        final connection = connectionWith(WhatsappConnectionStatus.pending);
        when(
          () => repository.getCurrentConnection(),
        ).thenAnswer((_) async => Success(connection));
      },
      build: () => WhatsappConnectionCubit(repository),
      wait: const Duration(milliseconds: 1),
      verify: (cubit) {
        expect(cubit.state, isA<WhatsappConnectionPending>());
      },
    );

    blocTest<WhatsappConnectionCubit, WhatsappConnectionState>(
      'status connected resolve em WhatsappConnectionConnected com os dados',
      setUp: () {
        final connection = connectionWith(
          WhatsappConnectionStatus.connected,
          displayPhoneNumber: '+5562999999999',
          connectedAt: DateTime.utc(2026, 1, 15),
        );
        when(
          () => repository.getCurrentConnection(),
        ).thenAnswer((_) async => Success(connection));
      },
      build: () => WhatsappConnectionCubit(repository),
      wait: const Duration(milliseconds: 1),
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<WhatsappConnectionConnected>());
        expect(
          (state as WhatsappConnectionConnected).connection.displayPhoneNumber,
          '+5562999999999',
        );
      },
    );

    blocTest<WhatsappConnectionCubit, WhatsappConnectionState>(
      'status disconnected resolve em WhatsappConnectionDisconnected',
      setUp: () {
        final connection = connectionWith(
          WhatsappConnectionStatus.disconnected,
          disconnectedAt: DateTime.utc(2026, 2, 1),
        );
        when(
          () => repository.getCurrentConnection(),
        ).thenAnswer((_) async => Success(connection));
      },
      build: () => WhatsappConnectionCubit(repository),
      wait: const Duration(milliseconds: 1),
      verify: (cubit) {
        expect(cubit.state, isA<WhatsappConnectionDisconnected>());
      },
    );

    blocTest<WhatsappConnectionCubit, WhatsappConnectionState>(
      'status error (vindo do banco) resolve em WhatsappConnectionError, '
      'nunca WhatsappConnectionLoadFailure',
      setUp: () {
        final connection = connectionWith(
          WhatsappConnectionStatus.error,
          lastError: {'code': 'META_REJECTED'},
        );
        when(
          () => repository.getCurrentConnection(),
        ).thenAnswer((_) async => Success(connection));
      },
      build: () => WhatsappConnectionCubit(repository),
      wait: const Duration(milliseconds: 1),
      verify: (cubit) {
        expect(cubit.state, isA<WhatsappConnectionError>());
      },
    );

    blocTest<WhatsappConnectionCubit, WhatsappConnectionState>(
      'falha ao CONSULTAR o Supabase resolve em WhatsappConnectionLoadFailure, '
      'nunca WhatsappConnectionNotConnected',
      setUp: () => when(
        () => repository.getCurrentConnection(),
      ).thenAnswer((_) async => Error(NetworkFailure())),
      build: () => WhatsappConnectionCubit(repository),
      wait: const Duration(milliseconds: 1),
      verify: (cubit) {
        expect(cubit.state, isA<WhatsappConnectionLoadFailure>());
        expect(cubit.state, isNot(isA<WhatsappConnectionNotConnected>()));
      },
    );
  });

  group('WhatsappConnectionCubit.load as retry', () {
    blocTest<WhatsappConnectionCubit, WhatsappConnectionState>(
      'chamar load() de novo depois que a primeira falha já resolveu pode '
      'terminar em sucesso',
      setUp: () {
        var callCount = 0;
        when(() => repository.getCurrentConnection()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return Error(NetworkFailure());
          return const Success(null);
        });
      },
      build: () => WhatsappConnectionCubit(repository),
      act: (cubit) async {
        // Deixa o load() do construtor (a 1ª chamada, que falha) terminar
        // antes de disparar o retry explícito — senão as duas chamadas
        // concorrentes disputam a mesma emissão de Loading.
        await Future<void>.delayed(Duration.zero);
        await cubit.load();
      },
      expect: () => [
        isA<WhatsappConnectionLoadFailure>(),
        const WhatsappConnectionLoading(),
        const WhatsappConnectionNotConnected(),
      ],
      verify: (_) {
        verify(() => repository.getCurrentConnection()).called(2);
      },
    );
  });

  group('conexão pelo app', () {
    final url = Uri.parse(
      'https://lapelve.example/whatsapp-connect.html#state=x',
    );

    Future<WhatsappConnectionCubit> loaded({
      bool available = true,
      Future<bool> Function(Uri)? launcher,
      WhatsappConnection? connection,
    }) async {
      when(
        () => repository.getCurrentConnection(),
      ).thenAnswer((_) async => Success(connection));
      when(
        () => repository.isSelfConnectAvailable(),
      ).thenAnswer((_) async => Success(available));
      final cubit = WhatsappConnectionCubit(
        repository,
        launcher: launcher ?? (_) async => true,
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      return cubit;
    }

    test('sem disponibilidade no backend: nunca oferece conectar', () async {
      final cubit = await loaded(available: false);
      expect(
        cubit.state,
        const WhatsappConnectionNotConnected(selfConnectAvailable: false),
      );
      await cubit.close();
    });

    test(
      'falha ao consultar a disponibilidade = indisponível (seguro)',
      () async {
        when(
          () => repository.isSelfConnectAvailable(),
        ).thenAnswer((_) async => Error(ServerFailure()));
        when(
          () => repository.getCurrentConnection(),
        ).thenAnswer((_) async => const Success(null));
        final cubit = WhatsappConnectionCubit(repository);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(
          cubit.state,
          const WhatsappConnectionNotConnected(selfConnectAvailable: false),
        );
        await cubit.close();
      },
    );

    test(
      'connect: abre a URL devolvida pelo servidor e passa a "conectando"',
      () async {
        Uri? opened;
        when(
          () => repository.startConnection(),
        ).thenAnswer((_) async => Success(url));
        final cubit = await loaded(
          launcher: (u) async {
            opened = u;
            return true;
          },
        );
        await cubit.connect();
        expect(opened, url);
        expect(cubit.state, const WhatsappConnectionConnecting());
        await cubit.close();
      },
    );

    test(
      'connect: falha do servidor não abre nada nem finge conexão',
      () async {
        var launched = false;
        when(
          () => repository.startConnection(),
        ).thenAnswer((_) async => Error(ServerFailure()));
        final cubit = await loaded(
          launcher: (_) async {
            launched = true;
            return true;
          },
        );
        await cubit.connect();
        expect(launched, isFalse);
        expect(
          cubit.state,
          const WhatsappConnectionNotConnected(
            selfConnectAvailable: true,
            startFailed: true,
          ),
        );
        await cubit.close();
      },
    );

    test(
      'connect: se o navegador não abre, volta ao estado com aviso',
      () async {
        when(
          () => repository.startConnection(),
        ).thenAnswer((_) async => Success(url));
        final cubit = await loaded(launcher: (_) async => false);
        await cubit.connect();
        expect(
          cubit.state,
          const WhatsappConnectionNotConnected(
            selfConnectAvailable: true,
            startFailed: true,
          ),
        );
        await cubit.close();
      },
    );

    test('pendente: cada load reavalia no servidor antes de reler', () async {
      final cubit = await loaded(
        connection: connectionWith(WhatsappConnectionStatus.pending),
      );
      verify(() => repository.refreshRemoteStatus()).called(1);
      expect(cubit.state, isA<WhatsappConnectionPending>());
      await cubit.close();
    });

    test(
      'disconnect com sucesso relê o estado; com falha mantém conectado',
      () async {
        final connected = connectionWith(
          WhatsappConnectionStatus.connected,
          displayPhoneNumber: '+55 62 99999-9999',
          connectedAt: DateTime.utc(2026, 1, 1),
        );
        final cubit = await loaded(connection: connected);
        when(
          () => repository.disconnect(),
        ).thenAnswer((_) async => Error(ServerFailure()));
        await cubit.disconnect();
        expect(
          cubit.state,
          WhatsappConnectionConnected(connected, disconnectFailed: true),
        );

        when(
          () => repository.disconnect(),
        ).thenAnswer((_) async => const Success(null));
        when(() => repository.getCurrentConnection()).thenAnswer(
          (_) async => Success(
            connectionWith(
              WhatsappConnectionStatus.disconnected,
              disconnectedAt: DateTime.utc(2026, 2, 1),
            ),
          ),
        );
        await cubit.disconnect();
        expect(cubit.state, isA<WhatsappConnectionDisconnected>());
        await cubit.close();
      },
    );

    test(
      'conectada: confere a autorização e mostra o aviso de vencimento',
      () async {
        final expires = DateTime.utc(2026, 10, 20);
        when(() => repository.refreshRemoteStatus()).thenAnswer(
          (_) async => Success(
            WhatsappRemoteStatus(
              reason: 'token_expiring',
              tokenExpiresAt: expires,
            ),
          ),
        );
        final connected = connectionWith(WhatsappConnectionStatus.connected);
        final cubit = await loaded(connection: connected);
        verify(() => repository.refreshRemoteStatus()).called(1);
        expect(
          cubit.state,
          WhatsappConnectionConnected(
            connected,
            tokenExpiresAt: expires,
            tokenExpiring: true,
          ),
        );
        await cubit.close();
      },
    );

    test('conectada sem aviso do servidor: sem tokenExpiresAt', () async {
      final connected = connectionWith(WhatsappConnectionStatus.connected);
      final cubit = await loaded(connection: connected);
      expect(cubit.state, WhatsappConnectionConnected(connected));
      await cubit.close();
    });

    test('erro por token_invalid é reavaliado; outros erros, não', () async {
      final tokenError = connectionWith(
        WhatsappConnectionStatus.error,
        lastError: {'code': 'token_invalid'},
      );
      var cubit = await loaded(connection: tokenError);
      verify(() => repository.refreshRemoteStatus()).called(1);
      expect(cubit.state, WhatsappConnectionError(tokenError));
      await cubit.close();

      clearInteractions(repository);
      final otherError = connectionWith(
        WhatsappConnectionStatus.error,
        lastError: {'code': 'account_disabled'},
      );
      cubit = await loaded(connection: otherError);
      verifyNever(() => repository.refreshRemoteStatus());
      expect(cubit.state, WhatsappConnectionError(otherError));
      await cubit.close();
    });

    test('disconnect fora de conexão ativa é ignorado', () async {
      final cubit = await loaded();
      await cubit.disconnect();
      verifyNever(() => repository.disconnect());
      await cubit.close();
    });
  });
}
