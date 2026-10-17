import 'package:flutter_test/flutter_test.dart';
import 'package:la_pelve/core/offline/connectivity_monitor.dart';
import 'package:la_pelve/core/offline/local/key_vault.dart';
import 'package:la_pelve/core/offline/local_writer.dart';
import 'package:la_pelve/core/offline/offline_session.dart';
import 'package:la_pelve/core/offline/sync/remote_gateway.dart';
import 'package:la_pelve/core/offline/sync/sync_status_cubit.dart';

import 'fakes.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('flush', () {
    test('reports true once the entity reached the server', () async {
      final h = Harness();
      LocalWriter(h.context).create('patients', {'id': 'p1', 'name': 'X'});
      expect(await h.engine.flush('patients', 'p1'), isTrue);
      expect(h.remote.table('patients').keys, ['p1']);
    });

    test('reports false offline and does not wait', () async {
      final h = Harness();
      h.monitor.online = false;
      LocalWriter(h.context).create('patients', {'id': 'p1', 'name': 'X'});
      expect(await h.engine.flush('patients', 'p1'), isFalse);
      expect(h.store.counts().pending, 1);
    });

    test('reports false on network error without looping', () async {
      final h = Harness();
      LocalWriter(h.context).create('patients', {'id': 'p1', 'name': 'X'});
      h.remote.failWith = RemoteErrorKind.network;
      expect(await h.engine.flush('patients', 'p1'), isFalse);
      expect(h.store.liveOps().single.attempts, 1);
    });
  });

  group('SyncStatusCubit', () {
    late FakeConnectivityMonitor monitor;
    late FakeRemote remote;
    late OfflineSession session;
    late SyncStatusCubit cubit;

    setUp(() async {
      monitor = FakeConnectivityMonitor();
      remote = FakeRemote();
      session = OfflineSession(
        vault: InMemoryKeyVault(),
        remote: remote,
        monitor: monitor,
        currentUserId: () => testUser,
        provider: FakeStoreProvider(),
        autoSync: false,
      );
      cubit = SyncStatusCubit(session, monitor);
    });

    tearDown(() async {
      await cubit.close();
      await session.dispose();
    });

    test('hidden without a session, synced bar stays hidden', () async {
      expect(cubit.state.kind, SyncUiKind.hidden);
      expect(cubit.state.visible, isFalse);
      await session.onUser(testUser);
      await settle();
      expect(cubit.state.kind, SyncUiKind.synced);
      expect(cubit.state.visible, isFalse);
    });

    test('offline with pending, then synced confirmation', () async {
      final ctx = (await session.onUser(testUser))!;
      await settle();
      monitor.online = false;
      LocalWriter(ctx).create('patients', {'id': 'p1', 'name': 'X'});
      await ctx.engine.sync();
      await settle();
      expect(cubit.state.kind, SyncUiKind.offline);
      expect(cubit.state.pending, 1);
      expect(cubit.state.visible, isTrue);

      monitor.online = true;
      await ctx.engine.sync(force: true);
      await settle();
      expect(cubit.state.kind, SyncUiKind.synced);
      expect(cubit.state.justSynced, isTrue);
      expect(cubit.state.visible, isTrue, reason: 'brief confirmation');
    });

    test('conflict outranks everything', () async {
      final ctx = (await session.onUser(testUser))!;
      remote.seed('patients', {'id': 'p1', 'name': 'A'});
      await ctx.engine.sync();
      LocalWriter(ctx).update('patients', 'p1', {'id': 'p1', 'name': 'LOCAL'});
      remote.table('patients')['p1']!['name'] = 'REMOTE';
      await ctx.engine.sync();
      await settle();
      expect(cubit.state.kind, SyncUiKind.conflict);
      expect(cubit.state.conflicts, 1);
    });

    test('permanent failure shows the error state', () async {
      final ctx = (await session.onUser(testUser))!;
      LocalWriter(ctx).create('patients', {'id': 'p1', 'name': 'X'});
      remote.failWith = RemoteErrorKind.permanent;
      await ctx.engine.sync();
      await settle();
      expect(cubit.state.kind, SyncUiKind.error);
      expect(cubit.state.failed, 1);
    });
  });
}
