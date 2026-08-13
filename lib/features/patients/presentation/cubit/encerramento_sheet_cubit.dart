import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/encerramento_sheet_state.dart';

class EncerramentoSheetCubit extends Cubit<EncerramentoSheetState> {
  EncerramentoSheetCubit()
    : super(EncerramentoSheetState(date: DateTime.now()));

  void setData(DateTime date) => emit(state.copyWith(date: date));

  void setMotivo(DischargeReason? reason) =>
      emit(EncerramentoSheetState(date: state.date, reason: reason));
}
