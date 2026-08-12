import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fisioterapia_pelvica/core/error/failures.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment_status.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/repositories/agenda_repository.dart';

class AgendaRepositorySupabase implements AgendaRepository {
  AgendaRepositorySupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<List<Appointment>>> getAll() async {
    try {
      final rows = await _client
          .from('appointments')
          .select()
          .order('data')
          .order('hora');
      return Success(rows.map((row) => Appointment.fromJson(row)).toList());
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[AgendaRepositorySupabase.getAll] code=${e.code} msg=${e.message}\n$st',
      );
      return const Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[AgendaRepositorySupabase.getAll] $e\n$st');
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> add(Appointment appointment) async {
    try {
      await _client.from('appointments').insert(appointment.toJson());
      return const Success(null);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[AgendaRepositorySupabase.add] code=${e.code} msg=${e.message}\n$st',
      );
      return const Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[AgendaRepositorySupabase.add] $e\n$st');
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> update(Appointment appointment) async {
    try {
      await _client
          .from('appointments')
          .update(appointment.toJson())
          .eq('id', appointment.id);
      return const Success(null);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[AgendaRepositorySupabase.update] code=${e.code} msg=${e.message}\n$st',
      );
      return const Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[AgendaRepositorySupabase.update] $e\n$st');
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> updateStatus(String id, AppointmentStatus status) async {
    try {
      await _client
          .from('appointments')
          .update({'status': status.name})
          .eq('id', id);
      return const Success(null);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[AgendaRepositorySupabase.updateStatus] code=${e.code} msg=${e.message}\n$st',
      );
      return const Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[AgendaRepositorySupabase.updateStatus] $e\n$st');
      return const Error(UnexpectedFailure());
    }
  }
}
