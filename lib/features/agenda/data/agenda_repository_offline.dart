import 'dart:async';

import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/offline/offline_repository_support.dart';
import 'package:la_pelve/core/offline/offline_session.dart';
import 'package:la_pelve/core/offline/sync/entity_config.dart';
import 'package:la_pelve/core/offline/sync/remote_gateway.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment_status.dart';
import 'package:la_pelve/features/agenda/domain/repositories/agenda_repository.dart';

/// Agenda offline-first. O Realtime continua: cada foto que chega do servidor
/// (ex.: confirmação por WhatsApp) é aplicada ao espelho local, preservando
/// o que ainda está pendente de envio, e a tela lê sempre o espelho.
class AgendaRepositoryOffline implements AgendaRepository {
  AgendaRepositoryOffline(this._session, this._remote, this._gateway);

  final OfflineSession _session;
  final AgendaRepository _remote;
  final RemoteGateway _gateway;

  static final _kind = appointmentsConfig.kind;

  List<Appointment> _readAll(OfflineContext ctx) {
    final appointments = [
      for (final r in ctx.store.listRecords(_kind))
        Appointment.fromJson(asJson(r.data)),
    ];
    appointments.sort((a, b) {
      final dateOrder = a.date.compareTo(b.date);
      if (dateOrder != 0) return dateOrder;
      return (a.time.hour * 60 + a.time.minute).compareTo(
        b.time.hour * 60 + b.time.minute,
      );
    });
    return appointments;
  }

  @override
  Stream<List<Appointment>> watchAllForUser(String userId) {
    // Fechado pelo consumidor ao cancelar a assinatura (onCancel).
    // ignore: close_sinks
    late final StreamController<List<Appointment>> controller;
    StreamSubscription<Set<String>>? dataSub;
    StreamSubscription<List<Map<String, Object?>>>? remoteSub;
    var cancelled = false;

    Future<void> start() async {
      final ctx = await _session.context();
      if (cancelled || controller.isClosed) return;
      if (ctx == null) {
        remoteSub = null;
        await controller.addStream(_remote.watchAllForUser(userId));
        return;
      }
      dataSub = _session.dataChanged.where((k) => k.contains(_kind)).listen((
        _,
      ) {
        if (!controller.isClosed) controller.add(_readAll(ctx));
      });
      remoteSub = _gateway
          .watch(appointmentsConfig, userId)
          .listen(
            (rows) => ctx.engine.applyExternalSnapshot(_kind, rows),
            // Offline: o espelho local segue válido; a sincronização
            // periódica e a reconexão cuidam do resto.
            onError: (Object _) {},
          );
    }

    controller = StreamController<List<Appointment>>(
      onListen: () => unawaited(start()),
      onCancel: () async {
        cancelled = true;
        await dataSub?.cancel();
        await remoteSub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<Result<List<Appointment>>> getAll() => offlineRead(
    session: _session,
    kind: _kind,
    fallback: _remote.getAll,
    read: (store) => _readAll(_session.active!),
  );

  @override
  Future<Result<void>> add(Appointment appointment) => offlineWrite(
    session: _session,
    fallback: () => _remote.add(appointment),
    body: (w) => w.create(_kind, appointment.toJson()),
  );

  @override
  Future<Result<void>> update(Appointment appointment) => offlineWrite(
    session: _session,
    fallback: () => _remote.update(appointment),
    body: (w) {
      final record = w.context.store.getRecord(_kind, appointment.id);
      // Status tem fluxo próprio (updateStatus), como no repositório remoto.
      final full = appointment.toJson()..remove('status');
      final current = record == null
          ? null
          : (Appointment.fromJson(asJson(record.data)).toJson()
              ..remove('status'));
      w.update(_kind, appointment.id, full, current: current);
    },
  );

  @override
  Future<Result<void>> delete(String id) => offlineWrite(
    session: _session,
    fallback: () => _remote.delete(id),
    body: (w) => w.delete(_kind, id),
  );

  @override
  Future<Result<void>> updateStatus(String id, AppointmentStatus status) =>
      offlineWrite(
        session: _session,
        fallback: () => _remote.updateStatus(id, status),
        body: (w) => w.updatePatch(_kind, id, {'status': status.name}),
      );
}
