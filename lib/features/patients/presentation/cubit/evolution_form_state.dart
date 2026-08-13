import 'package:equatable/equatable.dart';

class EvolutionFormState extends Equatable {
  const EvolutionFormState({this.date, this.saving = false, this.revision = 0});

  final DateTime? date;
  final bool saving;
  final int revision;

  EvolutionFormState copyWith({DateTime? date, bool? saving, int? revision}) {
    return EvolutionFormState(
      date: date ?? this.date,
      saving: saving ?? this.saving,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [date, saving, revision];
}
