import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fisioterapia_pelvica/core/error/failures.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/repositories/financial_repository.dart';

class FinancialRepositorySupabase implements FinancialRepository {
  FinancialRepositorySupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<List<FinancialEntry>>> getAll() async {
    try {
      final rows = await _client
          .from('financial_entries')
          .select()
          .order('date');
      return Success(rows.map((row) => FinancialEntry.fromJson(row)).toList());
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[FinancialRepositorySupabase.getAll] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[FinancialRepositorySupabase.getAll] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> add(FinancialEntry entry) async {
    try {
      await _client.from('financial_entries').insert(entry.toJson());
      return const Success(null);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[FinancialRepositorySupabase.add] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[FinancialRepositorySupabase.add] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> update(FinancialEntry entry) async {
    try {
      await _client
          .from('financial_entries')
          .update(entry.toJson())
          .eq('id', entry.id);
      return const Success(null);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[FinancialRepositorySupabase.update] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[FinancialRepositorySupabase.update] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _client.from('financial_entries').delete().eq('id', id);
      return const Success(null);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[FinancialRepositorySupabase.delete] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[FinancialRepositorySupabase.delete] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }
}
