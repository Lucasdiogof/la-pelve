import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/login_form_state.dart';

class LoginFormCubit extends Cubit<LoginFormState> {
  LoginFormCubit() : super(const LoginFormState());

  void toggleObscurePassword() =>
      emit(state.copyWith(obscurePassword: !state.obscurePassword));

  void markSubmitted() => emit(state.copyWith(submitted: true));

  void notifyFieldChanged() =>
      emit(state.copyWith(revision: state.revision + 1));
}
