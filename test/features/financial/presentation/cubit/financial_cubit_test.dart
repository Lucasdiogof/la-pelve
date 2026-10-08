import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/state/data_state.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/financial/domain/repositories/financial_repository.dart';
import 'package:la_pelve/features/financial/presentation/cubit/financial_cubit.dart';

class _MockFinancialRepository extends Mock implements FinancialRepository {}

void main() {
  late _MockFinancialRepository repository;

  final entry = FinancialEntry(
    id: 'f1',
    patientName: 'Maria',
    date: DateTime.utc(2026, 3, 5),
    amount: 150,
  );

  setUp(() {
    repository = _MockFinancialRepository();
  });

  group('FinancialCubit initial load', () {
    test(
      'starts as loading (not an empty success) and loads nothing by itself',
      () async {
        final cubit = FinancialCubit(repository);
        expect(cubit.state.isInitialLoading, isTrue);
        expect(cubit.state.hasData, isFalse);
        await Future<void>.delayed(Duration.zero);
        verifyNever(() => repository.getAll());
        await cubit.close();
      },
    );

    blocTest<FinancialCubit, DataState<List<FinancialEntry>>>(
      'ensureLoaded emits the loaded entries',
      setUp: () {
        when(
          () => repository.getAll(),
        ).thenAnswer((_) async => Success([entry]));
      },
      build: () => FinancialCubit(repository),
      act: (cubit) => cubit.ensureLoaded(),
      expect: () => [
        DataState<List<FinancialEntry>>.success([entry]),
      ],
    );

    blocTest<FinancialCubit, DataState<List<FinancialEntry>>>(
      'a failed first load is a failure, never an empty success',
      setUp: () {
        when(
          () => repository.getAll(),
        ).thenAnswer((_) async => Error(ServerFailure()));
      },
      build: () => FinancialCubit(repository),
      act: (cubit) => cubit.ensureLoaded(),
      verify: (cubit) {
        expect(cubit.state.isFailureWithoutData, isTrue);
        expect(cubit.state.data, isNull);
      },
    );
  });

  group('FinancialCubit.addEntry', () {
    test('reloads the list after a successful add', () async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => repository.add(entry),
      ).thenAnswer((_) async => const Success(null));
      final cubit = FinancialCubit(repository);
      await cubit.ensureLoaded();

      when(() => repository.getAll()).thenAnswer((_) async => Success([entry]));
      final result = await cubit.addEntry(entry);

      expect(result, isA<Success<void>>());
      expect(cubit.state.data, [entry]);
      await cubit.close();
    });

    test('does not reload the list when the add fails', () async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => repository.add(entry),
      ).thenAnswer((_) async => Error(ServerFailure()));
      final cubit = FinancialCubit(repository);
      await cubit.ensureLoaded();

      final result = await cubit.addEntry(entry);

      expect(result, isA<Error<void>>());
      expect(cubit.state.data, isEmpty);
      await cubit.close();
    });
  });

  group('FinancialCubit.deleteEntry', () {
    test('reloads the list after a successful delete', () async {
      when(() => repository.getAll()).thenAnswer((_) async => Success([entry]));
      when(
        () => repository.delete(entry.id),
      ).thenAnswer((_) async => const Success(null));
      final cubit = FinancialCubit(repository);
      await cubit.ensureLoaded();

      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => const Success([]));
      final result = await cubit.deleteEntry(entry.id);

      expect(result, isA<Success<void>>());
      expect(cubit.state.data, isEmpty);
      await cubit.close();
    });

    test('does not reload the list when the delete fails', () async {
      when(() => repository.getAll()).thenAnswer((_) async => Success([entry]));
      when(
        () => repository.delete(entry.id),
      ).thenAnswer((_) async => Error(ServerFailure()));
      final cubit = FinancialCubit(repository);
      await cubit.ensureLoaded();

      final result = await cubit.deleteEntry(entry.id);

      expect(result, isA<Error<void>>());
      expect(cubit.state.data, [entry]);
      await cubit.close();
    });
  });
}
