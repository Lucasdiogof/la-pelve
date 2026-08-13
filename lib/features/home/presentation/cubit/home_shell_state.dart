import 'package:equatable/equatable.dart';

class HomeShellState extends Equatable {
  const HomeShellState({
    this.index = 0,
    this.agendaResetKey = 0,
    this.financialResetKey = 0,
  });

  final int index;
  final int agendaResetKey;
  final int financialResetKey;

  HomeShellState copyWith({
    int? index,
    int? agendaResetKey,
    int? financialResetKey,
  }) {
    return HomeShellState(
      index: index ?? this.index,
      agendaResetKey: agendaResetKey ?? this.agendaResetKey,
      financialResetKey: financialResetKey ?? this.financialResetKey,
    );
  }

  @override
  List<Object?> get props => [index, agendaResetKey, financialResetKey];
}
