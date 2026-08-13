import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:fisioterapia_pelvica/features/agenda/domain/entities/appointment_status.dart';
import 'package:fisioterapia_pelvica/shared/utils/date_only.dart';
import 'package:fisioterapia_pelvica/shared/utils/enum_from_name.dart';
import 'package:fisioterapia_pelvica/shared/utils/unset.dart';

class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.date,
    required this.time,
    required this.patientName,
    this.patientId,
    this.status = AppointmentStatus.scheduled,
  });

  final String id;
  final DateTime date;
  final TimeOfDay time;
  final String patientName;
  final String? patientId;
  final AppointmentStatus status;

  Appointment copyWith({
    DateTime? date,
    TimeOfDay? time,
    String? patientName,
    Object? patientId = kUnset,
    AppointmentStatus? status,
  }) {
    return Appointment(
      id: id,
      date: date ?? this.date,
      time: time ?? this.time,
      patientName: patientName ?? this.patientName,
      patientId: unsetOr(patientId, this.patientId),
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': dateOnly(date),
    'time':
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00',
    'patient_name': patientName,
    'patient_id': patientId,
    'status': status.name,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    time: _parseTime(json['time'] as String),
    patientName: json['patient_name'] as String? ?? '',
    patientId: json['patient_id'] as String?,
    status:
        enumFromName(AppointmentStatus.values, json['status']) ??
        AppointmentStatus.scheduled,
  );

  static TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  List<Object?> get props => [id, date, time, patientName, patientId, status];
}
