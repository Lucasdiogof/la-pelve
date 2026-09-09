import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment_status.dart';
import 'package:la_pelve/features/agenda/domain/repositories/agenda_repository.dart';

class AgendaCubit extends Cubit<List<Appointment>> {
  AgendaCubit(this._repository) : super(const []) {
    reload();
  }

  final AgendaRepository _repository;

  Future<void> reload() async {
    final result = await _repository.getAll();
    if (result case Success(:final data)) emit(data);
  }

  Future<Result<void>> addAppointment(Appointment appointment) async {
    final result = await _repository.add(appointment);
    if (result case Success()) await reload();
    return result;
  }

  Future<Result<void>> updateAppointment(Appointment appointment) async {
    final result = await _repository.update(appointment);
    if (result case Success()) await reload();
    return result;
  }

  Future<Result<void>> deleteAppointment(String id) async {
    final result = await _repository.delete(id);
    if (result case Success()) await reload();
    return result;
  }

  Future<Result<void>> updateStatus(String id, AppointmentStatus status) async {
    final result = await _repository.updateStatus(id, status);
    if (result case Success()) await reload();
    return result;
  }
}
