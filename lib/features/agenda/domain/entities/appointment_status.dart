enum AppointmentStatus {
  agendado,
  confirmado,
  atendido,
  cancelado,
  faltou,
  reagendado,
}

extension AppointmentStatusLabel on AppointmentStatus {
  String get label => switch (this) {
    AppointmentStatus.agendado => 'Agendado',
    AppointmentStatus.confirmado => 'Confirmado',
    AppointmentStatus.atendido => 'Atendido',
    AppointmentStatus.cancelado => 'Cancelado',
    AppointmentStatus.faltou => 'Faltou',
    AppointmentStatus.reagendado => 'Reagendado',
  };
}
