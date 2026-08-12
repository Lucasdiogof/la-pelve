import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/patient_repository.dart';

class PatientsCubit extends Cubit<List<Patient>> {
  PatientsCubit(this._repository) : super(const []) {
    _load();
  }

  final PatientRepository _repository;

  Future<void> _load() async {
    final result = await _repository.getAll();
    if (result case Success(:final data)) emit(data);
  }

  Future<Result<void>> addPatient(Patient patient) async {
    final result = await _repository.add(patient);
    if (result case Success()) await _load();
    return result;
  }

  Future<Result<void>> updatePatient(Patient patient) async {
    final result = await _repository.update(patient);
    if (result case Success()) await _load();
    return result;
  }

  Future<Result<void>> deletePatient(String id) async {
    final result = await _repository.delete(id);
    if (result case Success()) await _load();
    return result;
  }
}
