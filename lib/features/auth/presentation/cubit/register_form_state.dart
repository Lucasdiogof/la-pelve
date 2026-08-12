import 'package:equatable/equatable.dart';

class RegisterFormState extends Equatable {
  const RegisterFormState({
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.revision = 0,
  });

  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final int revision;

  RegisterFormState copyWith({
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    int? revision,
  }) {
    return RegisterFormState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [
    obscurePassword,
    obscureConfirmPassword,
    revision,
  ];
}
