import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/evolution_entry.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';

abstract class PatientRepository {
  Future<Result<List<Patient>>> getAll();

  Future<Result<void>> add(Patient patient);

  Future<Result<void>> update(Patient patient);

  Future<Result<void>> delete(String id);

  Future<Result<List<EvolutionEntry>>> getEvolutions(String patientId);

  Future<Result<void>> addEvolution(EvolutionEntry entry);

  Future<Result<void>> updateEvolution(EvolutionEntry entry);

  Future<Result<void>> deleteEvolution(String id);
}
