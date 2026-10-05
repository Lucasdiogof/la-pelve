import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/profile/domain/entities/whatsapp_connection.dart';
import 'package:la_pelve/features/profile/domain/repositories/whatsapp_connection_repository.dart';
import 'package:la_pelve/features/profile/presentation/cubit/whatsapp_connection_state.dart';

class WhatsappConnectionCubit extends Cubit<WhatsappConnectionState> {
  WhatsappConnectionCubit(this._repository)
    : super(const WhatsappConnectionLoading()) {
    load();
  }

  final WhatsappConnectionRepository _repository;

  /// Também serve como retry: tanto o botão de "atualizar status" quanto o
  /// de "tentar novamente" (após falha de consulta) chamam este mesmo
  /// método.
  Future<void> load() async {
    emit(const WhatsappConnectionLoading());
    final result = await _repository.getCurrentConnection();
    switch (result) {
      case Success(:final data):
        emit(_stateFor(data));
      case Error(:final failure):
        emit(WhatsappConnectionLoadFailure(failure));
    }
  }

  WhatsappConnectionState _stateFor(WhatsappConnection? connection) {
    if (connection == null) return const WhatsappConnectionNotConnected();
    return switch (connection.status) {
      WhatsappConnectionStatus.pending => WhatsappConnectionPending(
        connection,
      ),
      WhatsappConnectionStatus.connected => WhatsappConnectionConnected(
        connection,
      ),
      WhatsappConnectionStatus.disconnected => WhatsappConnectionDisconnected(
        connection,
      ),
      WhatsappConnectionStatus.error => WhatsappConnectionError(connection),
    };
  }
}
