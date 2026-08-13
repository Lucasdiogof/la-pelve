import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment_status.dart';

void main() {
  group('Appointment.toJson/fromJson', () {
    test('round-trips date, time and status', () {
      final appointment = Appointment(
        id: 'a1',
        date: DateTime(2026, 3, 5),
        time: const TimeOfDay(hour: 14, minute: 30),
        patientName: 'Maria',
        status: AppointmentStatus.confirmed,
      );

      final restored = Appointment.fromJson(appointment.toJson());

      expect(restored, appointment);
    });

    test('serializes the time with leading zeros', () {
      final appointment = Appointment(
        id: 'a1',
        date: DateTime(2026, 3, 5),
        time: const TimeOfDay(hour: 9, minute: 5),
        patientName: 'Maria',
      );

      expect(appointment.toJson()['time'], '09:05:00');
    });

    test('defaults to scheduled for an unknown status', () {
      final json = {
        'id': 'a1',
        'date': '2026-03-05',
        'time': '09:00:00',
        'patient_name': 'Maria',
        'status': 'unknown_status',
      };

      expect(Appointment.fromJson(json).status, AppointmentStatus.scheduled);
    });

    test('round-trips a linked patientId', () {
      final appointment = Appointment(
        id: 'a1',
        date: DateTime(2026, 3, 5),
        time: const TimeOfDay(hour: 9, minute: 0),
        patientName: 'Maria',
        patientId: 'p1',
      );

      final restored = Appointment.fromJson(appointment.toJson());

      expect(restored.patientId, 'p1');
    });

    test('leaves patientId null for a free-text appointment', () {
      final appointment = Appointment(
        id: 'a1',
        date: DateTime(2026, 3, 5),
        time: const TimeOfDay(hour: 9, minute: 0),
        patientName: 'Maria',
      );

      final restored = Appointment.fromJson(appointment.toJson());

      expect(restored.patientId, isNull);
    });
  });

  group('Appointment.copyWith', () {
    test('replaces only the status', () {
      final appointment = Appointment(
        id: 'a1',
        date: DateTime(2026, 3, 5),
        time: const TimeOfDay(hour: 9, minute: 0),
        patientName: 'Maria',
      );

      final updated = appointment.copyWith(status: AppointmentStatus.fulfilled);

      expect(updated.status, AppointmentStatus.fulfilled);
      expect(updated.id, appointment.id);
      expect(updated.date, appointment.date);
      expect(updated.time, appointment.time);
      expect(updated.patientName, appointment.patientName);
    });

    test('replaces date, time, name and patientId together', () {
      final appointment = Appointment(
        id: 'a1',
        date: DateTime(2026, 3, 5),
        time: const TimeOfDay(hour: 9, minute: 0),
        patientName: 'Maria',
        patientId: 'p1',
      );

      final updated = appointment.copyWith(
        date: DateTime(2026, 3, 6),
        time: const TimeOfDay(hour: 14, minute: 0),
        patientName: 'Joana',
        patientId: 'p2',
      );

      expect(updated.date, DateTime(2026, 3, 6));
      expect(updated.time, const TimeOfDay(hour: 14, minute: 0));
      expect(updated.patientName, 'Joana');
      expect(updated.patientId, 'p2');
    });

    test('clears patientId when explicitly passed null', () {
      final appointment = Appointment(
        id: 'a1',
        date: DateTime(2026, 3, 5),
        time: const TimeOfDay(hour: 9, minute: 0),
        patientName: 'Maria',
        patientId: 'p1',
      );

      final updated = appointment.copyWith(patientId: null);

      expect(updated.patientId, isNull);
    });

    test('keeps patientId when the argument is omitted', () {
      final appointment = Appointment(
        id: 'a1',
        date: DateTime(2026, 3, 5),
        time: const TimeOfDay(hour: 9, minute: 0),
        patientName: 'Maria',
        patientId: 'p1',
      );

      final updated = appointment.copyWith(patientName: 'Joana');

      expect(updated.patientId, 'p1');
    });
  });
}
