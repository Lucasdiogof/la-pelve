import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/cubit/change_password_state.dart';

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit() : super(const ChangePasswordState());

  void toggleObscureCurrentPassword() => emit(
    state.copyWith(obscureCurrentPassword: !state.obscureCurrentPassword),
  );

  void toggleObscureNewPassword() =>
      emit(state.copyWith(obscureNewPassword: !state.obscureNewPassword));

  void toggleObscureConfirmPassword() => emit(
    state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword),
  );

  void setSaving(bool saving) => emit(state.copyWith(saving: saving));

  void notifyFieldChanged() =>
      emit(state.copyWith(revision: state.revision + 1));
}
