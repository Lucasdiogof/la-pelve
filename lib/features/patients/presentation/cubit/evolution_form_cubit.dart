import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/evolution_entry.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/evolution_form_state.dart';

class EvolutionFormCubit extends Cubit<EvolutionFormState> {
  EvolutionFormCubit({EvolutionEntry? existing})
    : super(EvolutionFormState(data: existing?.data));

  void setData(DateTime data) => emit(state.copyWith(data: data));

  void setSaving(bool saving) => emit(state.copyWith(saving: saving));

  void notifyFieldChanged() =>
      emit(state.copyWith(revision: state.revision + 1));
}
