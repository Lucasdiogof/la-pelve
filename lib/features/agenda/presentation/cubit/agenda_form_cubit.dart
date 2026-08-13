import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment.dart';
import 'package:fisioterapia_pelvica/features/agenda/presentation/cubit/agenda_form_state.dart';

class AgendaFormCubit extends Cubit<AgendaFormState> {
  AgendaFormCubit({Appointment? existing})
    : super(
        AgendaFormState(
          date: existing?.date,
          time: existing?.time,
          patientId: existing?.patientId,
        ),
      );

  void setData(DateTime date) => emit(state.copyWith(date: date));

  void setHora(TimeOfDay time) => emit(state.copyWith(time: time));

  void selectPatient(String patientId) =>
      emit(state.copyWith(patientId: patientId, revision: state.revision + 1));

  void onNomeChanged() =>
      emit(state.copyWith(patientId: null, revision: state.revision + 1));

  void setSaving(bool saving) => emit(state.copyWith(saving: saving));
}
