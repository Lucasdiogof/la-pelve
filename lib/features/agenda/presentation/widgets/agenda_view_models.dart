import 'package:flutter/material.dart' show TimeOfDay;
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

int _minutesOf(TimeOfDay time) => time.hour * 60 + time.minute;

Map<DateTime, List<Appointment>> groupUpcomingAppointmentsByDay(
  List<Appointment> appointments, {
  required DateTime today,
}) {
  final endDate = today.add(const Duration(days: 7));
  final upcoming =
      appointments.where((a) {
        final data = dateOnly(a.data);
        return !data.isBefore(today) && !data.isAfter(endDate);
      }).toList()..sort((a, b) {
        final byDate = a.data.compareTo(b.data);
        if (byDate != 0) return byDate;
        return _minutesOf(a.hora).compareTo(_minutesOf(b.hora));
      });

  final byDay = <DateTime, List<Appointment>>{};
  for (final appointment in upcoming) {
    byDay.putIfAbsent(dateOnly(appointment.data), () => []).add(appointment);
  }
  return byDay;
}
