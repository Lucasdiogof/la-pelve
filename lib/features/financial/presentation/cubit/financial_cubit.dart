import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/state/resource_cubit.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/financial/domain/repositories/financial_repository.dart';

class FinancialCubit extends ResourceCubit<List<FinancialEntry>> {
  FinancialCubit(this._repository) : super(debugName: 'financial');

  final FinancialRepository _repository;

  @override
  Future<Result<List<FinancialEntry>>> fetch() => _repository.getAll();

  Future<Result<void>> addEntry(FinancialEntry entry) async {
    final result = await _repository.add(entry);
    if (result case Success()) await refresh();
    return result;
  }

  Future<Result<void>> updateEntry(FinancialEntry entry) async {
    final result = await _repository.update(entry);
    if (result case Success()) await refresh();
    return result;
  }

  Future<Result<void>> deleteEntry(String id) async {
    final result = await _repository.delete(id);
    if (result case Success()) await refresh();
    return result;
  }
}
