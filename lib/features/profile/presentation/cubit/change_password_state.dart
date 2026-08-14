import 'package:equatable/equatable.dart';

class ChangePasswordState extends Equatable {
  const ChangePasswordState({
    this.obscureCurrentPassword = true,
    this.obscureNewPassword = true,
    this.obscureConfirmPassword = true,
    this.saving = false,
    this.revision = 0,
  });

  final bool obscureCurrentPassword;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;
  final bool saving;
  final int revision;

  ChangePasswordState copyWith({
    bool? obscureCurrentPassword,
    bool? obscureNewPassword,
    bool? obscureConfirmPassword,
    bool? saving,
    int? revision,
  }) {
    return ChangePasswordState(
      obscureCurrentPassword:
          obscureCurrentPassword ?? this.obscureCurrentPassword,
      obscureNewPassword: obscureNewPassword ?? this.obscureNewPassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
      saving: saving ?? this.saving,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [
    obscureCurrentPassword,
    obscureNewPassword,
    obscureConfirmPassword,
    saving,
    revision,
  ];
}
