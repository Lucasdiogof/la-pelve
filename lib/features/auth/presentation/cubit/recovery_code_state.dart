import 'package:equatable/equatable.dart';

class RecoveryCodeState extends Equatable {
  const RecoveryCodeState({
    this.verifying = false,
    this.resending = false,
    this.cooldownSeconds = 0,
    this.revision = 0,
  });

  final bool verifying;
  final bool resending;
  final int cooldownSeconds;
  final int revision;

  RecoveryCodeState copyWith({
    bool? verifying,
    bool? resending,
    int? cooldownSeconds,
    int? revision,
  }) {
    return RecoveryCodeState(
      verifying: verifying ?? this.verifying,
      resending: resending ?? this.resending,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [verifying, resending, cooldownSeconds, revision];
}
