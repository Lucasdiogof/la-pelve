import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:fisioterapia_pelvica/shared/utils/unset.dart';

class AgendaFormState extends Equatable {
  const AgendaFormState({
    this.date,
    this.time,
    this.patientId,
    this.saving = false,
    this.revision = 0,
  });

  final DateTime? date;
  final TimeOfDay? time;
  final String? patientId;
  final bool saving;
  final int revision;

  AgendaFormState copyWith({
    DateTime? date,
    TimeOfDay? time,
    Object? patientId = kUnset,
    bool? saving,
    int? revision,
  }) {
    return AgendaFormState(
      date: date ?? this.date,
      time: time ?? this.time,
      patientId: unsetOr(patientId, this.patientId),
      saving: saving ?? this.saving,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [date, time, patientId, saving, revision];
}
