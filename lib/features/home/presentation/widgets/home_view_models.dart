import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment_status.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_enums.dart';
import 'package:fisioterapia_pelvica/features/home/l10n/home_strings.dart';

enum ScheduleStatus { completed, next, waiting, cancelled }

extension ScheduleStatusLabel on ScheduleStatus {
  String label(AppLanguage language) {
    final t = HomeStrings(language);
    return switch (this) {
      ScheduleStatus.completed => t.scheduleStatusCompleted,
      ScheduleStatus.next => t.scheduleStatusNext,
      ScheduleStatus.waiting => t.scheduleStatusWaiting,
      ScheduleStatus.cancelled => t.scheduleStatusCancelled,
    };
  }
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

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int _minutesOf(TimeOfDay time) => time.hour * 60 + time.minute;

String _formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

String _dayLabel(DateTime day, DateTime today, HomeStrings t) {
  final diff = day.difference(today).inDays;
  if (diff == 0) return t.today;
  if (diff == 1) return t.tomorrow;
  return t.weekdayShortName(day.weekday);
}

ScheduleStatus _statusFor(
  Appointment appointment,
  bool isToday,
  int nowMinutes,
  bool nextAlreadyAssigned,
) {
  switch (appointment.status) {
    case AppointmentStatus.fulfilled:
      return ScheduleStatus.completed;
    case AppointmentStatus.cancelled:
    case AppointmentStatus.noShow:
      return ScheduleStatus.cancelled;
    case AppointmentStatus.scheduled:
    case AppointmentStatus.confirmed:
    case AppointmentStatus.rescheduled:
      if (isToday && _minutesOf(appointment.time) < nowMinutes) {
        return ScheduleStatus.completed;
      }
      return nextAlreadyAssigned ? ScheduleStatus.waiting : ScheduleStatus.next;
  }
}

List<ScheduleItem> buildUpcomingSchedule(
  List<Appointment> appointments,
  AppLanguage language,
) {
  final t = HomeStrings(language);
  final now = DateTime.now();
  final today = _dateOnly(now);
  final endDate = today.add(const Duration(days: 7));
  final upcoming =
      appointments.where((a) {
        final date = _dateOnly(a.date);
        return !date.isBefore(today) && !date.isAfter(endDate);
      }).toList()..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return _minutesOf(a.time).compareTo(_minutesOf(b.time));
      });

  final nowMinutes = _minutesOf(TimeOfDay.fromDateTime(now));
  var nextAssigned = false;
  final result = <ScheduleItem>[];
  for (final appointment in upcoming) {
    final isToday = _isSameDay(appointment.date, now);
    final status = _statusFor(appointment, isToday, nowMinutes, nextAssigned);
    if (status == ScheduleStatus.next) nextAssigned = true;
    result.add(
      ScheduleItem(
        dayLabel: _dayLabel(_dateOnly(appointment.date), today, t),
        time: _formatTime(appointment.time),
        patientName: appointment.patientName.trim().isEmpty
            ? t.noNamePatient
            : appointment.patientName,
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
      .where((a) => !a.date.isBefore(startOfWeek) && a.date.isBefore(endOfWeek))
      .length;

  final receivedThisMonth = financialEntries
      .where(
        (e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.status == PaymentStatus.paid,
      )
      .fold<double>(0, (sum, e) => sum + e.amount);

  return ClinicOverview(
    activePatients: patientCount,
    appointmentsThisWeek: appointmentsThisWeek,
    receivedThisMonth: receivedThisMonth,
  );
}

extension ScheduleStatusStyle on ScheduleStatus {
  Color foreground(AppColors colors) => switch (this) {
    ScheduleStatus.completed => colors.success,
    ScheduleStatus.next => colors.primary,
    ScheduleStatus.waiting => colors.primaryButton,
    ScheduleStatus.cancelled => colors.textSecondary,
  };
}
