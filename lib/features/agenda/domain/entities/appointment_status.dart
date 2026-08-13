import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';

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
    (AppointmentStatus.confirmed, AppLanguage.portuguese) => 'Confirmado',
    (AppointmentStatus.confirmed, AppLanguage.english) => 'Confirmed',
    (AppointmentStatus.fulfilled, AppLanguage.portuguese) => 'Atendido',
    (AppointmentStatus.fulfilled, AppLanguage.english) => 'Completed',
    (AppointmentStatus.cancelled, AppLanguage.portuguese) => 'Cancelado',
    (AppointmentStatus.cancelled, AppLanguage.english) => 'Cancelled',
    (AppointmentStatus.noShow, AppLanguage.portuguese) => 'Faltou',
    (AppointmentStatus.noShow, AppLanguage.english) => 'No-show',
    (AppointmentStatus.rescheduled, AppLanguage.portuguese) => 'Reagendado',
    (AppointmentStatus.rescheduled, AppLanguage.english) => 'Rescheduled',
  };
}
