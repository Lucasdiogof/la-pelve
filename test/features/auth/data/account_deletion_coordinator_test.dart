import 'package:flutter_test/flutter_test.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/features/auth/data/account_deletion_coordinator.dart';

class _Gateway implements AccountDeletionGateway {
  final calls = <String>[];
  Object? checkError;
  Object? avatarError;
  Object? deleteError;
  Object? signOutError;

  Future<void> _step(String name, Object? error) async {
    calls.add(name);
    if (error != null) throw error;
  }

  @override
  Future<void> checkAllowed() => _step('check', checkError);

  @override
  Future<void> removeAvatars() => _step('avatars', avatarError);

  @override
  Future<void> deleteAccountOnServer() => _step('delete', deleteError);

  @override
  Future<void> signOut() => _step('signOut', signOutError);

  @override
  Future<void> wipeLocalData() => _step('wipe', null);
}

void main() {
  test(
    'conta vazia: ordem check -> avatar -> servidor -> saída -> limpeza local',
    () async {
      final g = _Gateway();
      await AccountDeletionCoordinator(g).run();
      expect(g.calls, ['check', 'avatars', 'delete', 'signOut', 'wipe']);
    },
  );

  test(
    'conta com dados: bloqueada ANTES de qualquer ação destrutiva',
    () async {
      final g = _Gateway()..checkError = AccountHasDataFailure();
      await expectLater(
        AccountDeletionCoordinator(g).run(),
        throwsA(isA<AccountHasDataFailure>()),
      );
      expect(g.calls, ['check']); // nem avatar, nem exclusão, nem limpeza local
    },
  );

  test('falha de Storage no avatar aborta; a conta não é excluída', () async {
    final g = _Gateway()..avatarError = StateError('storage');
    await expectLater(AccountDeletionCoordinator(g).run(), throwsStateError);
    expect(g.calls, ['check', 'avatars']);
  });

  test('falha da RPC de exclusão: sem signOut nem limpeza local', () async {
    final g = _Gateway()..deleteError = StateError('rpc');
    await expectLater(AccountDeletionCoordinator(g).run(), throwsStateError);
    expect(g.calls, ['check', 'avatars', 'delete']);
  });

  test(
    'servidor recusa na revalidação (dados criados no meio): nada local é apagado',
    () async {
      final g = _Gateway()..deleteError = AccountHasDataFailure();
      await expectLater(
        AccountDeletionCoordinator(g).run(),
        throwsA(isA<AccountHasDataFailure>()),
      );
      expect(g.calls.contains('wipe'), isFalse);
      expect(g.calls.contains('signOut'), isFalse);
    },
  );

  test(
    'conta já excluída no servidor: falha em signOut não vira erro',
    () async {
      final g = _Gateway()..signOutError = StateError('sessão já inválida');
      await AccountDeletionCoordinator(g).run();
      expect(g.calls.last, 'wipe');
    },
  );

  test('repetir após falha é seguro (idempotente)', () async {
    final g = _Gateway()..deleteError = StateError('rede');
    final c = AccountDeletionCoordinator(g);
    await expectLater(c.run(), throwsStateError);
    g.deleteError = null;
    await c.run();
    expect(g.calls.where((c) => c == 'delete').length, 2);
  });

  test('pré-checagem isolada não apaga nada', () async {
    final g = _Gateway();
    await AccountDeletionCoordinator(g).checkOnly();
    expect(g.calls, ['check']);
  });
}
