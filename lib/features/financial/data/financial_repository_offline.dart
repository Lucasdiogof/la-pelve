import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/offline/offline_repository_support.dart';
import 'package:la_pelve/core/offline/offline_session.dart';
import 'package:la_pelve/core/offline/sync/entity_config.dart';
import 'package:la_pelve/features/financial/domain/entities/financial_entry.dart';
import 'package:la_pelve/features/financial/domain/repositories/financial_repository.dart';

class FinancialRepositoryOffline implements FinancialRepository {
  FinancialRepositoryOffline(this._session, this._remote);

  final OfflineSession _session;
  final FinancialRepository _remote;

  static final _kind = financialConfig.kind;

  @override
  Future<Result<List<FinancialEntry>>> getAll() => offlineRead(
    session: _session,
    kind: _kind,
    fallback: _remote.getAll,
    read: (store) {
      final records = store.listRecords(_kind)
        ..sort((a, b) => '${a.data['date']}'.compareTo('${b.data['date']}'));
      return [for (final r in records) FinancialEntry.fromJson(asJson(r.data))];
    },
  );

  @override
  Future<Result<void>> add(FinancialEntry entry) => offlineWrite(
    session: _session,
    fallback: () => _remote.add(entry),
    body: (w) => w.create(_kind, entry.toJson()),
  );

  @override
  Future<Result<void>> update(FinancialEntry entry) => offlineWrite(
    session: _session,
    fallback: () => _remote.update(entry),
    body: (w) {
      final record = w.context.store.getRecord(_kind, entry.id);
      w.update(
        _kind,
        entry.id,
        entry.toJson(),
        current: record == null
            ? null
            : FinancialEntry.fromJson(asJson(record.data)).toJson(),
      );
    },
  );

  @override
  Future<Result<void>> delete(String id) => offlineWrite(
    session: _session,
    fallback: () => _remote.delete(id),
    body: (w) => w.delete(_kind, id),
  );
}
