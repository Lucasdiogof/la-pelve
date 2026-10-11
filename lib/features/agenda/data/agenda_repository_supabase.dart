import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment_status.dart';
import 'package:la_pelve/features/agenda/domain/repositories/agenda_repository.dart';

class AgendaRepositorySupabase implements AgendaRepository {
  AgendaRepositorySupabase(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<Appointment>> watchAllForUser(String userId) => _client
      .from('appointments')
      .stream(primaryKey: ['id'])
      .eq('fisioterapeuta_id', userId)
      .map((rows) {
        final appointments = rows.map(Appointment.fromJson).toList();
        appointments.sort((a, b) {
          final dateOrder = a.date.compareTo(b.date);
          if (dateOrder != 0) return dateOrder;
          final aMinutes = a.time.hour * 60 + a.time.minute;
          final bMinutes = b.time.hour * 60 + b.time.minute;
          return aMinutes.compareTo(bMinutes);
        });
        return appointments;
      });

  @override
  Future<Result<List<Appointment>>> getAll() async {
    try {
      final rows = await _client
          .from('appointments')
          .select()
          .order('date')
          .order('time');
      return Success(rows.map((row) => Appointment.fromJson(row)).toList());
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[AgendaRepositorySupabase.getAll] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[AgendaRepositorySupabase.getAll] $e\n$st');
      return Error(UnexpectedFailure());
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
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[AgendaRepositorySupabase.add] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> update(Appointment appointment) async {
    try {
      await _client
          .from('appointments')
          .update(appointment.toJson()..remove('status'))
          .eq('id', appointment.id);
      return const Success(null);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[AgendaRepositorySupabase.update] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[AgendaRepositorySupabase.update] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _client.from('appointments').delete().eq('id', id);
      return const Success(null);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[AgendaRepositorySupabase.delete] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[AgendaRepositorySupabase.delete] $e\n$st');
      return Error(UnexpectedFailure());
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
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[AgendaRepositorySupabase.updateStatus] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }
}
