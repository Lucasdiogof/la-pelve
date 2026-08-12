import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/shared/utils/date_only.dart';

class EvolutionEntry extends Equatable {
  const EvolutionEntry({
    required this.id,
    required this.patientId,
    required this.data,
    required this.descricao,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String patientId;
  final DateTime data;
  final String descricao;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EvolutionEntry copyWith({
    DateTime? data,
    String? descricao,
    DateTime? updatedAt,
  }) {
    return EvolutionEntry(
      id: id,
      patientId: patientId,
      data: data ?? this.data,
      descricao: descricao ?? this.descricao,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'data': dateOnly(data),
    'descricao': descricao,
    'updated_at': updatedAt?.toIso8601String(),
  };

  factory EvolutionEntry.fromJson(Map<String, dynamic> json) => EvolutionEntry(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    data: DateTime.parse(json['data'] as String),
    descricao: json['descricao'] as String,
    createdBy: json['fisioterapeuta_id'] as String?,
    createdAt: json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
    updatedAt: json['updated_at'] == null
        ? null
        : DateTime.parse(json['updated_at'] as String),
  );

  @override
  List<Object?> get props => [
    id,
    patientId,
    data,
    descricao,
    createdBy,
    createdAt,
    updatedAt,
  ];
}
