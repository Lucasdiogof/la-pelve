import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment_status.dart';

void main() {
  group('Appointment.toJson/fromJson', () {
    test('round-trips date, time and status', () {
      final appointment = Appointment(
        id: 'a1',
        data: DateTime(2026, 3, 5),
        hora: const TimeOfDay(hour: 14, minute: 30),
        nomePaciente: 'Maria',
        status: AppointmentStatus.confirmado,
      );

      final restored = Appointment.fromJson(appointment.toJson());

      expect(restored, appointment);
    });

    test('serializes the time with leading zeros', () {
      final appointment = Appointment(
        id: 'a1',
        data: DateTime(2026, 3, 5),
        hora: const TimeOfDay(hour: 9, minute: 5),
        nomePaciente: 'Maria',
      );

      expect(appointment.toJson()['hora'], '09:05:00');
    });

    test('defaults to agendado for an unknown status', () {
      final json = {
        'id': 'a1',
        'data': '2026-03-05',
        'hora': '09:00:00',
        'nome_paciente': 'Maria',
        'status': 'unknown_status',
      };

      expect(Appointment.fromJson(json).status, AppointmentStatus.agendado);
    });
  });

  group('Appointment.copyWith', () {
    test('replaces only the status', () {
      final appointment = Appointment(
        id: 'a1',
        data: DateTime(2026, 3, 5),
        hora: const TimeOfDay(hour: 9, minute: 0),
        nomePaciente: 'Maria',
      );

      final updated = appointment.copyWith(status: AppointmentStatus.atendido);

      expect(updated.status, AppointmentStatus.atendido);
      expect(updated.id, appointment.id);
      expect(updated.data, appointment.data);
      expect(updated.hora, appointment.hora);
      expect(updated.nomePaciente, appointment.nomePaciente);
    });
  });
}
