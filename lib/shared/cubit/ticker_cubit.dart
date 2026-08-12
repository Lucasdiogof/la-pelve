import 'package:flutter_bloc/flutter_bloc.dart';

class TickerCubit extends Cubit<int> {
  TickerCubit() : super(0);

  void tick() => emit(state + 1);
}
