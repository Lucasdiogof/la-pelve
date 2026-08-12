import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fisioterapia_pelvica/core/error/failures.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/evolution_entry.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/patient_repository.dart';

class PatientRepositorySupabase implements PatientRepository {
  PatientRepositorySupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<List<Patient>>> getAll() async {
    try {
      final rows = await _client
          .from('patients')
          .select()
          .filter('deleted_at', 'is', null)
          .order('created_at');
      return Success(rows.map((row) => Patient.fromJson(row)).toList());
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[PatientRepositorySupabase.getAll] code=${e.code} msg=${e.message}\n$st',
      );
      return const Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[PatientRepositorySupabase.getAll] $e\n$st');
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> add(Patient patient) async {
    try {
      await _client.from('patients').insert(patient.toJson());
      return const Success(null);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[PatientRepositorySupabase.add] code=${e.code} msg=${e.message}\n$st',
      );
      return const Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[PatientRepositorySupabase.add] $e\n$st');
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> update(Patient patient) async {
    try {
      await _client
          .from('patients')
          .update(patient.toJson())
          .eq('id', patient.id);
      return const Success(null);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[PatientRepositorySupabase.update] code=${e.code} msg=${e.message}\n$st',
      );
      return const Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[PatientRepositorySupabase.update] $e\n$st');
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _client
          .from('patients')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      return const Success(null);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[PatientRepositorySupabase.delete] code=${e.code} msg=${e.message}\n$st',
      );
      return const Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[PatientRepositorySupabase.delete] $e\n$st');
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<List<EvolutionEntry>>> getEvolutions(String patientId) async {
    try {
      final rows = await _client
          .from('evolution_entries')
          .select()
          .eq('patient_id', patientId)
          .order('data');
      return Success(rows.map((row) => EvolutionEntry.fromJson(row)).toList());
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[PatientRepositorySupabase.getEvolutions] code=${e.code} msg=${e.message}\n$st',
      );
      return const Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[PatientRepositorySupabase.getEvolutions] $e\n$st');
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> addEvolution(EvolutionEntry entry) async {
    try {
      await _client.from('evolution_entries').insert(entry.toJson());
      return const Success(null);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[PatientRepositorySupabase.addEvolution] code=${e.code} msg=${e.message}\n$st',
      );
      return const Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[PatientRepositorySupabase.addEvolution] $e\n$st');
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> updateEvolution(EvolutionEntry entry) async {
    try {
      await _client
          .from('evolution_entries')
          .update(entry.toJson())
          .eq('id', entry.id);
      return const Success(null);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[PatientRepositorySupabase.updateEvolution] code=${e.code} msg=${e.message}\n$st',
      );
      return const Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[PatientRepositorySupabase.updateEvolution] $e\n$st');
      return const Error(UnexpectedFailure());
    }
  }
}
