import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/features/auth/domain/entities/app_user.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  const AuthSuccess(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  const AuthError(this.message, {this.isInvalidCredentials = false});

  final String message;
  final bool isInvalidCredentials;

  @override
  List<Object?> get props => [message, isInvalidCredentials];
}
