import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_enums.dart';
import 'package:fisioterapia_pelvica/features/financial/presentation/cubit/payment_form_state.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';

class PaymentFormCubit extends Cubit<PaymentFormState> {
  PaymentFormCubit() : super(const PaymentFormState());

  void selectPatient(Patient patient) =>
      emit(state.copyWith(patient: patient, revision: state.revision + 1));

  void onNomeChanged() =>
      emit(state.copyWith(patient: null, revision: state.revision + 1));

  void setData(DateTime date) => emit(state.copyWith(date: date));

  void notifyFieldChanged() =>
      emit(state.copyWith(revision: state.revision + 1));

  void setFormaPagamento(PaymentMethod? paymentMethod) =>
      emit(state.copyWith(paymentMethod: paymentMethod));

  void setStatus(PaymentStatus status) => emit(state.copyWith(status: status));

  void setSaving(bool saving) => emit(state.copyWith(saving: saving));

  void reset() => emit(const PaymentFormState());
}
