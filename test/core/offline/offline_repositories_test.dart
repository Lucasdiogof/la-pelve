import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/offline/connectivity_monitor.dart';
import 'package:la_pelve/core/offline/local/key_vault.dart';
import 'package:la_pelve/core/offline/offline_session.dart';
import 'package:la_pelve/features/agenda/data/agenda_repository_offline.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment_status.dart';
import 'package:la_pelve/features/agenda/domain/repositories/agenda_repository.dart';
import 'package:la_pelve/features/financial/data/financial_repository_offline.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/financial/domain/repositories/financial_repository.dart';
import 'package:la_pelve/features/patients/data/patient_repository_offline.dart';
import 'package:la_pelve/features/patients/domain/entities/evolution_entry.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_repository.dart';
import 'package:mocktail/mocktail.dart';

import 'fakes.dart';

class FakeConnectivityMonitorHolder {
  final monitor = FakeConnectivityMonitor();
}

class _MockPatientRepo extends Mock implements PatientRepository {}

class _MockAgendaRepo extends Mock implements AgendaRepository {}

class _MockFinancialRepo extends Mock implements FinancialRepository {}

/// Fluxo ponta a ponta com dados fictícios: modo avião, criar paciente,
/// consulta vinculada, evolução, reconectar e conferir o "servidor".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeRemote remote;
  late FakeConnectivityMonitorHolder net;
  late OfflineSession session;
  late FakeStoreProvider provider;
  late PatientRepositoryOffline patients;
  late AgendaRepositoryOffline agenda;
  late FinancialRepositoryOffline financial;

  setUp(() async {
    remote = FakeRemote();
    net = FakeConnectivityMonitorHolder();
    provider = FakeStoreProvider();
    session = OfflineSession(
      vault: InMemoryKeyVault(),
      remote: remote,
      monitor: net.monitor,
      currentUserId: () => testUser,
      provider: provider,
      autoSync: false,
    );
    patients = PatientRepositoryOffline(session, _MockPatientRepo());
    agenda = AgendaRepositoryOffline(session, _MockAgendaRepo(), remote);
    financial = FinancialRepositoryOffline(session, _MockFinancialRepo());
  });

  tearDown(() => session.dispose());

  Patient fictional(String id, String name) => Patient(
    id: id,
    createdAt: DateTime.utc(2026, 10, 17, 9),
    personalInfo: PersonalInfo(name: name),
  );

  Future<void> idle() => Future<void>.delayed(const Duration(milliseconds: 20));

  test('first open offline (never synced) fails with a network failure, '
      'never hangs', () async {
    net.monitor.online = false;
    await session.onUser(testUser);
    final result = await patients.getAll();
    expect(result, isA<Error<List<Patient>>>());
    expect((result as Error).failure, isA<NetworkFailure>());
  });

  test('airplane-mode day: patient + linked appointment + progress note, '
      'then reconnect', () async {
    // Dia 1, com internet: sincroniza e vê a lista vazia.
    await session.onUser(testUser);
    expect((await patients.getAll() as Success<List<Patient>>).data, isEmpty);

    // Modo avião.
    net.monitor.online = false;
    final p = fictional('p1', 'Maria Ficticia');
    expect(await patients.add(p), isA<Success<void>>());
    final appt = Appointment(
      id: 'a1',
      date: DateTime(2026, 10, 20),
      time: const TimeOfDay(hour: 9, minute: 30),
      patientName: 'Maria Ficticia',
      patientId: 'p1',
    );
    expect(await agenda.add(appt), isA<Success<void>>());
    final entry = EvolutionEntry(
      id: 'e1',
      patientId: 'p1',
      date: DateTime(2026, 10, 17),
      description: 'Sessao ficticia de teste',
    );
    expect(await patients.addEvolution(entry), isA<Success<void>>());

    // Tudo visível localmente, nada no servidor.
    expect(
      (await patients.getAll() as Success<List<Patient>>).data.single.id,
      'p1',
    );
    expect(
      (await agenda.getAll() as Success<List<Appointment>>).data.single.id,
      'a1',
    );
    expect(
      (await patients.getEvolutions('p1') as Success<List<EvolutionEntry>>)
          .data
          .single
          .description,
      'Sessao ficticia de teste',
    );
    expect(remote.table('patients'), isEmpty);
    expect(session.unsyncedCount, 3);

    // "Fechar e reabrir o app": mesmo banco, a fila continua.
    final store = provider.opened[testUser]!;
    expect(store.liveOps().length, 3);

    // Internet volta.
    net.monitor.online = true;
    await session.active!.engine.sync(force: true);
    expect(remote.table('patients').keys, ['p1']);
    expect(remote.table('appointments')['a1']!['patient_id'], 'p1');
    expect(remote.table('evolution_entries')['e1']!['patient_id'], 'p1');
    expect(session.unsyncedCount, 0);

    // Sincronizar de novo não duplica nada.
    await session.active!.engine.sync(force: true);
    expect(remote.table('patients').length, 1);
    expect(remote.table('appointments').length, 1);
    expect(remote.table('evolution_entries').length, 1);
  });

  test('offline edit of an appointment status and reschedule are kept and '
      'sent once', () async {
    remote.seed('patients', {'id': 'p1', 'name': 'X'});
    remote.seed('appointments', {
      'id': 'a1',
      'date': '2026-10-20',
      'time': '09:00:00',
      'patient_name': 'X',
      'patient_id': 'p1',
      'status': 'scheduled',
    });
    await session.onUser(testUser);
    await agenda.getAll();
    net.monitor.online = false;
    await agenda.updateStatus('a1', AppointmentStatus.confirmed);
    final list = (await agenda.getAll() as Success<List<Appointment>>).data;
    expect(list.single.status, AppointmentStatus.confirmed);

    net.monitor.online = true;
    await session.active!.engine.sync(force: true);
    expect(remote.table('appointments')['a1']!['status'], 'confirmed');
    expect(remote.calls.where((c) => c == 'update appointments').length, 1);
  });

  test('editing a record with an open conflict is refused', () async {
    remote.seed('patients', {
      'id': 'p1',
      'name': 'Original',
      'created_at': '2026-10-17T09:00:00+00:00',
    });
    await session.onUser(testUser);
    await patients.getAll();
    final base =
        (await patients.getAll() as Success<List<Patient>>).data.single;
    await patients.update(
      base.copyWith(personalInfo: const PersonalInfo(name: 'Local')),
    );
    remote.table('patients')['p1']!['name'] = 'Remoto';
    await session.active!.engine.sync(force: true);

    final result = await patients.update(
      base.copyWith(personalInfo: const PersonalInfo(name: 'Outra')),
    );
    expect((result as Error).failure, isA<SyncConflictFailure>());
  });

  test('financial entry offline roundtrip', () async {
    await session.onUser(testUser);
    await financial.getAll();
    net.monitor.online = false;
    final entry = FinancialEntry(
      id: 'f1',
      patientName: 'Maria Ficticia',
      date: DateTime(2026, 10, 17),
      amount: 150,
    );
    await financial.add(entry);
    expect(
      (await financial.getAll() as Success<List<FinancialEntry>>).data.length,
      1,
    );
    net.monitor.online = true;
    await session.active!.engine.sync(force: true);
    expect(remote.table('financial_entries')['f1']!['amount'], 150);
    await idle();
  });

  test(
    'without a local store (web) repositories fall back to the remote',
    () async {
      final fallback = _MockPatientRepo();
      when(fallback.getAll).thenAnswer((_) async => const Success(<Patient>[]));
      final web = PatientRepositoryOffline(
        OfflineSession(
          vault: InMemoryKeyVault(),
          remote: remote,
          monitor: net.monitor,
          currentUserId: () => testUser,
          provider: provider,
          enabled: false,
        ),
        fallback,
      );
      expect(await web.getAll(), isA<Success<List<Patient>>>());
      verify(fallback.getAll).called(1);
    },
  );
}
