import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/auth/domain/entities/app_user.dart';

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

  Future<Result<void>> deleteAccount();

  Future<Result<void>> sendPasswordResetEmail(String email);

  /// Valida o código de 6 dígitos de recuperação e abre a sessão que permite
  /// definir a nova senha.
  Future<Result<void>> verifyRecoveryCode({
    required String email,
    required String code,
  });

  Future<Result<void>> updatePassword(String newPassword);
}
