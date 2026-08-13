import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/encerramento_sheet_state.dart';

class EncerramentoSheetCubit extends Cubit<EncerramentoSheetState> {
  EncerramentoSheetCubit()
    : super(EncerramentoSheetState(data: DateTime.now()));

  void setData(DateTime data) => emit(state.copyWith(data: data));

  void setMotivo(MotivoEncerramento? motivo) =>
      emit(EncerramentoSheetState(data: state.data, motivo: motivo));
}
