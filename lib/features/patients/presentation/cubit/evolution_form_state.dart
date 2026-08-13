import 'package:equatable/equatable.dart';

class EvolutionFormState extends Equatable {
  const EvolutionFormState({this.data, this.saving = false, this.revision = 0});

  final DateTime? data;
  final bool saving;
  final int revision;

  EvolutionFormState copyWith({DateTime? data, bool? saving, int? revision}) {
    return EvolutionFormState(
      data: data ?? this.data,
      saving: saving ?? this.saving,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [data, saving, revision];
}
