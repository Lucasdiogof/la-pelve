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
    DateTime? tokenExpiresAt;
    var tokenExpiring = false;
    var statusStale = false;
    if (result case Success(:final data) when _needsRemoteCheck(data)) {
      // Melhor esforço: se falhar, mostra o que já está salvo (e avisa).
      final remote = await _repository.refreshRemoteStatus();
      if (isClosed) return;
      switch (remote) {
        case Success(:final data):
          tokenExpiresAt = data.tokenExpiresAt;
          tokenExpiring = data.reason == 'token_expiring';
        case Error():
          statusStale = true;
      }
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
        emit(
          _stateFor(
            connection,
            available,
            startFailed,
            tokenExpiresAt: tokenExpiresAt,
            tokenExpiring: tokenExpiring,
            statusStale: statusStale,
          ),
        );
      case Error(:final failure):
        emit(WhatsappConnectionLoadFailure(failure));
    }
  }

  /// Inicia o onboarding: o servidor cria um `state` de uso único ligado à
  /// sessão e devolve a URL; o app só a abre. Nunca simula conexão: o estado
  /// "Conectado" só aparece quando o banco disser.
  Future<void> connect() async {
    if (_starting) return; // toque repetido enquanto a anterior ainda roda
    _starting = true;
    try {
      await _connect();
    } finally {
      _starting = false;
    }
  }

  bool _starting = false;

  Future<void> _connect() async {
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

  /// Pendente: reavalia (templates/webhook). Conectada: confere se a
  /// autorização da Meta ainda vale. Erro por token inválido: confere de novo
  /// (o servidor reabilita se o token voltou a valer). Os demais erros não são
  /// reavaliados sozinhos para não mascarar o que a Meta informou.
  static bool _needsRemoteCheck(WhatsappConnection? connection) {
    if (connection == null) return false;
    return switch (connection.status) {
      WhatsappConnectionStatus.pending ||
      WhatsappConnectionStatus.connected => true,
      WhatsappConnectionStatus.error =>
        connection.lastError?['code'] == 'token_invalid',
      WhatsappConnectionStatus.disconnected => false,
    };
  }

  WhatsappConnectionState _stateFor(
    WhatsappConnection? connection,
    bool available,
    bool startFailed, {
    DateTime? tokenExpiresAt,
    bool tokenExpiring = false,
    bool statusStale = false,
  }) {
    if (connection == null) {
      return WhatsappConnectionNotConnected(
        selfConnectAvailable: available,
        startFailed: startFailed,
      );
    }
    return switch (connection.status) {
      WhatsappConnectionStatus.pending => WhatsappConnectionPending(
        connection,
        statusStale: statusStale,
      ),
      WhatsappConnectionStatus.connected => WhatsappConnectionConnected(
        connection,
        tokenExpiresAt: tokenExpiresAt,
        tokenExpiring: tokenExpiring,
        statusStale: statusStale,
      ),
      WhatsappConnectionStatus.disconnected => WhatsappConnectionDisconnected(
        connection,
        selfConnectAvailable: available,
        startFailed: startFailed,
      ),
      WhatsappConnectionStatus.error => WhatsappConnectionError(
        connection,
        statusStale: statusStale,
      ),
    };
  }
}
