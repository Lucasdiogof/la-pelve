import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/repositories/financial_repository.dart';

class FinancialCubit extends Cubit<List<FinancialEntry>> {
  FinancialCubit(this._repository) : super(const []) {
    reload();
  }

  final FinancialRepository _repository;

  Future<void> reload() async {
    final result = await _repository.getAll();
    if (result case Success(:final data)) emit(data);
  }

  Future<Result<void>> addEntry(FinancialEntry entry) async {
    final result = await _repository.add(entry);
    if (result case Success()) await reload();
    return result;
  }

  Future<Result<void>> updateEntry(FinancialEntry entry) async {
    final result = await _repository.update(entry);
    if (result case Success()) await reload();
    return result;
  }

  Future<Result<void>> deleteEntry(String id) async {
    final result = await _repository.delete(id);
    if (result case Success()) await reload();
    return result;
  }
}
