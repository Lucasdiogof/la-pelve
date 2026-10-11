import 'package:equatable/equatable.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/features/profile/domain/entities/whatsapp_connection.dart';

sealed class WhatsappConnectionState extends Equatable {
  const WhatsappConnectionState();

  @override
  List<Object?> get props => [];
}

class WhatsappConnectionLoading extends WhatsappConnectionState {
  const WhatsappConnectionLoading();
}

/// Nenhuma linha em `whatsapp_connections` para este profissional: nunca
/// conectou.
class WhatsappConnectionNotConnected extends WhatsappConnectionState {
  const WhatsappConnectionNotConnected({
    this.selfConnectAvailable = false,
    this.startFailed = false,
  });

  /// O backend liberou o onboarding (Embedded Signup). Falso = a tela mostra
  /// "Integração em preparação" e nenhum botão.
  final bool selfConnectAvailable;

  /// A última tentativa de iniciar a conexão falhou (antes de abrir a Meta).
  final bool startFailed;

  @override
  List<Object?> get props => [selfConnectAvailable, startFailed];
}

/// O fluxo da Meta foi aberto em outra aba/janela; aguardando o retorno.
class WhatsappConnectionConnecting extends WhatsappConnectionState {
  const WhatsappConnectionConnecting();
}

class WhatsappConnectionPending extends WhatsappConnectionState {
  const WhatsappConnectionPending(this.connection);

  final WhatsappConnection connection;

  @override
  List<Object?> get props => [connection];
}

class WhatsappConnectionConnected extends WhatsappConnectionState {
  const WhatsappConnectionConnected(
    this.connection, {
    this.disconnectFailed = false,
  });

  final WhatsappConnection connection;

  /// A última tentativa de desconectar falhou; a conexão segue ativa.
  final bool disconnectFailed;

  @override
  List<Object?> get props => [connection, disconnectFailed];
}

class WhatsappConnectionDisconnected extends WhatsappConnectionState {
  const WhatsappConnectionDisconnected(
    this.connection, {
    this.selfConnectAvailable = false,
    this.startFailed = false,
  });

  final WhatsappConnection connection;
  final bool selfConnectAvailable;
  final bool startFailed;

  @override
  List<Object?> get props => [connection, selfConnectAvailable, startFailed];
}

/// `status == 'error'` na própria linha de `whatsapp_connections` (falha
/// do lado da Meta/backend ao conectar). Diferente de
/// [WhatsappConnectionLoadFailure], que é falha ao CONSULTAR o Supabase.
class WhatsappConnectionError extends WhatsappConnectionState {
  const WhatsappConnectionError(this.connection);

  final WhatsappConnection connection;

  @override
  List<Object?> get props => [connection];
}

/// Falha ao consultar o Supabase (rede, timeout, erro do servidor). Nunca
/// deve ser confundido com [WhatsappConnectionNotConnected].
class WhatsappConnectionLoadFailure extends WhatsappConnectionState {
  const WhatsappConnectionLoadFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
