import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/state/data_state.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment_status.dart';
import 'package:la_pelve/features/agenda/domain/repositories/agenda_repository.dart';
import 'package:la_pelve/features/agenda/presentation/cubit/agenda_cubit.dart';

class _MockAgendaRepository extends Mock implements AgendaRepository {}

void main() {
  late _MockAgendaRepository repository;

  final appointment = Appointment(
    id: 'a1',
    date: DateTime.utc(2026, 3, 5),
    time: const TimeOfDay(hour: 10, minute: 0),
    patientName: 'Maria',
  );

  setUp(() {
    repository = _MockAgendaRepository();
  });

  group('AgendaCubit initial load', () {
    test(
      'starts as loading (not an empty success) and loads nothing by itself',
      () async {
        final cubit = AgendaCubit(repository);
        expect(cubit.state.isInitialLoading, isTrue);
        expect(cubit.state.hasData, isFalse);
        await Future<void>.delayed(Duration.zero);
        verifyNever(() => repository.getAll());
        await cubit.close();
      },
    );

    blocTest<AgendaCubit, DataState<List<Appointment>>>(
      'ensureLoaded emits the loaded appointments',
      setUp: () {
        when(
          () => repository.getAll(),
        ).thenAnswer((_) async => Success([appointment]));
      },
      build: () => AgendaCubit(repository),
      act: (cubit) => cubit.ensureLoaded(),
      expect: () => [
        DataState<List<Appointment>>.success([appointment]),
      ],
    );

    blocTest<AgendaCubit, DataState<List<Appointment>>>(
      'a failed first load is a failure, never an empty success',
      setUp: () {
        when(
          () => repository.getAll(),
        ).thenAnswer((_) async => Error(ServerFailure()));
      },
      build: () => AgendaCubit(repository),
      act: (cubit) => cubit.ensureLoaded(),
      verify: (cubit) {
        expect(cubit.state.isFailureWithoutData, isTrue);
        expect(cubit.state.data, isNull);
      },
    );
  });

  group('AgendaCubit.updateStatus', () {
    test('reloads the list after a successful status update', () async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => Success([appointment]));
      when(
        () => repository.updateStatus(
          appointment.id,
          AppointmentStatus.fulfilled,
        ),
      ).thenAnswer((_) async => const Success(null));
      final cubit = AgendaCubit(repository);
      await cubit.ensureLoaded();

      when(() => repository.getAll()).thenAnswer(
        (_) async => Success([
          appointment.copyWith(status: AppointmentStatus.fulfilled),
        ]),
      );
      final result = await cubit.updateStatus(
        appointment.id,
        AppointmentStatus.fulfilled,
      );

      expect(result, isA<Success<void>>());
      expect(cubit.state.data!.single.status, AppointmentStatus.fulfilled);
      await cubit.close();
    });

    test('does not reload the list when the update fails', () async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => Success([appointment]));
      when(
        () => repository.updateStatus(
          appointment.id,
          AppointmentStatus.fulfilled,
        ),
      ).thenAnswer((_) async => Error(ServerFailure()));
      final cubit = AgendaCubit(repository);
      await cubit.ensureLoaded();

      final result = await cubit.updateStatus(
        appointment.id,
        AppointmentStatus.fulfilled,
      );

      expect(result, isA<Error<void>>());
      expect(cubit.state.data!.single.status, AppointmentStatus.scheduled);
      await cubit.close();
    });
  });

  group('AgendaCubit.updateAppointment', () {
    test('reloads the list after a successful update', () async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => Success([appointment]));
      final updated = appointment.copyWith(patientName: 'Joana');
      when(
        () => repository.update(updated),
      ).thenAnswer((_) async => const Success(null));
      final cubit = AgendaCubit(repository);
      await cubit.ensureLoaded();

      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => Success([updated]));
      final result = await cubit.updateAppointment(updated);

      expect(result, isA<Success<void>>());
      expect(cubit.state.data!.single.patientName, 'Joana');
      await cubit.close();
    });

    test('does not reload the list when the update fails', () async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => Success([appointment]));
      final updated = appointment.copyWith(patientName: 'Joana');
      when(
        () => repository.update(updated),
      ).thenAnswer((_) async => Error(ServerFailure()));
      final cubit = AgendaCubit(repository);
      await cubit.ensureLoaded();

      final result = await cubit.updateAppointment(updated);

      expect(result, isA<Error<void>>());
      expect(cubit.state.data!.single.patientName, 'Maria');
      await cubit.close();
    });
  });

  group('AgendaCubit.deleteAppointment', () {
    test('reloads the list after a successful delete', () async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => Success([appointment]));
      when(
        () => repository.delete(appointment.id),
      ).thenAnswer((_) async => const Success(null));
      final cubit = AgendaCubit(repository);
      await cubit.ensureLoaded();

      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => const Success([]));
      final result = await cubit.deleteAppointment(appointment.id);

      expect(result, isA<Success<void>>());
      expect(cubit.state.data, isEmpty);
      await cubit.close();
    });

    test('does not reload the list when the delete fails', () async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => Success([appointment]));
      when(
        () => repository.delete(appointment.id),
      ).thenAnswer((_) async => Error(ServerFailure()));
      final cubit = AgendaCubit(repository);
      await cubit.ensureLoaded();

      final result = await cubit.deleteAppointment(appointment.id);

      expect(result, isA<Error<void>>());
      expect(cubit.state.data, [appointment]);
      await cubit.close();
    });
  });
}
