import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';

class DischargeSheetState extends Equatable {
  const DischargeSheetState({this.date, this.reason});

  final DateTime? date;
  final DischargeReason? reason;

  DischargeSheetState copyWith({DateTime? date, DischargeReason? reason}) {
    return DischargeSheetState(
      date: date ?? this.date,
      reason: reason ?? this.reason,
    );
  }

  @override
  List<Object?> get props => [date, reason];
}
