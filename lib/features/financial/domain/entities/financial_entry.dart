import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/features/financial/domain/entities/financial_enums.dart';
import 'package:fisioterapia_pelvica/shared/utils/date_only.dart';
import 'package:fisioterapia_pelvica/shared/utils/enum_from_name.dart';

class FinancialEntry extends Equatable {
  const FinancialEntry({
    required this.id,
    required this.patientName,
    required this.date,
    required this.amount,
    this.patientId,
    this.notes = '',
    this.paymentMethod,
    this.otherPaymentMethodDescription,
    this.status = PaymentStatus.paid,
    this.otherStatusDescription,
  });

  final String id;

  final String? patientId;

  final String patientName;
  final DateTime date;
  final double amount;
  final String notes;
  final PaymentMethod? paymentMethod;
  final String? otherPaymentMethodDescription;
  final PaymentStatus status;
  final String? otherStatusDescription;

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'patient_name': patientName,
    'date': dateOnly(date),
    'amount': amount,
    'notes': notes,
    'payment_method': paymentMethod?.name,
    'other_payment_method_description': otherPaymentMethodDescription,
    'status': status.name,
    'other_status_description': otherStatusDescription,
  };

  factory FinancialEntry.fromJson(Map<String, dynamic> json) => FinancialEntry(
    id: json['id'] as String,
    patientId: json['patient_id'] as String?,
    patientName: json['patient_name'] as String? ?? '',
    date: DateTime.parse(json['date'] as String),
    amount: (json['amount'] as num).toDouble(),
    notes: json['notes'] as String? ?? '',
    paymentMethod: enumFromName(PaymentMethod.values, json['payment_method']),
    otherPaymentMethodDescription:
        json['other_payment_method_description'] as String?,
    status:
        enumFromName(PaymentStatus.values, json['status']) ??
        PaymentStatus.paid,
    otherStatusDescription: json['other_status_description'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    patientId,
    patientName,
    date,
    amount,
    notes,
    paymentMethod,
    otherPaymentMethodDescription,
    status,
    otherStatusDescription,
  ];
}
