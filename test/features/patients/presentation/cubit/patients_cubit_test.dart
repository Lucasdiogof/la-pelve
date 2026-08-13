import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fisioterapia_pelvica/core/error/failures.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/patient_repository.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';

class _MockPatientRepository extends Mock implements PatientRepository {}

void main() {
  late _MockPatientRepository repository;

  final patient = Patient(id: 'p1', createdAt: DateTime.utc(2026, 1, 1));

  setUp(() {
    repository = _MockPatientRepository();
  });

  group('PatientsCubit initial load', () {
    blocTest<PatientsCubit, List<Patient>>(
      'emits the loaded patients on start',
      setUp: () {
        when(
          () => repository.getAll(),
        ).thenAnswer((_) async => Success([patient]));
      },
      build: () => PatientsCubit(repository),
      expect: () => [
        [patient],
      ],
    );

    blocTest<PatientsCubit, List<Patient>>(
      'keeps the previous state when the initial load fails',
      setUp: () {
        when(
          () => repository.getAll(),
        ).thenAnswer((_) async => const Error(ServerFailure()));
      },
      build: () => PatientsCubit(repository),
      expect: () => <List<Patient>>[],
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
      await Future<void>.delayed(Duration.zero);

      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => Success([patient]));
      final result = await cubit.addPatient(patient);

      expect(result, isA<Success<void>>());
      expect(cubit.state, [patient]);
      verify(() => repository.add(patient)).called(1);
      await cubit.close();
    });

    test('does not reload the list when the add fails', () async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => const Success([]));
      when(
        () => repository.add(patient),
      ).thenAnswer((_) async => const Error(ServerFailure('boom')));
      final cubit = PatientsCubit(repository);
      await Future<void>.delayed(Duration.zero);

      final result = await cubit.addPatient(patient);

      expect(result, isA<Error<void>>());
      expect(cubit.state, isEmpty);
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
      await Future<void>.delayed(Duration.zero);

      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => const Success([]));
      final result = await cubit.deletePatient(patient.id);

      expect(result, isA<Success<void>>());
      expect(cubit.state, isEmpty);
      await cubit.close();
    });
  });
}
