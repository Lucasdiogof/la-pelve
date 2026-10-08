import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/state/resource_cubit.dart';

/// Recurso de teste: cada busca devolve o próximo Completer da fila, para o
/// teste controlar a ordem em que as respostas chegam.
class _FakeResource extends ResourceCubit<List<String>> {
  _FakeResource() : super(debugName: 'fake');

  final pending = <Completer<Result<List<String>>>>[];
  int fetchCount = 0;

  @override
  Future<Result<List<String>>> fetch() {
    fetchCount++;
    final completer = Completer<Result<List<String>>>();
    pending.add(completer);
    return completer.future;
  }

  void answer(int index, Result<List<String>> result) =>
      pending[index].complete(result);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeResource cubit;

  setUp(() => cubit = _FakeResource());
  tearDown(() => cubit.close());

  test('começa em loading, não como sucesso vazio, e não busca sozinho', () {
    expect(cubit.state.isInitialLoading, isTrue);
    expect(cubit.state.hasData, isFalse);
    expect(cubit.state.data, isNull);
    expect(cubit.fetchCount, 0);
  });

  test('primeira carga com dados', () async {
    final load = cubit.ensureLoaded();
    cubit.answer(0, const Success(['a', 'b']));
    await load;

    expect(cubit.state.data, ['a', 'b']);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.failure, isNull);
  });

  test('primeira carga realmente vazia é sucesso com lista vazia', () async {
    final load = cubit.ensureLoaded();
    cubit.answer(0, const Success([]));
    await load;

    expect(cubit.state.hasData, isTrue);
    expect(cubit.state.data, isEmpty);
    expect(cubit.state.isFailureWithoutData, isFalse);
  });

  test('primeira carga com falha vira falha sem dados (não vazio)', () async {
    final load = cubit.ensureLoaded();
    cubit.answer(0, Error(NetworkFailure()));
    await load;

    expect(cubit.state.isFailureWithoutData, isTrue);
    expect(cubit.state.data, isNull);
    expect(cubit.state.failure, isA<NetworkFailure>());
  });

  test('retry depois da falha carrega os dados', () async {
    final first = cubit.ensureLoaded();
    cubit.answer(0, Error(NetworkFailure()));
    await first;

    final retry = cubit.ensureLoaded();
    expect(cubit.state.isInitialLoading, isTrue);
    expect(cubit.state.failure, isNull);
    cubit.answer(1, const Success(['a']));
    await retry;

    expect(cubit.state.data, ['a']);
    expect(cubit.state.failure, isNull);
    expect(cubit.fetchCount, 2);
  });

  test('ensureLoaded com dados válidos não busca de novo', () async {
    final load = cubit.ensureLoaded();
    cubit.answer(0, const Success(['a']));
    await load;

    await cubit.ensureLoaded();
    expect(cubit.fetchCount, 1);
  });

  test('ensureLoaded simultâneos compartilham a mesma busca', () async {
    final a = cubit.ensureLoaded();
    final b = cubit.ensureLoaded();
    expect(cubit.fetchCount, 1);
    cubit.answer(0, const Success(['a']));
    await Future.wait([a, b]);
    expect(cubit.state.data, ['a']);
  });

  group('refresh com dados', () {
    setUp(() async {
      final load = cubit.ensureLoaded();
      cubit.answer(0, const Success(['antigo']));
      await load;
    });

    test('mantém os dados visíveis durante a busca', () async {
      final refresh = cubit.refresh();
      await _settle();

      expect(cubit.state.isRefreshing, isTrue);
      expect(cubit.state.data, ['antigo']);

      cubit.answer(1, const Success(['novo']));
      await refresh;
    });

    test('sucesso substitui os dados', () async {
      final refresh = cubit.refresh();
      cubit.answer(1, const Success(['novo']));
      await refresh;

      expect(cubit.state.data, ['novo']);
      expect(cubit.state.isLoading, isFalse);
    });

    test('falha mantém os dados anteriores e registra a falha', () async {
      final refresh = cubit.refresh();
      cubit.answer(1, Error(ServerFailure()));
      await refresh;

      expect(cubit.state.data, ['antigo']);
      expect(cubit.state.failure, isA<ServerFailure>());
      expect(cubit.state.isFailureWithoutData, isFalse);
    });
  });

  test(
    'resposta antiga que chega depois não sobrescreve a mais nova',
    () async {
      final a = cubit.refresh(); // busca A
      final b = cubit.refresh(); // busca B, iniciada depois

      cubit.answer(1, const Success(['B novo'])); // B termina primeiro
      await b;
      expect(cubit.state.data, ['B novo']);

      cubit.answer(0, const Success(['A velho'])); // A termina depois
      await a;
      expect(cubit.state.data, ['B novo']);
      expect(cubit.state.isLoading, isFalse);
    },
  );

  test('falha de uma busca antiga também é descartada', () async {
    final a = cubit.refresh();
    final b = cubit.refresh();
    cubit.answer(1, const Success(['B']));
    await b;
    cubit.answer(0, Error(ServerFailure()));
    await a;

    expect(cubit.state.data, ['B']);
    expect(cubit.state.failure, isNull);
  });

  test('reset apaga os dados e descarta a busca em andamento', () async {
    final load = cubit.ensureLoaded();
    cubit.answer(0, const Success(['usuário A']));
    await load;

    final stale = cubit.refresh();
    cubit.reset();
    expect(cubit.state.data, isNull);
    expect(cubit.state.isInitialLoading, isTrue);

    cubit.answer(1, const Success(['usuário A de novo']));
    await stale;
    expect(cubit.state.data, isNull, reason: 'resposta anterior ao reset');

    final next = cubit.ensureLoaded();
    cubit.answer(2, const Success(['usuário B']));
    await next;
    expect(cubit.state.data, ['usuário B']);
  });

  test(
    'exceção inesperada no fetch vira falha, não trava em loading',
    () async {
      final throwing = _ThrowingResource();
      addTearDown(throwing.close);
      await throwing.ensureLoaded();
      expect(throwing.state.isFailureWithoutData, isTrue);
      expect(throwing.state.failure, isA<UnexpectedFailure>());
    },
  );
}

class _ThrowingResource extends ResourceCubit<List<String>> {
  _ThrowingResource() : super(debugName: 'throwing');

  @override
  Future<Result<List<String>>> fetch() async => throw StateError('boom');
}
