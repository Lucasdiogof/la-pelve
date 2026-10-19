import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/auth/domain/entities/app_user.dart';
import 'package:la_pelve/features/auth/domain/entities/data_deletion_schedule.dart';

abstract class AuthRepository {
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void>> verifyPassword(String password);

  Future<Result<AppUser>> signUp({
    required String nome,
    required String crefito,
    required String telefone,
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();

  /// Pré-checagem no servidor, sem apagar nada. [AccountHasDataFailure] quando
  /// a conta tem registros que precisam ser preservados.
  Future<Result<void>> checkAccountDeletionAllowed();

  Future<Result<void>> deleteAccount();

  /// Exclusão definitiva já pedida (null quando não há). Dentro do prazo a
  /// conta pode ser restaurada.
  Future<Result<DataDeletionSchedule?>> getDataDeletionSchedule();

  /// Pede a exclusão de TODOS os dados com prazo de arrependimento de 30 dias.
  /// O servidor exige a confirmação explícita e é quem conta o prazo.
  Future<Result<DataDeletionSchedule>> requestDataDeletion();

  Future<Result<void>> cancelDataDeletion();

  Future<Result<void>> sendPasswordResetEmail(String email);

  /// Valida o código de 6 dígitos de recuperação e abre a sessão que permite
  /// definir a nova senha.
  Future<Result<void>> verifyRecoveryCode({
    required String email,
    required String code,
  });

  Future<Result<void>> updatePassword(String newPassword);
}
