import 'package:flutter_bloc/flutter_bloc.dart';

class FinancialReportMonthCubit extends Cubit<DateTime> {
  FinancialReportMonthCubit()
    : super(DateTime(DateTime.now().year, DateTime.now().month));

  void shift(int delta) => emit(DateTime(state.year, state.month + delta));
}
