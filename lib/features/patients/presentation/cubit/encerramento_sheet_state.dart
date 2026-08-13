import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';

class EncerramentoSheetState extends Equatable {
  const EncerramentoSheetState({this.date, this.reason});

  final DateTime? date;
  final DischargeReason? reason;

  EncerramentoSheetState copyWith({DateTime? date, DischargeReason? reason}) {
    return EncerramentoSheetState(
      date: date ?? this.date,
      reason: reason ?? this.reason,
    );
  }

  @override
  List<Object?> get props => [date, reason];
}
