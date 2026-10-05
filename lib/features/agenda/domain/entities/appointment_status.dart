import 'package:la_pelve/core/l10n/app_language.dart';

enum AppointmentStatus {
  scheduled,
  confirmed,
  fulfilled,
  cancelled,
  noShow,
  rescheduled,
}

extension AppointmentStatusLabel on AppointmentStatus {
  String label(AppLanguage language) => switch ((this, language)) {
    (AppointmentStatus.scheduled, AppLanguage.portuguese) => 'Agendado',
    (AppointmentStatus.scheduled, AppLanguage.english) => 'Scheduled',
    (AppointmentStatus.scheduled, AppLanguage.spanish) => 'Programado',
    (AppointmentStatus.confirmed, AppLanguage.portuguese) => 'Confirmado',
    (AppointmentStatus.confirmed, AppLanguage.english) => 'Confirmed',
    (AppointmentStatus.confirmed, AppLanguage.spanish) => 'Confirmado',
    (AppointmentStatus.fulfilled, AppLanguage.portuguese) => 'Atendido',
    (AppointmentStatus.fulfilled, AppLanguage.english) => 'Completed',
    (AppointmentStatus.fulfilled, AppLanguage.spanish) => 'Atendido',
    (AppointmentStatus.cancelled, AppLanguage.portuguese) => 'Cancelado',
    (AppointmentStatus.cancelled, AppLanguage.english) => 'Cancelled',
    (AppointmentStatus.cancelled, AppLanguage.spanish) => 'Cancelado',
    (AppointmentStatus.noShow, AppLanguage.portuguese) => 'Faltou',
    (AppointmentStatus.noShow, AppLanguage.english) => 'No-show',
    (AppointmentStatus.noShow, AppLanguage.spanish) => 'No asistió',
    (AppointmentStatus.rescheduled, AppLanguage.portuguese) => 'Reagendado',
    (AppointmentStatus.rescheduled, AppLanguage.english) => 'Rescheduled',
    (AppointmentStatus.rescheduled, AppLanguage.spanish) => 'Reprogramado',
  };
}
