import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment_status.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_enums.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/widgets/home_view_models.dart';

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  Appointment appointmentOn(
    DateTime day, {
    String id = 'a',
    TimeOfDay time = const TimeOfDay(hour: 12, minute: 0),
    AppointmentStatus status = AppointmentStatus.scheduled,
    String patientName = 'Paciente',
  }) {
    return Appointment(
      id: id,
      date: day,
      time: time,
      patientName: patientName,
      status: status,
    );
  }

  group('buildUpcomingSchedule', () {
    test('excludes appointments before today', () {
      final result = buildUpcomingSchedule([
        appointmentOn(today.subtract(const Duration(days: 1))),
      ]);

      expect(result, isEmpty);
    });

    test('includes today and the 7-day boundary, excludes day 8', () {
      final result = buildUpcomingSchedule([
        appointmentOn(today, id: 'today'),
        appointmentOn(today.add(const Duration(days: 7)), id: 'day7'),
        appointmentOn(today.add(const Duration(days: 8)), id: 'day8'),
      ]);

      expect(result.map((e) => e.dayLabel), containsAll(['Hoje']));
      expect(result.length, 2);
    });

    test('sorts by date then by time', () {
      final result = buildUpcomingSchedule([
        appointmentOn(
          today.add(const Duration(days: 1)),
          id: 'later-day-early-time',
          time: const TimeOfDay(hour: 8, minute: 0),
          patientName: 'B',
        ),
        appointmentOn(
          today,
          id: 'today-late-time',
          time: const TimeOfDay(hour: 20, minute: 0),
          patientName: 'A',
        ),
      ]);

      expect(result.map((e) => e.patientName).toList(), ['A', 'B']);
    });

    test('marks fulfilled as completed regardless of time', () {
      final result = buildUpcomingSchedule([
        appointmentOn(
          today.add(const Duration(days: 2)),
          time: const TimeOfDay(hour: 23, minute: 59),
          status: AppointmentStatus.fulfilled,
        ),
      ]);

      expect(result.single.status, ScheduleStatus.completed);
    });

    test('marks cancelled and noShow as cancelled', () {
      final result = buildUpcomingSchedule([
        appointmentOn(
          today.add(const Duration(days: 2)),
          id: 'c1',
          status: AppointmentStatus.cancelled,
        ),
        appointmentOn(
          today.add(const Duration(days: 2)),
          id: 'c2',
          status: AppointmentStatus.noShow,
        ),
      ]);

      expect(result.every((e) => e.status == ScheduleStatus.cancelled), isTrue);
    });

    test('marks a today appointment already past as completed', () {
      final result = buildUpcomingSchedule([
        appointmentOn(
          today,
          time: const TimeOfDay(hour: 0, minute: 1),
          status: AppointmentStatus.scheduled,
        ),
      ]);

      expect(result.single.status, ScheduleStatus.completed);
    });

    test('assigns next to the first upcoming slot and waiting to the rest', () {
      final result = buildUpcomingSchedule([
        appointmentOn(
          today.add(const Duration(days: 2)),
          id: 'first',
          status: AppointmentStatus.scheduled,
        ),
        appointmentOn(
          today.add(const Duration(days: 3)),
          id: 'second',
          status: AppointmentStatus.confirmed,
        ),
      ]);

      expect(result[0].status, ScheduleStatus.next);
      expect(result[1].status, ScheduleStatus.waiting);
    });

    test('a cancelled appointment does not consume the next slot', () {
      final result = buildUpcomingSchedule([
        appointmentOn(
          today.add(const Duration(days: 1)),
          id: 'cancelled',
          status: AppointmentStatus.cancelled,
        ),
        appointmentOn(
          today.add(const Duration(days: 2)),
          id: 'next',
          status: AppointmentStatus.scheduled,
        ),
      ]);

      final next = result.firstWhere(
        (e) => e.status != ScheduleStatus.cancelled,
      );
      expect(next.status, ScheduleStatus.next);
    });

    test('labels today, tomorrow and other days correctly', () {
      const weekdaysShort = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
      final farDay = today.add(const Duration(days: 3));

      final result = buildUpcomingSchedule([
        appointmentOn(today, id: 'today'),
        appointmentOn(today.add(const Duration(days: 1)), id: 'tomorrow'),
        appointmentOn(farDay, id: 'far'),
      ]);

      final byId = {
        'today': result.firstWhere(
          (e) => e.time == '12:00' && e.dayLabel == 'Hoje',
        ),
      };
      expect(byId['today'], isNotNull);
      expect(result.any((e) => e.dayLabel == 'Amanhã'), isTrue);
      expect(
        result.any((e) => e.dayLabel == weekdaysShort[farDay.weekday - 1]),
        isTrue,
      );
    });

    test('falls back to Sem nome for a blank patient name', () {
      final result = buildUpcomingSchedule([
        appointmentOn(today, patientName: '   '),
      ]);

      expect(result.single.patientName, 'Sem nome');
    });
  });

  group('buildClinicOverview', () {
    test('counts appointments within the current week only', () {
      final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final overview = buildClinicOverview(
        patientCount: 5,
        appointments: [
          appointmentOn(startOfWeek, id: 'in-week-start'),
          appointmentOn(
            endOfWeek.subtract(const Duration(minutes: 1)),
            id: 'in-week-end',
          ),
          appointmentOn(endOfWeek, id: 'next-week'),
          appointmentOn(
            startOfWeek.subtract(const Duration(days: 1)),
            id: 'last-week',
          ),
        ],
        financialEntries: const [],
      );

      expect(overview.appointmentsThisWeek, 2);
    });

    test('passes patientCount through unchanged', () {
      final overview = buildClinicOverview(
        patientCount: 42,
        appointments: const [],
        financialEntries: const [],
      );

      expect(overview.activePatients, 42);
    });

    test('sums only paid entries from the current month', () {
      final overview = buildClinicOverview(
        patientCount: 0,
        appointments: const [],
        financialEntries: [
          FinancialEntry(
            id: 'f1',
            patientName: 'A',
            date: DateTime(now.year, now.month, 10),
            amount: 100,
            status: PaymentStatus.paid,
          ),
          FinancialEntry(
            id: 'f2',
            patientName: 'B',
            date: DateTime(now.year, now.month, 15),
            amount: 50,
            status: PaymentStatus.pending,
          ),
          FinancialEntry(
            id: 'f3',
            patientName: 'C',
            date: DateTime(now.year, now.month - 1, 10),
            amount: 999,
            status: PaymentStatus.paid,
          ),
        ],
      );

      expect(overview.receivedThisMonth, 100);
    });
  });
}
