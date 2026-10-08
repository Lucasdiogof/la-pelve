import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/state/data_state.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_repository.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';

class _MockPatientRepository extends Mock implements PatientRepository {}

void main() {
  late _MockPatientRepository repository;

  final patient = Patient(id: 'p1', createdAt: DateTime.utc(2026, 1, 1));

  setUp(() {
    repository = _MockPatientRepository();
  });

  group('PatientsCubit initial load', () {
    test(
      'starts as loading (not an empty success) and loads nothing by itself',
      () async {
        final cubit = PatientsCubit(repository);
        expect(cubit.state.isInitialLoading, isTrue);
        expect(cubit.state.hasData, isFalse);
        await Future<void>.delayed(Duration.zero);
        verifyNever(() => repository.getAll());
        await cubit.close();
      },
    );

    blocTest<PatientsCubit, DataState<List<Patient>>>(
      'ensureLoaded emits the loaded patients',
      setUp: () {
        when(
          () => repository.getAll(),
        ).thenAnswer((_) async => Success([patient]));
      },
      build: () => PatientsCubit(repository),
      act: (cubit) => cubit.ensureLoaded(),
      expect: () => [
        DataState<List<Patient>>.success([patient]),
      ],
    );

    blocTest<PatientsCubit, DataState<List<Patient>>>(
      'a failed first load is a failure, never an empty success',
      setUp: () {
        when(
          () => repository.getAll(),
        ).thenAnswer((_) async => Error(ServerFailure()));
      },
      build: () => PatientsCubit(repository),
      act: (cubit) => cubit.ensureLoaded(),
      verify: (cubit) {
        expect(cubit.state.isFailureWithoutData, isTrue);
        expect(cubit.state.data, isNull);
      },
    );
  });

  group('PatientsCubit.addPatient', () {
    test('reloads the list after a successful add', () async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => repository.add(patient),
      ).thenAnswer((_) async => const Success(null));
      final cubit = PatientsCubit(repository);
      await cubit.ensureLoaded();

      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => Success([patient]));
      final result = await cubit.addPatient(patient);

      expect(result, isA<Success<void>>());
      expect(cubit.state.data, [patient]);
      verify(() => repository.add(patient)).called(1);
      await cubit.close();
    });

    test('does not reload the list when the add fails', () async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => repository.add(patient),
      ).thenAnswer((_) async => Error(ServerFailure('boom')));
      final cubit = PatientsCubit(repository);
      await cubit.ensureLoaded();

      final result = await cubit.addPatient(patient);

      expect(result, isA<Error<void>>());
      expect(cubit.state.data, isEmpty);
      await cubit.close();
    });
  });

  group('PatientsCubit.deletePatient', () {
    test('reloads the list after a successful delete', () async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => Success([patient]));
      when(
        () => repository.delete(patient.id),
      ).thenAnswer((_) async => const Success(null));
      final cubit = PatientsCubit(repository);
      await cubit.ensureLoaded();

      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => const Success([]));
      final result = await cubit.deletePatient(patient.id);

      expect(result, isA<Success<void>>());
      expect(cubit.state.data, isEmpty);
      await cubit.close();
    });
  });
}
