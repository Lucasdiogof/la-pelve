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
  const WhatsappConnectionNotConnected();
}

class WhatsappConnectionPending extends WhatsappConnectionState {
  const WhatsappConnectionPending(this.connection);

  final WhatsappConnection connection;

  @override
  List<Object?> get props => [connection];
}

class WhatsappConnectionConnected extends WhatsappConnectionState {
  const WhatsappConnectionConnected(this.connection);

  final WhatsappConnection connection;

  @override
  List<Object?> get props => [connection];
}

class WhatsappConnectionDisconnected extends WhatsappConnectionState {
  const WhatsappConnectionDisconnected(this.connection);

  final WhatsappConnection connection;

  @override
  List<Object?> get props => [connection];
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
