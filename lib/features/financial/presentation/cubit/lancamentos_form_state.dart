import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/shared/utils/unset.dart';

class LancamentosFormState extends Equatable {
  const LancamentosFormState({
    this.patient,
    this.data,
    this.formaPagamento,
    this.status = StatusPagamento.pago,
    this.saving = false,
    this.revision = 0,
  });

  final Patient? patient;
  final DateTime? data;
  final FormaPagamento? formaPagamento;
  final StatusPagamento status;
  final bool saving;
  final int revision;

  LancamentosFormState copyWith({
    Object? patient = kUnset,
    DateTime? data,
    Object? formaPagamento = kUnset,
    StatusPagamento? status,
    bool? saving,
    int? revision,
  }) {
    return LancamentosFormState(
      patient: unsetOr(patient, this.patient),
      data: data ?? this.data,
      formaPagamento: unsetOr(formaPagamento, this.formaPagamento),
      status: status ?? this.status,
      saving: saving ?? this.saving,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [
    patient,
    data,
    formaPagamento,
    status,
    saving,
    revision,
  ];
}
