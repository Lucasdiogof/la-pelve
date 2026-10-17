import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:la_pelve/core/offline/connectivity_monitor.dart';
import 'package:la_pelve/core/offline/local/key_vault.dart';
import 'package:la_pelve/core/offline/local/local_store.dart';
import 'package:la_pelve/core/offline/local/local_store_factory_io.dart';
import 'package:la_pelve/core/offline/offline_session.dart';

import 'fakes.dart';

void main() {
  late Directory dir;
  late InMemoryKeyVault vault;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('lp_offline_test_');
    vault = InMemoryKeyVault();
  });

  tearDown(() => dir.deleteSync(recursive: true));

  const secret = 'DADO-CLINICO-FICTICIO-12345';

  Future<void> write(LocalStore store) async {
    store.putRecord(
      const LocalRecord(
        kind: 'evolution_entries',
        id: 'e1',
        data: {'id': 'e1', 'description': secret},
        state: RecordState.pendingCreate,
      ),
    );
    store.enqueue(
      opId: 'op1',
      kind: 'evolution_entries',
      entityId: 'e1',
      type: OpType.create,
      payload: const {'id': 'e1', 'description': secret},
    );
  }

  test('data and queue survive closing and reopening the app', () async {
    var store = await openUserStore(
      userId: 'u1',
      vault: vault,
      directory: dir,
    );
    await write(store);
    store.close();

    store = await openUserStore(userId: 'u1', vault: vault, directory: dir);
    expect(store.getRecord('evolution_entries', 'e1')!.data['description'],
        secret);
    expect(store.liveOps().single.opId, 'op1');
    expect(store.counts().pending, 1);
    store.close();
  });

  test('the database file is encrypted at rest', () async {
    final store = await openUserStore(
      userId: 'u1',
      vault: vault,
      directory: dir,
    );
    await write(store);
    store.close();

    final bytes = dir
        .listSync()
        .whereType<File>()
        .expand((f) => f.readAsBytesSync())
        .toList();
    final text = String.fromCharCodes(bytes);
    expect(text.contains(secret), isFalse);
    expect(text.contains('SQLite format 3'), isFalse);
  });

  test('a lost key recreates an empty cache instead of crashing', () async {
    var store = await openUserStore(
      userId: 'u1',
      vault: vault,
      directory: dir,
    );
    await write(store);
    store.close();

    vault.keys.updateAll((_, _) => 'a' * 64);
    store = await openUserStore(userId: 'u1', vault: vault, directory: dir);
    expect(store.listRecords('evolution_entries'), isEmpty);
    store.close();
  });

  test('wipe removes file and key; purge keeps only the given user', () async {
    final a = await openUserStore(userId: 'a', vault: vault, directory: dir);
    final b = await openUserStore(userId: 'b', vault: vault, directory: dir);
    a.close();
    b.close();
    expect(dir.listSync().whereType<File>().length, greaterThanOrEqualTo(2));

    await purgeOtherStores(keepUserId: 'a', vault: vault, directory: dir);
    expect(
      dir.listSync().map((e) => e.path).any((p) => p.contains(scopeOf('b'))),
      isFalse,
    );
    expect(vault.keys.containsKey(scopeOf('b')), isFalse);

    await wipeUserStore(userId: 'a', vault: vault, directory: dir);
    expect(dir.listSync().whereType<File>(), isEmpty);
    expect(vault.keys, isEmpty);
  });

  group('OfflineSession', () {
    late FakeStoreProvider provider;
    late OfflineSession session;
    String? current;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      provider = FakeStoreProvider();
      current = 'u1';
      session = OfflineSession(
        vault: vault,
        remote: FakeRemote(),
        monitor: FakeConnectivityMonitor(),
        currentUserId: () => current,
        provider: provider,
      );
    });

    tearDown(() => session.dispose());

    test('opens the store of the logged user and purges the others', () async {
      final ctx = await session.onUser('u1');
      expect(ctx!.userId, 'u1');
      expect(provider.purged, ['u1']);
    });

    test('switching accounts closes the previous context first', () async {
      final first = await session.onUser('u1');
      final second = await session.onUser('u2');
      expect(second!.userId, 'u2');
      expect(session.active!.userId, 'u2');
      expect(identical(first!.store, second.store), isFalse);
    });

    test('no session closes everything without wiping', () async {
      await session.onUser('u1');
      expect(await session.onUser(null), isNull);
      expect(session.active, isNull);
      expect(provider.wiped, isEmpty);
    });

    test('explicit wipe deletes the user data', () async {
      await session.onUser('u1');
      await session.wipeUser('u1');
      expect(provider.wiped, ['u1']);
      expect(session.active, isNull);
    });
  });
}
