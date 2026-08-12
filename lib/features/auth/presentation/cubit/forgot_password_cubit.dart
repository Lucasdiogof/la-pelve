import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit() : super(const ForgotPasswordState());

  void setSending(bool sending) => emit(state.copyWith(sending: sending));

  void notifyFieldChanged() =>
      emit(state.copyWith(revision: state.revision + 1));
}
