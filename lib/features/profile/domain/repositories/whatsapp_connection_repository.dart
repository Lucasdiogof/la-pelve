import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/profile/domain/entities/whatsapp_connection.dart';

abstract class WhatsappConnectionRepository {
  /// Conexão WhatsApp do profissional autenticado. `Success(null)` quando
  /// não existe nenhuma linha (nunca conectou) — a RLS garante que só a
  /// própria conexão, se existir, é visível.
  Future<Result<WhatsappConnection?>> getCurrentConnection();

  /// O backend liberou o onboarding do WhatsApp? Falso enquanto a Meta/
  /// secrets não estiverem configurados: o app não oferece o botão.
  Future<Result<bool>> isSelfConnectAvailable();

  /// Cria o `state` de uso único no servidor e devolve a URL HTTPS da página
  /// de onboarding (a autorização acontece direto com a Meta).
  Future<Result<Uri>> startConnection();

  /// Pede ao servidor para reavaliar uma conexão pendente (templates e
  /// webhook). Não devolve dado: o chamador relê a conexão em seguida.
  Future<Result<void>> refreshRemoteStatus();

  /// Tira a inscrição do webhook, apaga o token e marca como desconectada.
  Future<Result<void>> disconnect();
}
