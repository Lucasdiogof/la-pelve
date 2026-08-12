import 'package:equatable/equatable.dart';

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({this.sending = false, this.revision = 0});

  final bool sending;
  final int revision;

  ForgotPasswordState copyWith({bool? sending, int? revision}) {
    return ForgotPasswordState(
      sending: sending ?? this.sending,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [sending, revision];
}
