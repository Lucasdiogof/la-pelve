import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment_status.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_enums.dart';

enum ScheduleStatus { finalizado, proximo, aguardando, cancelado }

extension ScheduleStatusLabel on ScheduleStatus {
  String get label => switch (this) {
    ScheduleStatus.finalizado => 'Finalizado',
    ScheduleStatus.proximo => 'Próximo',
    ScheduleStatus.aguardando => 'Aguardando',
    ScheduleStatus.cancelado => 'Cancelado',
  };
}

class ScheduleItem {
  const ScheduleItem({
    required this.dayLabel,
    required this.time,
    required this.patientName,
    required this.status,
  });

  final String dayLabel;
  final String time;
  final String patientName;
  final ScheduleStatus status;
}

class ClinicOverview {
  const ClinicOverview({
    required this.activePatients,
    required this.appointmentsThisWeek,
    required this.receivedThisMonth,
  });

  final int activePatients;
  final int appointmentsThisWeek;
  final double receivedThisMonth;
}

const _weekdaysShort = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int _minutesOf(TimeOfDay time) => time.hour * 60 + time.minute;

String _formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

String _dayLabel(DateTime day, DateTime today) {
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Amanhã';
  return _weekdaysShort[day.weekday - 1];
}

ScheduleStatus _statusFor(
  Appointment appointment,
  bool isToday,
  int nowMinutes,
  bool nextAlreadyAssigned,
) {
  switch (appointment.status) {
    case AppointmentStatus.atendido:
      return ScheduleStatus.finalizado;
    case AppointmentStatus.cancelado:
    case AppointmentStatus.faltou:
      return ScheduleStatus.cancelado;
    case AppointmentStatus.agendado:
    case AppointmentStatus.confirmado:
    case AppointmentStatus.reagendado:
      if (isToday && _minutesOf(appointment.hora) < nowMinutes) {
        return ScheduleStatus.finalizado;
      }
      return nextAlreadyAssigned
          ? ScheduleStatus.aguardando
          : ScheduleStatus.proximo;
  }
}

List<ScheduleItem> buildUpcomingSchedule(List<Appointment> appointments) {
  final now = DateTime.now();
  final today = _dateOnly(now);
  final endDate = today.add(const Duration(days: 7));
  final upcoming =
      appointments.where((a) {
        final data = _dateOnly(a.data);
        return !data.isBefore(today) && !data.isAfter(endDate);
      }).toList()..sort((a, b) {
        final byDate = a.data.compareTo(b.data);
        if (byDate != 0) return byDate;
        return _minutesOf(a.hora).compareTo(_minutesOf(b.hora));
      });

  final nowMinutes = _minutesOf(TimeOfDay.fromDateTime(now));
  var nextAssigned = false;
  final result = <ScheduleItem>[];
  for (final appointment in upcoming) {
    final isToday = _isSameDay(appointment.data, now);
    final status = _statusFor(appointment, isToday, nowMinutes, nextAssigned);
    if (status == ScheduleStatus.proximo) nextAssigned = true;
    result.add(
      ScheduleItem(
        dayLabel: _dayLabel(_dateOnly(appointment.data), today),
        time: _formatTime(appointment.hora),
        patientName: appointment.nomePaciente.trim().isEmpty
            ? 'Sem nome'
            : appointment.nomePaciente,
        status: status,
      ),
    );
  }
  return result;
}

ClinicOverview buildClinicOverview({
  required int patientCount,
  required List<Appointment> appointments,
  required List<FinancialEntry> financialEntries,
}) {
  final now = DateTime.now();
  final startOfWeek = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));
  final appointmentsThisWeek = appointments
      .where((a) => !a.data.isBefore(startOfWeek) && a.data.isBefore(endOfWeek))
      .length;

  final receivedThisMonth = financialEntries
      .where(
        (e) =>
            e.data.year == now.year &&
            e.data.month == now.month &&
            e.status == StatusPagamento.pago,
      )
      .fold<double>(0, (sum, e) => sum + e.valor);

  return ClinicOverview(
    activePatients: patientCount,
    appointmentsThisWeek: appointmentsThisWeek,
    receivedThisMonth: receivedThisMonth,
  );
}

extension ScheduleStatusStyle on ScheduleStatus {
  Color foreground(AppColors colors) => switch (this) {
    ScheduleStatus.finalizado => colors.success,
    ScheduleStatus.proximo => colors.primary,
    ScheduleStatus.aguardando => colors.primaryButton,
    ScheduleStatus.cancelado => colors.textSecondary,
  };
}
