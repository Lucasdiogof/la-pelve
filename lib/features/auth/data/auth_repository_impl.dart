import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fisioterapia_pelvica/core/error/failures.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/features/auth/domain/entities/app_user.dart';
import 'package:fisioterapia_pelvica/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client);

  final SupabaseClient _client;

  AppLanguage get _language {
    if (!GetIt.instance.isRegistered<LocaleCubit>()) {
      return AppLanguage.portuguese;
    }
    return GetIt.instance<LocaleCubit>().state;
  }

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) return Error(AuthFailure());
      return Success(AppUser(id: user.id, email: user.email ?? email));
    } on AuthException catch (e, st) {
      debugPrint(
        '[AuthRepository.signIn] AuthException code=${e.code} msg=${e.message}\n$st',
      );
      return Error(
        AuthFailure(_mapAuthError(e), e.code == 'invalid_credentials'),
      );
    } catch (e, st) {
      debugPrint('[AuthRepository.signIn] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<AppUser>> signUp({
    required String nome,
    required String crefito,
    required String telefone,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: kIsWeb
            ? '${Uri.base.origin}/'
            : 'fisioterapiapelvica://confirm-signup',
        data: {'nome': nome, 'crefito': crefito, 'telefone': telefone},
      );
      final user = response.user;
      if (user == null) return Error(AuthFailure());

      if (response.session == null) {
        return Error(AuthFailure(_confirmEmailMessage()));
      }

      return Success(AppUser(id: user.id, email: user.email ?? email));
    } on AuthException catch (e, st) {
      debugPrint(
        '[AuthRepository.signUp] AuthException code=${e.code} msg=${e.message}\n$st',
      );
      return Error(AuthFailure(_mapAuthError(e)));
    } catch (e, st) {
      debugPrint('[AuthRepository.signUp] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Success(null);
    } catch (e, st) {
      debugPrint('[AuthRepository.signOut] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) await _deleteAllUserFiles(userId);
      await _client.rpc<void>('delete_own_account');
      await _client.auth.signOut();
      return const Success(null);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[AuthRepository.deleteAccount] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[AuthRepository.deleteAccount] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb
            ? '${Uri.base.origin}/redefinir-senha'
            : 'fisioterapiapelvica://reset-password',
      );
      return const Success(null);
    } on AuthException catch (e, st) {
      debugPrint(
        '[AuthRepository.sendPasswordResetEmail] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(AuthFailure(_mapAuthError(e)));
    } catch (e, st) {
      debugPrint('[AuthRepository.sendPasswordResetEmail] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return const Success(null);
    } on AuthException catch (e, st) {
      debugPrint(
        '[AuthRepository.updatePassword] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(AuthFailure(_mapAuthError(e)));
    } catch (e, st) {
      debugPrint('[AuthRepository.updatePassword] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  Future<void> _deleteAllUserFiles(String userId) async {
    try {
      final avatarFiles = await _client.storage
          .from('avatars')
          .list(path: userId);
      if (avatarFiles.isNotEmpty) {
        await _client.storage
            .from('avatars')
            .remove(avatarFiles.map((f) => '$userId/${f.name}').toList());
      }
    } catch (e, st) {
      debugPrint(
        '[AuthRepository.deleteAccount] avatar cleanup failed: $e\n$st',
      );
    }

    try {
      final patientFolders = await _client.storage
          .from('patient-attachments')
          .list(path: userId);
      for (final folder in patientFolders) {
        final files = await _client.storage
            .from('patient-attachments')
            .list(path: '$userId/${folder.name}');
        if (files.isNotEmpty) {
          await _client.storage
              .from('patient-attachments')
              .remove(
                files.map((f) => '$userId/${folder.name}/${f.name}').toList(),
              );
        }
      }
    } catch (e, st) {
      debugPrint(
        '[AuthRepository.deleteAccount] attachment cleanup failed: $e\n$st',
      );
    }
  }

  String _confirmEmailMessage() => switch (_language) {
    AppLanguage.portuguese =>
      'Confirme o e-mail enviado para concluir o cadastro.',
    AppLanguage.english => 'Confirm the email we sent to finish signing up.',
  };

  String _mapAuthError(AuthException e) {
    final code = e.code ?? '';
    return switch ((code, _language)) {
      ('invalid_credentials', AppLanguage.portuguese) =>
        'E-mail ou senha incorretos.',
      ('invalid_credentials', AppLanguage.english) =>
        'Incorrect email or password.',
      ('email_address_invalid', AppLanguage.portuguese) =>
        'Endereço de e-mail inválido. Verifique e tente novamente.',
      ('email_address_invalid', AppLanguage.english) =>
        'Invalid email address. Check it and try again.',
      (
        'email_already_in_use' ||
            'user_already_registered' ||
            'user_already_exists',
        AppLanguage.portuguese,
      ) =>
        'Já existe uma conta com este e-mail.',
      (
        'email_already_in_use' ||
            'user_already_registered' ||
            'user_already_exists',
        AppLanguage.english,
      ) =>
        'An account with this email already exists.',
      ('weak_password', AppLanguage.portuguese) =>
        'A senha deve ter no mínimo 8 caracteres.',
      ('weak_password', AppLanguage.english) =>
        'The password must be at least 8 characters long.',
      ('over_email_send_rate_limit', AppLanguage.portuguese) =>
        'Muitos cadastros em pouco tempo. Aguarde alguns minutos e tente novamente.',
      ('over_email_send_rate_limit', AppLanguage.english) =>
        'Too many attempts in a short time. Wait a few minutes and try again.',
      (_, AppLanguage.portuguese) => 'Erro de autenticação. Tente novamente.',
      (_, AppLanguage.english) => 'Authentication error. Please try again.',
    };
  }
}
