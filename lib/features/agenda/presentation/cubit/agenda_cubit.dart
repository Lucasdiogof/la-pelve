import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/state/resource_cubit.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment_status.dart';
import 'package:la_pelve/features/agenda/domain/repositories/agenda_repository.dart';

class AgendaCubit extends ResourceCubit<List<Appointment>> {
  AgendaCubit(this._repository) : super(debugName: 'agenda');

  final AgendaRepository _repository;

  StreamSubscription<List<Appointment>>? _realtimeSubscription;
  int _realtimeGeneration = 0;

  /// Mantém a agenda (e a Home, que utiliza o mesmo cubit) sincronizadas
  /// com alterações vindas do webhook de confirmação do WhatsApp.
  /// A inscrição acompanha a sessão para nunca reaproveitar dados de outra conta.
  void startRealtime(String userId) {
    stopRealtime();
    final generation = _realtimeGeneration;
    _realtimeSubscription = _repository.watchAllForUser(userId).listen(
      (appointments) {
        if (isClosed || generation != _realtimeGeneration) return;
        applyExternalData(appointments);
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[AgendaCubit] realtime error: ${error.runtimeType}');
        if (!isClosed && generation == _realtimeGeneration) {
          unawaited(refresh());
        }
      },
    );
  }

  void stopRealtime() {
    _realtimeGeneration++;
    final previous = _realtimeSubscription;
    _realtimeSubscription = null;
    if (previous != null) unawaited(previous.cancel());
  }

  @override
  void reset() {
    stopRealtime();
    super.reset();
  }

  @override
  Future<void> close() async {
    stopRealtime();
    await super.close();
  }

  @override
  Future<Result<List<Appointment>>> fetch() => _repository.getAll();

  Future<Result<void>> addAppointment(Appointment appointment) async {
    final result = await _repository.add(appointment);
    if (result case Success()) await refresh();
    return result;
  }

  Future<Result<void>> updateAppointment(Appointment appointment) async {
    final result = await _repository.update(appointment);
    if (result case Success()) await refresh();
    return result;
  }

  Future<Result<void>> deleteAppointment(String id) async {
    final result = await _repository.delete(id);
    if (result case Success()) await refresh();
    return result;
  }

  Future<Result<void>> updateStatus(String id, AppointmentStatus status) async {
    final result = await _repository.updateStatus(id, status);
    if (result case Success()) await refresh();
    return result;
  }
}
