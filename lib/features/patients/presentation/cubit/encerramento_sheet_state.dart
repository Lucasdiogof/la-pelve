import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';

class EncerramentoSheetState extends Equatable {
  const EncerramentoSheetState({this.data, this.motivo});

  final DateTime? data;
  final MotivoEncerramento? motivo;

  EncerramentoSheetState copyWith({
    DateTime? data,
    MotivoEncerramento? motivo,
  }) {
    return EncerramentoSheetState(
      data: data ?? this.data,
      motivo: motivo ?? this.motivo,
    );
  }

  @override
  List<Object?> get props => [data, motivo];
}
