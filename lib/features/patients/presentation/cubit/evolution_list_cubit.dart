import 'dart:async';

import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/state/resource_cubit.dart';
import 'package:la_pelve/features/patients/domain/entities/evolution_entry.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_repository.dart';

/// Evoluções de UM paciente: dado sob demanda, carregado ao abrir a tela.
class EvolutionListCubit extends ResourceCubit<List<EvolutionEntry>> {
  /// [localChanges]: avisos de mudança do espelho local (pull, conflito
  /// resolvido); a lista se atualiza sozinha, sem rede.
  EvolutionListCubit(
    this._repository,
    this._patientId, {
    Stream<Set<String>>? localChanges,
  }) : super(debugName: 'evolutions') {
    ensureLoaded();
    _changes = localChanges?.listen((kinds) {
      if (kinds.contains('evolution_entries')) unawaited(refresh());
    });
  }

  StreamSubscription<Set<String>>? _changes;

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }

  final PatientRepository _repository;
  final String _patientId;

  @override
  Future<Result<List<EvolutionEntry>>> fetch() =>
      _repository.getEvolutions(_patientId);

  Future<Result<void>> delete(String id) async {
    final result = await _repository.deleteEvolution(id);
    if (result is Success) await refresh();
    return result;
  }
}
