import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/state/resource_cubit.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_repository.dart';

class PatientsCubit extends ResourceCubit<List<Patient>> {
  PatientsCubit(this._repository) : super(debugName: 'patients');

  final PatientRepository _repository;

  @override
  Future<Result<List<Patient>>> fetch() => _repository.getAll();

  Future<Result<void>> addPatient(Patient patient) async {
    final result = await _repository.add(patient);
    if (result case Success()) await refresh();
    return result;
  }

  Future<Result<void>> updatePatient(Patient patient) async {
    final result = await _repository.update(patient);
    if (result case Success()) await refresh();
    return result;
  }

  Future<Result<void>> deletePatient(String id) async {
    final result = await _repository.delete(id);
    if (result case Success()) await refresh();
    return result;
  }
}
