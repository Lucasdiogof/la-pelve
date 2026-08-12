import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment_status.dart';

abstract class AgendaRepository {
  Future<Result<List<Appointment>>> getAll();

  Future<Result<void>> add(Appointment appointment);

  Future<Result<void>> updateStatus(String id, AppointmentStatus status);
}
