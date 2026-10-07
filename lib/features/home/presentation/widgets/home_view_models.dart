import 'package:flutter/material.dart';
import 'package:la_pelve/core/l10n/app_language.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment_status.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_enums.dart';
import 'package:la_pelve/features/home/l10n/home_strings.dart';
import 'package:la_pelve/shared/widgets/app_status_badge.dart';

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
    required this.day,
    required this.dayLabel,
    required this.time,
    required this.patientName,
    required this.status,
  });

  /// Dia do atendimento (sem hora): é a chave do agrupamento por dia.
  final DateTime day;
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
  // Em UTC para a contagem de dias não sofrer com horário de verão.
  final diff = DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  if (diff == 0) return t.today;
  if (diff == 1) return t.tomorrow;
  final weekday = t.weekdayShortName(day.weekday);
  // A partir de uma semana o dia da semana se repete: a data desfaz a
  // ambiguidade ("Qua, 14/10").
  if (diff >= 7) {
    return '$weekday, ${day.day.toString().padLeft(2, '0')}/'
        '${day.month.toString().padLeft(2, '0')}';
  }
  return weekday;
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

/// Mínimo de atendimentos que a Home procura mostrar em "Próximos
/// atendimentos".
const int kUpcomingScheduleMinItems = 5;

/// Próximos atendimentos da Home. A unidade é o DIA: a partir de hoje, em
/// ordem cronológica, entra o dia INTEIRO (todos os atendimentos dele) até o
/// total chegar a [kUpcomingScheduleMinItems] ou mais; nesse ponto para. Dias
/// sem atendimento são pulados e um dia nunca é cortado ao meio, então o
/// total pode passar de 5 (ex.: 4 hoje + 3 amanhã = 7). Sem limite de janela:
/// se os próximos atendimentos estão longe, eles aparecem mesmo assim.
List<ScheduleItem> buildUpcomingSchedule(
  List<Appointment> appointments,
  AppLanguage language,
) {
  final t = HomeStrings(language);
  final now = DateTime.now();
  final today = _dateOnly(now);
  final upcoming =
      appointments.where((a) => !_dateOnly(a.date).isBefore(today)).toList()
        ..sort((a, b) {
          final byDate = _dateOnly(a.date).compareTo(_dateOnly(b.date));
          if (byDate != 0) return byDate;
          return _minutesOf(a.time).compareTo(_minutesOf(b.time));
        });

  // Dias inteiros, em ordem, até atingir o mínimo.
  final selected = <Appointment>[];
  for (var i = 0; i < upcoming.length;) {
    if (selected.length >= kUpcomingScheduleMinItems) break;
    final day = _dateOnly(upcoming[i].date);
    while (i < upcoming.length && _dateOnly(upcoming[i].date) == day) {
      selected.add(upcoming[i++]);
    }
  }

  final nowMinutes = _minutesOf(TimeOfDay.fromDateTime(now));
  var nextAssigned = false;
  final result = <ScheduleItem>[];
  for (final appointment in selected) {
    final isToday = _isSameDay(appointment.date, now);
    final status = _statusFor(appointment, isToday, nowMinutes, nextAssigned);
    if (status == ScheduleStatus.next) nextAssigned = true;
    final day = _dateOnly(appointment.date);
    result.add(
      ScheduleItem(
        day: day,
        dayLabel: _dayLabel(day, today, t),
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

/// Tom de cada [ScheduleStatus], no mesmo vocabulário do mapa de
/// AppointmentStatus (`appointment_status_style.dart`): concluído = success
/// (como fulfilled), cancelado = muted (como cancelled).
extension ScheduleStatusStyle on ScheduleStatus {
  AppStatusTone get tone => switch (this) {
    ScheduleStatus.completed => AppStatusTone.success,
    ScheduleStatus.next => AppStatusTone.primary,
    ScheduleStatus.waiting => AppStatusTone.neutral,
    ScheduleStatus.cancelled => AppStatusTone.muted,
  };
}
