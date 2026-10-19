import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:la_pelve/core/offline/offline_session.dart';
import 'package:la_pelve/core/config/env_config.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/network_errors.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/app_language.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/features/auth/data/account_deletion_coordinator.dart';
import 'package:la_pelve/features/auth/domain/entities/app_user.dart';
import 'package:la_pelve/features/auth/domain/entities/data_deletion_schedule.dart';
import 'package:la_pelve/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client, {this.offline});

  final SupabaseClient _client;

  /// Dados offline do usuário: apagados quando ele sai da conta de propósito.
  final OfflineSession? offline;

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
    } on AuthRetryableFetchException catch (e, st) {
      debugPrint('[AuthRepository.signIn] sem rede: $e\n$st');
      return Error(NetworkFailure());
    } on AuthException catch (e, st) {
      debugPrint(
        '[AuthRepository.signIn] AuthException code=${e.code} msg=${e.message}\n$st',
      );
      return Error(
        AuthFailure(_mapAuthError(e), e.code == 'invalid_credentials'),
      );
    } catch (e, st) {
      debugPrint('[AuthRepository.signIn] $e\n$st');
      return Error(failureFromException(e));
    }
  }

  @override
  Future<Result<void>> verifyPassword(String password) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) return Error(AuthFailure());
    final verificationClient = SupabaseClient(
      EnvConfig.supabaseUrl,
      EnvConfig.supabasePublishableKey,
    );
    try {
      await verificationClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return const Success(null);
    } on AuthException catch (e, st) {
      debugPrint(
        '[AuthRepository.verifyPassword] AuthException code=${e.code} '
        'msg=${e.message}\n$st',
      );
      return Error(
        AuthFailure(_mapAuthError(e), e.code == 'invalid_credentials'),
      );
    } catch (e, st) {
      debugPrint('[AuthRepository.verifyPassword] $e\n$st');
      return Error(UnexpectedFailure());
    } finally {
      await verificationClient.dispose();
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
            : 'lapelve://confirm-signup',
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
      final userId = _client.auth.currentUser?.id;
      await _client.auth.signOut();
      // Logout explícito: o cache clínico local não pode sobreviver à conta.
      if (userId != null) await offline?.wipeUser(userId);
      return const Success(null);
    } catch (e, st) {
      debugPrint('[AuthRepository.signOut] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  late final AccountDeletionCoordinator _deletion = AccountDeletionCoordinator(
    _SupabaseDeletionGateway(_client, offline),
  );

  @override
  Future<Result<void>> checkAccountDeletionAllowed() =>
      _runDeletion(_deletion.checkOnly, 'checkAccountDeletionAllowed');

  @override
  Future<Result<void>> deleteAccount() =>
      _runDeletion(_deletion.run, 'deleteAccount');

  @override
  Future<Result<DataDeletionSchedule?>> getDataDeletionSchedule() async {
    try {
      final data = await _client.rpc<dynamic>('get_account_deletion_status');
      if (data is Map) {
        return Success(
          DataDeletionSchedule.fromJson(Map<String, dynamic>.from(data)),
        );
      }
      return const Success(null);
    } catch (e) {
      debugPrint('[AuthRepository.getDataDeletionSchedule] ${e.runtimeType}');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<DataDeletionSchedule>> requestDataDeletion() async {
    try {
      final data = await _client.rpc<dynamic>(
        'request_account_data_deletion',
        params: {'p_confirmation': 'EXCLUIR_TODOS_OS_DADOS'},
      );
      final schedule = DataDeletionSchedule.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
      // Sai da conta e limpa o cache deste aparelho: os dados somem da tela
      // na hora; para voltar, é só entrar de novo e restaurar dentro do prazo.
      final userId = _client.auth.currentUser?.id;
      try {
        await _client.auth.signOut();
        if (userId != null) await offline?.wipeUser(userId);
      } catch (_) {}
      return Success(schedule);
    } on PostgrestException catch (e) {
      debugPrint('[AuthRepository.requestDataDeletion] code=${e.code}');
      return Error(ServerFailure());
    } catch (e) {
      debugPrint('[AuthRepository.requestDataDeletion] ${e.runtimeType}');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> cancelDataDeletion() async {
    try {
      await _client.rpc<void>('cancel_account_data_deletion');
      return const Success(null);
    } on PostgrestException catch (e) {
      debugPrint('[AuthRepository.cancelDataDeletion] code=${e.code}');
      return Error(ServerFailure());
    } catch (e) {
      debugPrint('[AuthRepository.cancelDataDeletion] ${e.runtimeType}');
      return Error(UnexpectedFailure());
    }
  }

  Future<Result<void>> _runDeletion(
    Future<void> Function() body,
    String label,
  ) async {
    try {
      await body();
      return const Success(null);
    } on AccountHasDataFailure catch (f) {
      return Error(f);
    } on StorageException catch (e) {
      debugPrint('[AuthRepository.$label] storage statusCode=${e.statusCode}');
      return Error(ServerFailure());
    } on PostgrestException catch (e) {
      debugPrint('[AuthRepository.$label] code=${e.code}');
      return Error(ServerFailure());
    } catch (e) {
      debugPrint('[AuthRepository.$label] ${e.runtimeType}');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
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
  Future<Result<void>> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        type: OtpType.recovery,
        email: email,
        token: code,
      );
      if (response.session == null) return Error(AuthFailure());
      return const Success(null);
    } on AuthException catch (e, st) {
      debugPrint(
        '[AuthRepository.verifyRecoveryCode] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(AuthFailure(_mapAuthError(e)));
    } catch (e, st) {
      debugPrint('[AuthRepository.verifyRecoveryCode] $e\n$st');
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

  String _confirmEmailMessage() => switch (_language) {
    AppLanguage.portuguese =>
      'Confirme o e-mail enviado para concluir o cadastro.',
    AppLanguage.english => 'Confirm the email we sent to finish signing up.',
    AppLanguage.spanish =>
      'Confirma el correo que enviamos para completar el registro.',
  };

  String _mapAuthError(AuthException e) {
    final code = e.code ?? '';
    return switch ((code, _language)) {
      ('invalid_credentials', AppLanguage.portuguese) =>
        'E-mail ou senha incorretos.',
      ('invalid_credentials', AppLanguage.english) =>
        'Incorrect email or password.',
      ('invalid_credentials', AppLanguage.spanish) =>
        'Correo electrónico o contraseña incorrectos.',
      ('email_address_invalid', AppLanguage.portuguese) =>
        'Endereço de e-mail inválido. Verifique e tente novamente.',
      ('email_address_invalid', AppLanguage.english) =>
        'Invalid email address. Check it and try again.',
      ('email_address_invalid', AppLanguage.spanish) =>
        'Dirección de correo inválida. Verifícala e inténtalo de nuevo.',
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
      (
        'email_already_in_use' ||
            'user_already_registered' ||
            'user_already_exists',
        AppLanguage.spanish,
      ) =>
        'Ya existe una cuenta con este correo electrónico.',
      ('weak_password', AppLanguage.portuguese) =>
        'A senha deve ter no mínimo 8 caracteres.',
      ('weak_password', AppLanguage.english) =>
        'The password must be at least 8 characters long.',
      ('weak_password', AppLanguage.spanish) =>
        'La contraseña debe tener al menos 8 caracteres.',
      ('over_email_send_rate_limit', AppLanguage.portuguese) =>
        'Muitos envios de e-mail em pouco tempo. Aguarde alguns minutos e tente novamente.',
      ('over_email_send_rate_limit', AppLanguage.english) =>
        'Too many attempts in a short time. Wait a few minutes and try again.',
      ('over_email_send_rate_limit', AppLanguage.spanish) =>
        'Demasiados intentos en poco tiempo. Espera unos minutos e inténtalo de nuevo.',
      ('otp_expired', AppLanguage.portuguese) =>
        'Código inválido ou expirado. Confira os 6 dígitos ou peça um novo.',
      ('otp_expired', AppLanguage.english) =>
        'Invalid or expired code. Check the 6 digits or request a new one.',
      ('otp_expired', AppLanguage.spanish) =>
        'Código inválido o vencido. Revisa los 6 dígitos o solicita uno nuevo.',
      ('over_request_rate_limit', AppLanguage.portuguese) =>
        'Muitas tentativas. Aguarde um instante e tente novamente.',
      ('over_request_rate_limit', AppLanguage.english) =>
        'Too many attempts. Wait a moment and try again.',
      ('over_request_rate_limit', AppLanguage.spanish) =>
        'Demasiados intentos. Espera un momento e inténtalo de nuevo.',
      (_, AppLanguage.portuguese) => 'Erro de autenticação. Tente novamente.',
      (_, AppLanguage.english) => 'Authentication error. Please try again.',
      (_, AppLanguage.spanish) => 'Error de autenticación. Inténtalo de nuevo.',
    };
  }
}

class _SupabaseDeletionGateway implements AccountDeletionGateway {
  _SupabaseDeletionGateway(this._client, this._offline);

  final SupabaseClient _client;
  final OfflineSession? _offline;

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<void> checkAllowed() async {
    try {
      await _client.rpc<void>('check_account_deletion_allowed');
    } on PostgrestException catch (e) {
      if (e.message.contains('account_has_data')) throw AccountHasDataFailure();
      rethrow;
    }
  }

  @override
  Future<void> removeAvatars() async {
    final userId = _userId;
    if (userId == null) return;
    final files = await _client.storage.from('avatars').list(path: userId);
    if (files.isEmpty) return;
    await _client.storage
        .from('avatars')
        .remove(files.map((f) => '$userId/${f.name}').toList());
  }

  @override
  Future<void> deleteAccountOnServer() async {
    try {
      await _client.rpc<void>('delete_own_account');
    } on PostgrestException catch (e) {
      if (e.message.contains('account_has_data')) throw AccountHasDataFailure();
      rethrow;
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> wipeLocalData() async {
    final userId = _userId;
    if (userId != null) await _offline?.wipeUser(userId);
  }
}
