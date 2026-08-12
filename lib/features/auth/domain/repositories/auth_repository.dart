import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  });

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

  Future<Result<void>> updatePassword(String newPassword);
}
