import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/profile/domain/entities/whatsapp_connection.dart';

abstract class WhatsappConnectionRepository {
  /// Conexão WhatsApp do profissional autenticado. `Success(null)` quando
  /// não existe nenhuma linha (nunca conectou) — a RLS garante que só a
  /// própria conexão, se existir, é visível.
  Future<Result<WhatsappConnection?>> getCurrentConnection();
}
