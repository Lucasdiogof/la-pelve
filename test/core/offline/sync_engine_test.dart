import 'package:flutter_test/flutter_test.dart';
import 'package:la_pelve/core/offline/local/local_store.dart';
import 'package:la_pelve/core/offline/local_writer.dart';
import 'package:la_pelve/core/offline/sync/conflict_resolver.dart';
import 'package:la_pelve/core/offline/sync/entity_config.dart';
import 'package:la_pelve/core/offline/sync/remote_gateway.dart';

import 'fakes.dart';

Map<String, Object?> patient(String id, {String name = 'Paciente Ficticia'}) =>
    {'id': id, 'name': name, 'phone': '11999990000', 'age': 30};

Map<String, Object?> appointment(String id, String patientId) => {
  'id': id,
  'date': '2026-10-20',
  'time': '09:00:00',
  'patient_name': 'Paciente Ficticia',
  'patient_id': patientId,
  'status': 'scheduled',
};

Map<String, Object?> evolution(String id, String patientId, String text) => {
  'id': id,
  'patient_id': patientId,
  'date': '2026-10-17',
  'description': text,
};

void main() {
  late Harness h;
  late LocalWriter writer;

  setUp(() {
    h = Harness();
    writer = LocalWriter(h.context);
  });

  test(
    'offline create is persisted locally and reaches server after sync',
    () async {
      h.monitor.online = false;
      writer.create('patients', patient('p1'));

      expect(
        h.store.listRecords('patients').single.state,
        RecordState.pendingCreate,
      );
      expect(h.store.counts().pending, 1);
      await h.engine.sync();
      expect(h.remote.table('patients'), isEmpty, reason: 'still offline');

      h.monitor.online = true;
      await h.engine.sync();
      expect(h.remote.table('patients').keys, ['p1']);
      expect(h.store.counts().total, 0);
      expect(h.store.getRecord('patients', 'p1')!.state, RecordState.synced);
    },
  );

  test(
    'patient and its appointment created offline keep the link in order',
    () async {
      writer.create('patients', patient('p1'));
      writer.create('appointments', appointment('a1', 'p1'));
      await h.engine.sync();

      expect(h.remote.calls.where((c) => c.startsWith('insert')).toList(), [
        'insert patients',
        'insert appointments',
      ]);
      expect(h.remote.table('appointments')['a1']!['patient_id'], 'p1');
    },
  );

  test('child waits while the parent create failed permanently', () async {
    writer.create('patients', patient('p1'));
    writer.create('appointments', appointment('a1', 'p1'));
    h.remote.failWith = RemoteErrorKind.permanent;
    await h.engine.sync();
    h.remote.failWith = null;
    final ops = h.store.liveOps();
    expect(ops.first.status, OpStatus.failed);
    await h.engine.sync();
    expect(h.remote.table('appointments'), isEmpty);
    h.engine.retryOp(ops.first.opId);
    await h.engine.sync();
    await h.engine.sync();
    expect(h.remote.table('appointments').keys, ['a1']);
  });

  test('lost response then retry does not duplicate', () async {
    h.remote.dropResponseOnce = true;
    writer.create('patients', patient('p1'));
    await h.engine.sync();
    expect(h.remote.table('patients').length, 1);
    expect(h.store.counts().pending, 1, reason: 'client never saw the ack');

    await h.engine.sync(force: true);
    expect(h.remote.table('patients').length, 1);
    expect(h.store.counts().total, 0);
  });

  test('network failure backs off and keeps the operation', () async {
    writer.create('patients', patient('p1'));
    h.remote.failWith = RemoteErrorKind.network;
    await h.engine.sync();
    final op = h.store.liveOps().single;
    expect(op.status, OpStatus.pending);
    expect(op.attempts, 1);
    expect(op.nextAttemptAt, isNotNull);
    expect(h.engine.status.isOnline, isFalse);

    h.remote.failWith = null;
    await h.engine.sync();
    expect(h.remote.table('patients'), isEmpty, reason: 'inside backoff');
    await h.engine.sync(force: true);
    expect(h.remote.table('patients').length, 1);
  });

  test('interrupted (syncing) operation is recovered on next run', () async {
    writer.create('patients', patient('p1'));
    final op = h.store.liveOps().single;
    h.store.updateOp(op.copyWith(status: OpStatus.syncing));
    await h.engine.sync();
    expect(h.remote.table('patients').length, 1);
  });

  test('edits to the same record coalesce into one update', () async {
    h.remote.seed('patients', {...patient('p1'), 'created_at': 'x'});
    await h.engine.sync();
    writer.update('patients', 'p1', {...patient('p1'), 'phone': '1'});
    writer.update('patients', 'p1', {...patient('p1'), 'phone': '2'});
    expect(h.store.liveOps().length, 1);
    await h.engine.sync();
    expect(h.remote.table('patients')['p1']!['phone'], '2');
    expect(h.remote.calls.where((c) => c == 'update patients').length, 1);
  });

  group('conflicts', () {
    test('different columns of a patient merge without conflict', () async {
      h.remote.seed('patients', patient('p1'));
      await h.engine.sync();
      writer.update('patients', 'p1', {...patient('p1'), 'phone': '222'});
      h.remote.table('patients')['p1']!['age'] = 31;
      await h.engine.sync();
      final row = h.remote.table('patients')['p1']!;
      expect(row['phone'], '222');
      expect(row['age'], 31);
      expect(h.store.counts().conflicts, 0);
    });

    test(
      'same column edited on both sides is a conflict, never overwritten',
      () async {
        h.remote.seed('patients', patient('p1'));
        await h.engine.sync();
        writer.update('patients', 'p1', {...patient('p1'), 'phone': 'LOCAL'});
        h.remote.table('patients')['p1']!['phone'] = 'REMOTE';
        await h.engine.sync();

        expect(h.remote.table('patients')['p1']!['phone'], 'REMOTE');
        expect(h.store.counts().conflicts, 1);
        final item = h.engine.conflicts().single;
        expect(item.keys, ['phone']);
        expect(item.local['phone'], 'LOCAL');
        expect(item.remote!['phone'], 'REMOTE');
        expect(
          () => writer.updatePatch('patients', 'p1', {'age': 5}),
          throwsA(isA<LocalWriteException>()),
        );
      },
    );

    test('evolution (strict): any remote change conflicts; keepBoth keeps '
        'both texts', () async {
      h.remote.seed('patients', patient('p1'));
      h.remote.seed('evolution_entries', evolution('e1', 'p1', 'original'));
      await h.engine.sync();
      writer.update(
        'evolution_entries',
        'e1',
        evolution('e1', 'p1', 'versao A offline'),
      );
      h.remote.table('evolution_entries')['e1']!['date'] = '2026-10-16';
      await h.engine.sync();

      expect(h.engine.conflicts().single.kind, 'evolution_entries');
      expect(
        h.remote.table('evolution_entries')['e1']!['description'],
        'original',
      );

      await h.engine.resolveConflict(
        'evolution_entries',
        'e1',
        ConflictResolution.keepBoth,
      );
      await h.engine.sync();
      final texts = h.remote
          .table('evolution_entries')
          .values
          .map((r) => r['description'])
          .toSet();
      expect(texts, {'original', 'versao A offline'});
      expect(h.store.counts().total, 0);
    });

    test('keepLocal re-applies on top of the remote version', () async {
      h.remote.seed('patients', patient('p1'));
      await h.engine.sync();
      writer.update('patients', 'p1', {...patient('p1'), 'phone': 'LOCAL'});
      h.remote.table('patients')['p1']!['phone'] = 'REMOTE';
      await h.engine.sync();
      await h.engine.resolveConflict(
        'patients',
        'p1',
        ConflictResolution.keepLocal,
      );
      await h.engine.sync();
      expect(h.remote.table('patients')['p1']!['phone'], 'LOCAL');
      expect(h.store.counts().total, 0);
    });

    test('keepRemote drops the local change', () async {
      h.remote.seed('patients', patient('p1'));
      await h.engine.sync();
      writer.update('patients', 'p1', {...patient('p1'), 'phone': 'LOCAL'});
      h.remote.table('patients')['p1']!['phone'] = 'REMOTE';
      await h.engine.sync();
      await h.engine.resolveConflict(
        'patients',
        'p1',
        ConflictResolution.keepRemote,
      );
      expect(h.store.getRecord('patients', 'p1')!.data['phone'], 'REMOTE');
      expect(h.store.counts().total, 0);
    });

    test(
      'record removed on the server while edited offline is a conflict',
      () async {
        h.remote.seed('evolution_entries', evolution('e1', 'p1', 'x'));
        h.remote.seed('patients', patient('p1'));
        await h.engine.sync();
        writer.update('evolution_entries', 'e1', evolution('e1', 'p1', 'y'));
        h.remote.table('evolution_entries').remove('e1');
        await h.engine.sync();
        expect(h.engine.conflicts().single.remote, isNull);
      },
    );

    test('lost-response retry of an update is not a conflict', () async {
      h.remote.seed('patients', patient('p1'));
      await h.engine.sync();
      writer.update('patients', 'p1', {...patient('p1'), 'phone': 'NEW'});
      h.remote.dropResponseOnce = true;
      await h.engine.sync();
      await h.engine.sync(force: true);
      expect(h.store.counts().total, 0);
      expect(h.remote.table('patients')['p1']!['phone'], 'NEW');
    });
  });

  group('pull', () {
    test(
      'removes synced rows deleted on server, keeps pending local ones',
      () async {
        h.remote.seed('patients', patient('p1'));
        h.remote.seed('patients', patient('p2'));
        await h.engine.sync();
        h.remote.table('patients').remove('p1');
        writer.create('patients', patient('p3'));
        await h.engine.sync();
        final ids = h.store.listRecords('patients').map((r) => r.id).toSet();
        expect(ids, {'p2', 'p3'});
      },
    );

    test('soft-deleted patient disappears locally', () async {
      h.remote.seed('patients', patient('p1'));
      await h.engine.sync();
      h.remote.table('patients')['p1']!['deleted_at'] = 'now';
      await h.engine.sync();
      expect(h.store.listRecords('patients'), isEmpty);
    });

    test(
      'pending local edit is visible immediately and survives a pull',
      () async {
        h.remote.seed('patients', patient('p1'));
        await h.engine.sync();
        h.monitor.online = false;
        writer.update('patients', 'p1', {...patient('p1'), 'phone': 'LOCAL'});
        expect(h.store.getRecord('patients', 'p1')!.data['phone'], 'LOCAL');
        h.engine.applyExternalSnapshot('patients', [patient('p1')]);
        expect(h.store.getRecord('patients', 'p1')!.data['phone'], 'LOCAL');
      },
    );
  });

  group('delete', () {
    test(
      'offline create+delete of an appointment never reaches the server',
      () async {
        writer.create('appointments', appointment('a1', 'p1'));
        writer.delete('appointments', 'a1');
        expect(h.store.liveOps(), isEmpty);
        expect(h.store.listRecords('appointments'), isEmpty);
      },
    );

    test('patient delete is a soft delete on the server', () async {
      h.remote.seed('patients', patient('p1'));
      await h.engine.sync();
      writer.delete('patients', 'p1');
      expect(h.store.listRecords('patients'), isEmpty);
      await h.engine.sync();
      expect(h.remote.table('patients')['p1']!['deleted_at'], isNotNull);
      expect(h.store.allRecords('patients'), isEmpty);
    });
  });

  test('operations of another user are never sent', () async {
    var current = testUser;
    final other = Harness(current: () => current);
    LocalWriter(other.context).create('patients', patient('p1'));
    current = 'someone-else';
    await other.engine.sync();
    expect(other.remote.table('patients'), isEmpty);
    expect(other.engine.status.lastError, 'scope');
  });

  test(
    'discarding a failed create removes the record and its children',
    () async {
      writer.create('patients', patient('p1'));
      writer.create('appointments', appointment('a1', 'p1'));
      h.remote.failWith = RemoteErrorKind.permanent;
      await h.engine.sync();
      final failed = h.engine.failedOps().single;
      h.engine.discardOp(failed.opId);
      expect(h.store.liveOps(), isEmpty);
      expect(h.store.allRecords('patients'), isEmpty);
      expect(h.store.allRecords('appointments'), isEmpty);
    },
  );

  test('applyExternalSnapshot mirrors realtime rows', () async {
    h.engine.applyExternalSnapshot('appointments', [appointment('a1', 'p1')]);
    expect(h.store.listRecords('appointments').single.id, 'a1');
    h.engine.applyExternalSnapshot('appointments', []);
    expect(h.store.listRecords('appointments'), isEmpty);
  });

  test('entity registry is ordered parents first', () {
    final kinds = offlineEntities.map((e) => e.kind).toList();
    expect(kinds.indexOf('patients'), lessThan(kinds.indexOf('appointments')));
  });
}
