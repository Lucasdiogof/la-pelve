import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/error/failures.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/auth/domain/repositories/auth_repository.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthInitial());

  final AuthRepository _repository;

  Future<void> signIn({required String email, required String password}) async {
    emit(const AuthLoading());
    final result = await _repository.signIn(email: email, password: password);
    switch (result) {
      case Success(:final data):
        emit(AuthSuccess(data));
      case Error(:final failure):
        emit(
          AuthError(
            failure.message,
            isInvalidCredentials:
                failure is AuthFailure && failure.isInvalidCredentials,
          ),
        );
    }
  }

  Future<void> signUp({
    required String nome,
    required String crefito,
    required String telefone,
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    final result = await _repository.signUp(
      nome: nome,
      crefito: crefito,
      telefone: telefone,
      email: email,
      password: password,
    );
    switch (result) {
      case Success(:final data):
        emit(AuthSuccess(data));
      case Error(:final failure):
        emit(AuthError(failure.message));
    }
  }
}
