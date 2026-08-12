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
    TimeOfDay hora = const TimeOfDay(hour: 12, minute: 0),
    AppointmentStatus status = AppointmentStatus.agendado,
    String nomePaciente = 'Paciente',
  }) {
    return Appointment(
      id: id,
      data: day,
      hora: hora,
      nomePaciente: nomePaciente,
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
          hora: const TimeOfDay(hour: 8, minute: 0),
          nomePaciente: 'B',
        ),
        appointmentOn(
          today,
          id: 'today-late-time',
          hora: const TimeOfDay(hour: 20, minute: 0),
          nomePaciente: 'A',
        ),
      ]);

      expect(result.map((e) => e.patientName).toList(), ['A', 'B']);
    });

    test('marks atendido as finalizado regardless of time', () {
      final result = buildUpcomingSchedule([
        appointmentOn(
          today.add(const Duration(days: 2)),
          hora: const TimeOfDay(hour: 23, minute: 59),
          status: AppointmentStatus.atendido,
        ),
      ]);

      expect(result.single.status, ScheduleStatus.finalizado);
    });

    test('marks cancelado and faltou as cancelado', () {
      final result = buildUpcomingSchedule([
        appointmentOn(
          today.add(const Duration(days: 2)),
          id: 'c1',
          status: AppointmentStatus.cancelado,
        ),
        appointmentOn(
          today.add(const Duration(days: 2)),
          id: 'c2',
          status: AppointmentStatus.faltou,
        ),
      ]);

      expect(result.every((e) => e.status == ScheduleStatus.cancelado), isTrue);
    });

    test('marks a today appointment already past as finalizado', () {
      final result = buildUpcomingSchedule([
        appointmentOn(
          today,
          hora: const TimeOfDay(hour: 0, minute: 1),
          status: AppointmentStatus.agendado,
        ),
      ]);

      expect(result.single.status, ScheduleStatus.finalizado);
    });

    test('assigns proximo to the first upcoming slot and aguardando to the rest', () {
      final result = buildUpcomingSchedule([
        appointmentOn(
          today.add(const Duration(days: 2)),
          id: 'first',
          status: AppointmentStatus.agendado,
        ),
        appointmentOn(
          today.add(const Duration(days: 3)),
          id: 'second',
          status: AppointmentStatus.confirmado,
        ),
      ]);

      expect(result[0].status, ScheduleStatus.proximo);
      expect(result[1].status, ScheduleStatus.aguardando);
    });

    test('a cancelled appointment does not consume the proximo slot', () {
      final result = buildUpcomingSchedule([
        appointmentOn(
          today.add(const Duration(days: 1)),
          id: 'cancelled',
          status: AppointmentStatus.cancelado,
        ),
        appointmentOn(
          today.add(const Duration(days: 2)),
          id: 'next',
          status: AppointmentStatus.agendado,
        ),
      ]);

      final next = result.firstWhere((e) => e.status != ScheduleStatus.cancelado);
      expect(next.status, ScheduleStatus.proximo);
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
        'today': result.firstWhere((e) => e.time == '12:00' && e.dayLabel == 'Hoje'),
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
        appointmentOn(today, nomePaciente: '   '),
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

    test('sums only pago entries from the current month', () {
      final overview = buildClinicOverview(
        patientCount: 0,
        appointments: const [],
        financialEntries: [
          FinancialEntry(
            id: 'f1',
            patientName: 'A',
            data: DateTime(now.year, now.month, 10),
            valor: 100,
            status: StatusPagamento.pago,
          ),
          FinancialEntry(
            id: 'f2',
            patientName: 'B',
            data: DateTime(now.year, now.month, 15),
            valor: 50,
            status: StatusPagamento.pendente,
          ),
          FinancialEntry(
            id: 'f3',
            patientName: 'C',
            data: DateTime(now.year, now.month - 1, 10),
            valor: 999,
            status: StatusPagamento.pago,
          ),
        ],
      );

      expect(overview.receivedThisMonth, 100);
    });
  });
}
