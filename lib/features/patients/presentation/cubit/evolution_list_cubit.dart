import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/evolution_entry.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/patient_repository.dart';

class EvolutionListCubit extends Cubit<Result<List<EvolutionEntry>>?> {
  EvolutionListCubit(this._repository, this._patientId) : super(null) {
    reload();
  }

  final PatientRepository _repository;
  final String _patientId;

  Future<void> reload() async {
    emit(await _repository.getEvolutions(_patientId));
  }

  Future<Result<void>> delete(String id) async {
    final result = await _repository.deleteEvolution(id);
    if (result is Success) await reload();
    return result;
  }
}
