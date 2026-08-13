import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fisioterapia_pelvica/core/error/failures.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/auth/domain/entities/app_user.dart';
import 'package:fisioterapia_pelvica/features/auth/domain/repositories/auth_repository.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fisioterapia_pelvica/features/auth/presentation/cubit/auth_state.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  const user = AppUser(id: 'u1', email: 'lucas@example.com');

  setUp(() {
    repository = _MockAuthRepository();
  });

  group('AuthCubit.signIn', () {
    blocTest<AuthCubit, AuthState>(
      'emits loading then success on a valid sign in',
      setUp: () {
        when(
          () => repository.signIn(
            email: 'lucas@example.com',
            password: '12345678',
          ),
        ).thenAnswer((_) async => const Success(user));
      },
      build: () => AuthCubit(repository),
      act: (cubit) =>
          cubit.signIn(email: 'lucas@example.com', password: '12345678'),
      expect: () => [const AuthLoading(), const AuthSuccess(user)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits loading then a generic error on a server failure',
      setUp: () {
        when(
          () =>
              repository.signIn(email: 'lucas@example.com', password: 'wrong'),
        ).thenAnswer(
          (_) async => const Error(ServerFailure('Erro no servidor.')),
        );
      },
      build: () => AuthCubit(repository),
      act: (cubit) =>
          cubit.signIn(email: 'lucas@example.com', password: 'wrong'),
      expect: () => [const AuthLoading(), const AuthError('Erro no servidor.')],
    );

    blocTest<AuthCubit, AuthState>(
      'flags isInvalidCredentials on an AuthFailure with invalid credentials',
      setUp: () {
        when(
          () =>
              repository.signIn(email: 'lucas@example.com', password: 'wrong'),
        ).thenAnswer(
          (_) async => const Error(AuthFailure('Credenciais inválidas.', true)),
        );
      },
      build: () => AuthCubit(repository),
      act: (cubit) =>
          cubit.signIn(email: 'lucas@example.com', password: 'wrong'),
      expect: () => [
        const AuthLoading(),
        const AuthError('Credenciais inválidas.', isInvalidCredentials: true),
      ],
    );
  });

  group('AuthCubit.signUp', () {
    blocTest<AuthCubit, AuthState>(
      'emits loading then success on a valid sign up',
      setUp: () {
        when(
          () => repository.signUp(
            nome: 'Lucas',
            crefito: '123456-F3',
            telefone: '11933334444',
            email: 'lucas@example.com',
            password: '12345678',
          ),
        ).thenAnswer((_) async => const Success(user));
      },
      build: () => AuthCubit(repository),
      act: (cubit) => cubit.signUp(
        nome: 'Lucas',
        crefito: '123456-F3',
        telefone: '11933334444',
        email: 'lucas@example.com',
        password: '12345678',
      ),
      expect: () => [const AuthLoading(), const AuthSuccess(user)],
    );
  });
}
