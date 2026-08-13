enum AppointmentStatus {
  scheduled,
  confirmed,
  fulfilled,
  cancelled,
  noShow,
  rescheduled,
}

extension AppointmentStatusLabel on AppointmentStatus {
  String get label => switch (this) {
    AppointmentStatus.scheduled => 'Agendado',
    AppointmentStatus.confirmed => 'Confirmado',
    AppointmentStatus.fulfilled => 'Atendido',
    AppointmentStatus.cancelled => 'Cancelado',
    AppointmentStatus.noShow => 'Faltou',
    AppointmentStatus.rescheduled => 'Reagendado',
  };
}
