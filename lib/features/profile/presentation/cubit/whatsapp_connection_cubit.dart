import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/profile/domain/entities/whatsapp_connection.dart';
import 'package:la_pelve/features/profile/domain/repositories/whatsapp_connection_repository.dart';
import 'package:la_pelve/features/profile/presentation/cubit/whatsapp_connection_state.dart';

/// Abre a página de onboarding fora do app (navegador do sistema ou nova aba).
typedef WhatsappUrlLauncher = Future<bool> Function(Uri url);

Future<bool> _launchExternal(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

class WhatsappConnectionCubit extends Cubit<WhatsappConnectionState> {
  WhatsappConnectionCubit(this._repository, {this._launcher = _launchExternal})
    : super(const WhatsappConnectionLoading()) {
    load();
  }

  final WhatsappConnectionRepository _repository;
  final WhatsappUrlLauncher _launcher;

  /// Também serve como retry: tanto o botão de "atualizar status" quanto o
  /// de "tentar novamente" (após falha de consulta) chamam este mesmo
  /// método. Conexão pendente é reavaliada no servidor antes de reler.
  Future<void> load({bool startFailed = false}) async {
    if (isClosed) return;
    emit(const WhatsappConnectionLoading());
    var result = await _repository.getCurrentConnection();
    if (isClosed) return;
    if (result case Success(
      :final data,
    ) when data?.status == WhatsappConnectionStatus.pending) {
      // Melhor esforço: se falhar, mostra o que já está salvo.
      await _repository.refreshRemoteStatus();
      if (isClosed) return;
      result = await _repository.getCurrentConnection();
      if (isClosed) return;
    }
    switch (result) {
      case Success(:final data):
        final connection = data;
        final needsAvailability =
            connection == null ||
            connection.status == WhatsappConnectionStatus.disconnected;
        var available = false;
        if (needsAvailability) {
          final availability = await _repository.isSelfConnectAvailable();
          if (isClosed) return;
          available = availability is Success<bool> && availability.data;
        }
        emit(_stateFor(connection, available, startFailed));
      case Error(:final failure):
        emit(WhatsappConnectionLoadFailure(failure));
    }
  }

  /// Inicia o onboarding: o servidor cria um `state` de uso único ligado à
  /// sessão e devolve a URL; o app só a abre. Nunca simula conexão: o estado
  /// "Conectado" só aparece quando o banco disser.
  Future<void> connect() async {
    final current = state;
    final started = await _repository.startConnection();
    if (isClosed) return;
    switch (started) {
      case Success(:final data):
        final opened = await _launcher(data);
        if (isClosed) return;
        if (opened) {
          emit(const WhatsappConnectionConnecting());
        } else {
          await load(startFailed: true);
        }
      case Error():
        if (current is WhatsappConnectionNotConnected) {
          emit(
            WhatsappConnectionNotConnected(
              selfConnectAvailable: current.selfConnectAvailable,
              startFailed: true,
            ),
          );
        } else {
          await load(startFailed: true);
        }
    }
  }

  Future<void> disconnect() async {
    final current = state;
    if (current is! WhatsappConnectionConnected &&
        current is! WhatsappConnectionPending &&
        current is! WhatsappConnectionError) {
      return;
    }
    emit(const WhatsappConnectionLoading());
    final result = await _repository.disconnect();
    if (isClosed) return;
    if (result is Error<void> && current is WhatsappConnectionConnected) {
      emit(
        WhatsappConnectionConnected(current.connection, disconnectFailed: true),
      );
      return;
    }
    await load();
  }

  WhatsappConnectionState _stateFor(
    WhatsappConnection? connection,
    bool available,
    bool startFailed,
  ) {
    if (connection == null) {
      return WhatsappConnectionNotConnected(
        selfConnectAvailable: available,
        startFailed: startFailed,
      );
    }
    return switch (connection.status) {
      WhatsappConnectionStatus.pending => WhatsappConnectionPending(connection),
      WhatsappConnectionStatus.connected => WhatsappConnectionConnected(
        connection,
      ),
      WhatsappConnectionStatus.disconnected => WhatsappConnectionDisconnected(
        connection,
        selfConnectAvailable: available,
        startFailed: startFailed,
      ),
      WhatsappConnectionStatus.error => WhatsappConnectionError(connection),
    };
  }
}
