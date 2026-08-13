import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/widgets/agenda_view_models.dart';

void main() {
  final today = DateTime(2026, 3, 5);

  Appointment appointmentOn(
    DateTime day, {
    String id = 'a',
    TimeOfDay time = const TimeOfDay(hour: 12, minute: 0),
  }) {
    return Appointment(id: id, date: day, time: time, patientName: 'Paciente');
  }

  group('groupUpcomingAppointmentsByDay', () {
    test('excludes appointments before today and after day 7', () {
      final result = groupUpcomingAppointmentsByDay([
        appointmentOn(today.subtract(const Duration(days: 1)), id: 'before'),
        appointmentOn(today, id: 'today'),
        appointmentOn(today.add(const Duration(days: 7)), id: 'day7'),
        appointmentOn(today.add(const Duration(days: 8)), id: 'day8'),
      ], today: today);

      expect(
        result.keys,
        containsAll([today, today.add(const Duration(days: 7))]),
      );
      expect(result.containsKey(today.add(const Duration(days: 8))), isFalse);
    });

    test('groups multiple appointments on the same day together', () {
      final result = groupUpcomingAppointmentsByDay([
        appointmentOn(
          today,
          id: 'a1',
          time: const TimeOfDay(hour: 9, minute: 0),
        ),
        appointmentOn(
          today,
          id: 'a2',
          time: const TimeOfDay(hour: 14, minute: 0),
        ),
      ], today: today);

      expect(result[today]?.map((a) => a.id).toList(), ['a1', 'a2']);
    });

    test('sorts appointments within a day by time', () {
      final result = groupUpcomingAppointmentsByDay([
        appointmentOn(
          today,
          id: 'later',
          time: const TimeOfDay(hour: 20, minute: 0),
        ),
        appointmentOn(
          today,
          id: 'earlier',
          time: const TimeOfDay(hour: 8, minute: 0),
        ),
      ], today: today);

      expect(result[today]?.map((a) => a.id).toList(), ['earlier', 'later']);
    });
  });
}
