import 'package:la_pelve/core/error/failures.dart';

/// Operações externas da exclusão de conta. Separadas para que a SEQUÊNCIA
/// (a parte que protege os prontuários) seja testável sem Supabase.
abstract class AccountDeletionGateway {
  /// Pré-checagem no servidor. Lança [AccountHasDataFailure] se a conta tem
  /// dados vinculados (bloqueio definitivo enquanto não houver custódia).
  Future<void> checkAllowed();

  /// Remove só o avatar (não clínico). Falha aborta a exclusão.
  Future<void> removeAvatars();

  /// Exclusão no servidor: relê tudo sob trava e só então apaga a conta.
  Future<void> deleteAccountOnServer();

  Future<void> signOut();

  Future<void> wipeLocalData();
}

/// Sequência segura. O Storage não participa de transação do Postgres, então
/// a ordem é a garantia:
///  1. servidor recusa se há qualquer dado -> nada foi tocado;
///  2. só o avatar é removido pelo cliente (anexos clínicos NUNCA);
///  3. servidor revalida sob trava e exclui. Falha aqui deixa a conta viva e
///     só o avatar ausente (reversível, não clínico);
///  4. limpeza local só depois da exclusão confirmada.
/// Cada passo é idempotente: repetir após falha é seguro.
class AccountDeletionCoordinator {
  AccountDeletionCoordinator(this._gateway);

  final AccountDeletionGateway _gateway;

  Future<void> checkOnly() => _gateway.checkAllowed();

  Future<void> run() async {
    await _gateway.checkAllowed();
    await _gateway.removeAvatars();
    await _gateway.deleteAccountOnServer();
    // A conta já não existe: falhas daqui em diante não podem virar erro de
    // exclusão para quem vê a tela.
    try {
      await _gateway.signOut();
    } catch (_) {}
    try {
      await _gateway.wipeLocalData();
    } catch (_) {}
  }
}
