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
}
