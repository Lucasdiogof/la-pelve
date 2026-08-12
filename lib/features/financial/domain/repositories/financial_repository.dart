import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_entry.dart';

abstract class FinancialRepository {
  Future<Result<List<FinancialEntry>>> getAll();

  Future<Result<void>> add(FinancialEntry entry);

  Future<Result<void>> delete(String id);
}
