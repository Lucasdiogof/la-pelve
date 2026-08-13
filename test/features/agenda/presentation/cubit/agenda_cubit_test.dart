import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fisioterapia_pelvica/core/error/failures.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment_status.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/repositories/agenda_repository.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_cubit.dart';

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
    blocTest<AgendaCubit, List<Appointment>>(
      'emits the loaded appointments on start',
      setUp: () {
        when(
          () => repository.getAll(),
        ).thenAnswer((_) async => Success([appointment]));
      },
      build: () => AgendaCubit(repository),
      expect: () => [
        [appointment],
      ],
    );

    blocTest<AgendaCubit, List<Appointment>>(
      'keeps the previous state when the initial load fails',
      setUp: () {
        when(
          () => repository.getAll(),
        ).thenAnswer((_) async => Error(ServerFailure()));
      },
      build: () => AgendaCubit(repository),
      expect: () => <List<Appointment>>[],
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
      await Future<void>.delayed(Duration.zero);

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
      expect(cubit.state.single.status, AppointmentStatus.fulfilled);
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
      await Future<void>.delayed(Duration.zero);

      final result = await cubit.updateStatus(
        appointment.id,
        AppointmentStatus.fulfilled,
      );

      expect(result, isA<Error<void>>());
      expect(cubit.state.single.status, AppointmentStatus.scheduled);
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
      await Future<void>.delayed(Duration.zero);

      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => Success([updated]));
      final result = await cubit.updateAppointment(updated);

      expect(result, isA<Success<void>>());
      expect(cubit.state.single.patientName, 'Joana');
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
      await Future<void>.delayed(Duration.zero);

      final result = await cubit.updateAppointment(updated);

      expect(result, isA<Error<void>>());
      expect(cubit.state.single.patientName, 'Maria');
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
      await Future<void>.delayed(Duration.zero);

      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => const Success([]));
      final result = await cubit.deleteAppointment(appointment.id);

      expect(result, isA<Success<void>>());
      expect(cubit.state, isEmpty);
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
      await Future<void>.delayed(Duration.zero);

      final result = await cubit.deleteAppointment(appointment.id);

      expect(result, isA<Error<void>>());
      expect(cubit.state, [appointment]);
      await cubit.close();
    });
  });
}
