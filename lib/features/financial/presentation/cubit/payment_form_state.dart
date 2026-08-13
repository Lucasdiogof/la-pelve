import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/shared/utils/unset.dart';

class PaymentFormState extends Equatable {
  const PaymentFormState({
    this.patient,
    this.date,
    this.paymentMethod,
    this.status = PaymentStatus.paid,
    this.saving = false,
    this.revision = 0,
  });

  final Patient? patient;
  final DateTime? date;
  final PaymentMethod? paymentMethod;
  final PaymentStatus status;
  final bool saving;
  final int revision;

  PaymentFormState copyWith({
    Object? patient = kUnset,
    DateTime? date,
    Object? paymentMethod = kUnset,
    PaymentStatus? status,
    bool? saving,
    int? revision,
  }) {
    return PaymentFormState(
      patient: unsetOr(patient, this.patient),
      date: date ?? this.date,
      paymentMethod: unsetOr(paymentMethod, this.paymentMethod),
      status: status ?? this.status,
      saving: saving ?? this.saving,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [
    patient,
    date,
    paymentMethod,
    status,
    saving,
    revision,
  ];
}
