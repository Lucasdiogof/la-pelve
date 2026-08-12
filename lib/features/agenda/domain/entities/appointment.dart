import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment_status.dart';
import 'package:fisioterapia_pelvica/shared/utils/date_only.dart';
import 'package:fisioterapia_pelvica/shared/utils/enum_from_name.dart';
import 'package:fisioterapia_pelvica/shared/utils/unset.dart';

class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.data,
    required this.hora,
    required this.nomePaciente,
    this.patientId,
    this.status = AppointmentStatus.agendado,
  });

  final String id;
  final DateTime data;
  final TimeOfDay hora;
  final String nomePaciente;
  final String? patientId;
  final AppointmentStatus status;

  Appointment copyWith({
    DateTime? data,
    TimeOfDay? hora,
    String? nomePaciente,
    Object? patientId = kUnset,
    AppointmentStatus? status,
  }) {
    return Appointment(
      id: id,
      data: data ?? this.data,
      hora: hora ?? this.hora,
      nomePaciente: nomePaciente ?? this.nomePaciente,
      patientId: unsetOr(patientId, this.patientId),
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': dateOnly(data),
    'hora':
        '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}:00',
    'nome_paciente': nomePaciente,
    'patient_id': patientId,
    'status': status.name,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] as String,
    data: DateTime.parse(json['data'] as String),
    hora: _parseTime(json['hora'] as String),
    nomePaciente: json['nome_paciente'] as String? ?? '',
    patientId: json['patient_id'] as String?,
    status:
        enumFromName(AppointmentStatus.values, json['status']) ??
        AppointmentStatus.agendado,
  );

  static TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  List<Object?> get props => [id, data, hora, nomePaciente, patientId, status];
}
