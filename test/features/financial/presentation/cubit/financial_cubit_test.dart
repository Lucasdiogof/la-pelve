import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fisioterapia_pelvica/core/error/failures.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/repositories/financial_repository.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/financial_cubit.dart';

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
    blocTest<FinancialCubit, List<FinancialEntry>>(
      'emits the loaded entries on start',
      setUp: () {
        when(
          () => repository.getAll(),
        ).thenAnswer((_) async => Success([entry]));
      },
      build: () => FinancialCubit(repository),
      expect: () => [
        [entry],
      ],
    );

    blocTest<FinancialCubit, List<FinancialEntry>>(
      'keeps the previous state when the initial load fails',
      setUp: () {
        when(
          () => repository.getAll(),
        ).thenAnswer((_) async => const Error(ServerFailure()));
      },
      build: () => FinancialCubit(repository),
      expect: () => <List<FinancialEntry>>[],
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
      await Future<void>.delayed(Duration.zero);

      when(() => repository.getAll()).thenAnswer((_) async => Success([entry]));
      final result = await cubit.addEntry(entry);

      expect(result, isA<Success<void>>());
      expect(cubit.state, [entry]);
      await cubit.close();
    });

    test('does not reload the list when the add fails', () async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => repository.add(entry),
      ).thenAnswer((_) async => const Error(ServerFailure()));
      final cubit = FinancialCubit(repository);
      await Future<void>.delayed(Duration.zero);

      final result = await cubit.addEntry(entry);

      expect(result, isA<Error<void>>());
      expect(cubit.state, isEmpty);
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
      await Future<void>.delayed(Duration.zero);

      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => const Success([]));
      final result = await cubit.deleteEntry(entry.id);

      expect(result, isA<Success<void>>());
      expect(cubit.state, isEmpty);
      await cubit.close();
    });

    test('does not reload the list when the delete fails', () async {
      when(() => repository.getAll()).thenAnswer((_) async => Success([entry]));
      when(
        () => repository.delete(entry.id),
      ).thenAnswer((_) async => const Error(ServerFailure()));
      final cubit = FinancialCubit(repository);
      await Future<void>.delayed(Duration.zero);

      final result = await cubit.deleteEntry(entry.id);

      expect(result, isA<Error<void>>());
      expect(cubit.state, [entry]);
      await cubit.close();
    });
  });
}
