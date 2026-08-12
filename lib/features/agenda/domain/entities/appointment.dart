import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment_status.dart';
import 'package:fisioterapia_pelvica/shared/utils/date_only.dart';
import 'package:fisioterapia_pelvica/shared/utils/enum_from_name.dart';

class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.data,
    required this.hora,
    required this.nomePaciente,
    this.status = AppointmentStatus.agendado,
  });

  final String id;
  final DateTime data;
  final TimeOfDay hora;
  final String nomePaciente;
  final AppointmentStatus status;

  Appointment copyWith({AppointmentStatus? status}) {
    return Appointment(
      id: id,
      data: data,
      hora: hora,
      nomePaciente: nomePaciente,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': dateOnly(data),
    'hora':
        '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}:00',
    'nome_paciente': nomePaciente,
    'status': status.name,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] as String,
    data: DateTime.parse(json['data'] as String),
    hora: _parseTime(json['hora'] as String),
    nomePaciente: json['nome_paciente'] as String? ?? '',
    status:
        enumFromName(AppointmentStatus.values, json['status']) ??
        AppointmentStatus.agendado,
  );

  static TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  List<Object?> get props => [id, data, hora, nomePaciente, status];
}
