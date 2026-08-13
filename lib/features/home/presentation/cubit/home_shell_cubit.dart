import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/cubit/home_shell_state.dart';

class HomeShellCubit extends Cubit<HomeShellState> {
  HomeShellCubit() : super(const HomeShellState());

  void navigateToTab(int index) {
    emit(
      state.copyWith(
        index: index,
        agendaResetKey: index == 2 ? state.agendaResetKey + 1 : null,
        financialResetKey: index == 3 ? state.financialResetKey + 1 : null,
      ),
    );
  }
}
