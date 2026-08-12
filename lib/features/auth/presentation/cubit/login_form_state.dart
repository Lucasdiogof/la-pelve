import 'package:equatable/equatable.dart';

class LoginFormState extends Equatable {
  const LoginFormState({
    this.obscurePassword = true,
    this.submitted = false,
    this.revision = 0,
  });

  final bool obscurePassword;
  final bool submitted;
  final int revision;

  LoginFormState copyWith({
    bool? obscurePassword,
    bool? submitted,
    int? revision,
  }) {
    return LoginFormState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
      submitted: submitted ?? this.submitted,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [obscurePassword, submitted, revision];
}
