import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

class HomeClockCubit extends Cubit<int> {
  HomeClockCubit() : super(0) {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => emit(state + 1));
  }

  late final Timer _timer;

  @override
  Future<void> close() {
    _timer.cancel();
    return super.close();
  }
}
