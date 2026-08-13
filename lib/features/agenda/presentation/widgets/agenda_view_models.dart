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
        final date = dateOnly(a.date);
        return !date.isBefore(today) && !date.isAfter(endDate);
      }).toList()..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return _minutesOf(a.time).compareTo(_minutesOf(b.time));
      });

  final byDay = <DateTime, List<Appointment>>{};
  for (final appointment in upcoming) {
    byDay.putIfAbsent(dateOnly(appointment.date), () => []).add(appointment);
  }
  return byDay;
}
