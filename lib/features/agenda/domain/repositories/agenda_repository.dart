import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment_status.dart';

abstract class AgendaRepository {
  Future<Result<List<Appointment>>> getAll();

  Future<Result<void>> add(Appointment appointment);

  Future<Result<void>> update(Appointment appointment);

  Future<Result<void>> delete(String id);

  Future<Result<void>> updateStatus(String id, AppointmentStatus status);
}
