import 'package:flutter_bloc/flutter_bloc.dart';

class AppLockCubit extends Cubit<bool> {
  AppLockCubit() : super(false);

  void lock() => emit(true);

  void unlock() => emit(false);
}
