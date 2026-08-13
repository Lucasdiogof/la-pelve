import 'package:flutter_bloc/flutter_bloc.dart';

class AgendaReportMonthCubit extends Cubit<DateTime> {
  AgendaReportMonthCubit()
    : super(DateTime(DateTime.now().year, DateTime.now().month));

  void shift(int delta) => emit(DateTime(state.year, state.month + delta));
}
