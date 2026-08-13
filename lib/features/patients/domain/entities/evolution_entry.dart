import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/shared/utils/date_only.dart';

class EvolutionEntry extends Equatable {
  const EvolutionEntry({
    required this.id,
    required this.patientId,
    required this.date,
    required this.description,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String patientId;
  final DateTime date;
  final String description;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EvolutionEntry copyWith({
    DateTime? date,
    String? description,
    DateTime? updatedAt,
  }) {
    return EvolutionEntry(
      id: id,
      patientId: patientId,
      date: date ?? this.date,
      description: description ?? this.description,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'date': dateOnly(date),
    'description': description,
    'updated_at': updatedAt?.toIso8601String(),
  };

  factory EvolutionEntry.fromJson(Map<String, dynamic> json) => EvolutionEntry(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    date: DateTime.parse(json['date'] as String),
    description: json['description'] as String,
    createdBy: json['physiotherapist_id'] as String?,
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
    date,
    description,
    createdBy,
    createdAt,
    updatedAt,
  ];
}
