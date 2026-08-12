import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/reset_password_state.dart';

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  ResetPasswordCubit() : super(const ResetPasswordState());

  void toggleObscurePassword() =>
      emit(state.copyWith(obscurePassword: !state.obscurePassword));

  void toggleObscureConfirmPassword() => emit(
    state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword),
  );

  void setSaving(bool saving) => emit(state.copyWith(saving: saving));

  void notifyFieldChanged() =>
      emit(state.copyWith(revision: state.revision + 1));
}
