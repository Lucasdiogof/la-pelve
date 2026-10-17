import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/offline/offline_repository_support.dart';
import 'package:la_pelve/core/offline/offline_session.dart';
import 'package:la_pelve/core/offline/sync/entity_config.dart';
import 'package:la_pelve/features/patients/domain/entities/evolution_entry.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_repository.dart';

/// Pacientes e evoluções offline-first sobre o espelho local cifrado.
/// [_remote] é o repositório Supabase de antes: usado só quando não há
/// armazenamento local (Web, falha de Keystore).
class PatientRepositoryOffline implements PatientRepository {
  PatientRepositoryOffline(this._session, this._remote);

  final OfflineSession _session;
  final PatientRepository _remote;

  static final _patients = patientsConfig.kind;
  static final _evolutions = evolutionsConfig.kind;

  @override
  Future<Result<List<Patient>>> getAll() => offlineRead(
    session: _session,
    kind: _patients,
    fallback: _remote.getAll,
    read: (store) {
      final records = store.listRecords(_patients)
        ..sort(
          (a, b) => '${a.data['created_at']}'.compareTo(
            '${b.data['created_at']}',
          ),
        );
      return [for (final r in records) Patient.fromJson(asJson(r.data))];
    },
  );

  @override
  Future<Result<void>> add(Patient patient) => offlineWrite(
    session: _session,
    fallback: () => _remote.add(patient),
    body: (w) => w.create(_patients, patient.toJson()),
  );

  @override
  Future<Result<void>> update(Patient patient) => offlineWrite(
    session: _session,
    fallback: () => _remote.update(patient),
    body: (w) {
      final record = w.context.store.getRecord(_patients, patient.id);
      w.update(
        _patients,
        patient.id,
        patient.toJson(),
        current: record == null
            ? null
            : Patient.fromJson(asJson(record.data)).toJson(),
      );
    },
  );

  @override
  Future<Result<void>> delete(String id) => offlineWrite(
    session: _session,
    fallback: () => _remote.delete(id),
    body: (w) => w.delete(_patients, id),
  );

  @override
  Future<Result<List<EvolutionEntry>>> getEvolutions(String patientId) =>
      offlineRead(
        session: _session,
        kind: _evolutions,
        fallback: () => _remote.getEvolutions(patientId),
        read: (store) {
          final records =
              store
                  .listRecords(_evolutions)
                  .where((r) => r.data['patient_id'] == patientId)
                  .toList()
                ..sort((a, b) {
                  final byDate = '${a.data['date']}'.compareTo(
                    '${b.data['date']}',
                  );
                  return byDate != 0
                      ? byDate
                      : '${a.data['created_at']}'.compareTo(
                          '${b.data['created_at']}',
                        );
                });
          return [
            for (final r in records) EvolutionEntry.fromJson(asJson(r.data)),
          ];
        },
      );

  @override
  Future<Result<void>> addEvolution(EvolutionEntry entry) => offlineWrite(
    session: _session,
    fallback: () => _remote.addEvolution(entry),
    body: (w) => w.create(_evolutions, entry.toJson()),
  );

  @override
  Future<Result<void>> updateEvolution(EvolutionEntry entry) => offlineWrite(
    session: _session,
    fallback: () => _remote.updateEvolution(entry),
    body: (w) {
      final record = w.context.store.getRecord(_evolutions, entry.id);
      w.update(
        _evolutions,
        entry.id,
        entry.toJson(),
        current: record == null
            ? null
            : EvolutionEntry.fromJson(asJson(record.data)).toJson(),
      );
    },
  );

  @override
  Future<Result<void>> deleteEvolution(String id) => offlineWrite(
    session: _session,
    fallback: () => _remote.deleteEvolution(id),
    body: (w) => w.delete(_evolutions, id),
  );
}
