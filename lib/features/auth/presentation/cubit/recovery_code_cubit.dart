import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/features/auth/presentation/cubit/recovery_code_state.dart';

const kRecoveryResendCooldownSeconds = 60;

class RecoveryCodeCubit extends Cubit<RecoveryCodeState> {
  RecoveryCodeCubit()
    : super(
        const RecoveryCodeState(
          cooldownSeconds: kRecoveryResendCooldownSeconds,
        ),
      ) {
    _startTimer();
  }

  Timer? _timer;

  void setVerifying(bool verifying) =>
      emit(state.copyWith(verifying: verifying));

  void setResending(bool resending) =>
      emit(state.copyWith(resending: resending));

  void notifyFieldChanged() =>
      emit(state.copyWith(revision: state.revision + 1));

  void restartCooldown() {
    emit(state.copyWith(cooldownSeconds: kRecoveryResendCooldownSeconds));
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.cooldownSeconds - 1;
      if (next <= 0) timer.cancel();
      emit(state.copyWith(cooldownSeconds: next < 0 ? 0 : next));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
