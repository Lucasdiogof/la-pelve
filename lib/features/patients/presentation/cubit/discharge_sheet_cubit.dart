import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/discharge_sheet_state.dart';

class DischargeSheetCubit extends Cubit<DischargeSheetState> {
  DischargeSheetCubit() : super(DischargeSheetState(date: DateTime.now()));

  void setData(DateTime date) => emit(state.copyWith(date: date));

  void setMotivo(DischargeReason? reason) =>
      emit(DischargeSheetState(date: state.date, reason: reason));
}
