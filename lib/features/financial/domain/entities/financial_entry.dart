import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_enums.dart';
import 'package:fisioterapia_pelvica/shared/utils/date_only.dart';
import 'package:fisioterapia_pelvica/shared/utils/enum_from_name.dart';

class FinancialEntry extends Equatable {
  const FinancialEntry({
    required this.id,
    required this.patientName,
    required this.data,
    required this.valor,
    this.patientId,
    this.observacoes = '',
    this.formaPagamento,
    this.formaPagamentoOutraDescricao,
    this.status = StatusPagamento.pago,
    this.statusOutraDescricao,
  });

  final String id;

  final String? patientId;

  final String patientName;
  final DateTime data;
  final double valor;
  final String observacoes;
  final FormaPagamento? formaPagamento;
  final String? formaPagamentoOutraDescricao;
  final StatusPagamento status;
  final String? statusOutraDescricao;

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'patient_name': patientName,
    'data': dateOnly(data),
    'valor': valor,
    'observacoes': observacoes,
    'forma_pagamento': formaPagamento?.name,
    'forma_pagamento_outra_descricao': formaPagamentoOutraDescricao,
    'status': status.name,
    'status_outra_descricao': statusOutraDescricao,
  };

  factory FinancialEntry.fromJson(Map<String, dynamic> json) => FinancialEntry(
    id: json['id'] as String,
    patientId: json['patient_id'] as String?,
    patientName: json['patient_name'] as String? ?? '',
    data: DateTime.parse(json['data'] as String),
    valor: (json['valor'] as num).toDouble(),
    observacoes: json['observacoes'] as String? ?? '',
    formaPagamento: enumFromName(
      FormaPagamento.values,
      json['forma_pagamento'],
    ),
    formaPagamentoOutraDescricao:
        json['forma_pagamento_outra_descricao'] as String?,
    status:
        enumFromName(StatusPagamento.values, json['status']) ??
        StatusPagamento.pago,
    statusOutraDescricao: json['status_outra_descricao'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    patientId,
    patientName,
    data,
    valor,
    observacoes,
    formaPagamento,
    formaPagamentoOutraDescricao,
    status,
    statusOutraDescricao,
  ];
}
