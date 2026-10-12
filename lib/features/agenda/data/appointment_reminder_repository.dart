import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/agenda/domain/entities/appointment_reminder.dart';

/// Lembretes do WhatsApp de uma consulta. Só LEITURA, com a sessão normal da
/// profissional: a RLS de `whatsapp_messages` limita às próprias linhas. Só
/// as colunas de status/tempo são pedidas (nunca telefone, wamid ou erro).
abstract class AppointmentReminderRepository {
  Future<Result<List<AppointmentReminder>>> remindersFor(String appointmentId);
}

class AppointmentReminderRepositorySupabase
    implements AppointmentReminderRepository {
  AppointmentReminderRepositorySupabase(this._client);

  final SupabaseClient _client;

  static const _columns =
      'reminder_type,status,scheduled_for,sent_at,delivered_at,read_at,failed_at,created_at';

  @override
  Future<Result<List<AppointmentReminder>>> remindersFor(
    String appointmentId,
  ) async {
    try {
      final rows = await _client
          .from('whatsapp_messages')
          .select(_columns)
          .eq('appointment_id', appointmentId)
          .order('created_at', ascending: false)
          .limit(10)
          .timeout(const Duration(seconds: 10));
      return Success(
        latestRemindersByType(
          rows.map((row) => AppointmentReminder.fromJson(row)).toList(),
        ),
      );
    } on TimeoutException {
      return Error(NetworkFailure());
    } on PostgrestException catch (e) {
      debugPrint('[AppointmentReminderRepository] code=${e.code}');
      return Error(ServerFailure());
    } catch (_) {
      return Error(UnexpectedFailure());
    }
  }
}
