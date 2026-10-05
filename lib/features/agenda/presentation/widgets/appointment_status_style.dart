import 'package:la_pelve/features/agenda/domain/entities/appointment_status.dart';
import 'package:la_pelve/shared/widgets/app_status_badge.dart';

/// Mapa único AppointmentStatus -> tom visual. Toda tela que mostra o
/// status de um atendimento usa este mapa (via [AppStatusBadge]).
extension AppointmentStatusStyle on AppointmentStatus {
  AppStatusTone get tone => switch (this) {
    AppointmentStatus.scheduled => AppStatusTone.neutral,
    AppointmentStatus.confirmed => AppStatusTone.primary,
    AppointmentStatus.fulfilled => AppStatusTone.success,
    AppointmentStatus.cancelled => AppStatusTone.muted,
    AppointmentStatus.noShow => AppStatusTone.danger,
    AppointmentStatus.rescheduled => AppStatusTone.warning,
  };
}
