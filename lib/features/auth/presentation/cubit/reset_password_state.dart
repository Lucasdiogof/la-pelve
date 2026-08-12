import 'package:equatable/equatable.dart';

class ResetPasswordState extends Equatable {
  const ResetPasswordState({
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.saving = false,
    this.revision = 0,
  });

  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool saving;
  final int revision;

  ResetPasswordState copyWith({
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    bool? saving,
    int? revision,
  }) {
    return ResetPasswordState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
      saving: saving ?? this.saving,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [
    obscurePassword,
    obscureConfirmPassword,
    saving,
    revision,
  ];
}
