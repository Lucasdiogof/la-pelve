import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/profile/domain/entities/whatsapp_connection.dart';
import 'package:la_pelve/features/profile/domain/repositories/whatsapp_connection_repository.dart';

/// A consulta nunca pode ficar pendente para sempre.
const Duration _kWhatsappConnectionQueryTimeout = Duration(seconds: 10);

/// Só leitura, de propósito: esta etapa não cria, atualiza nem apaga nada
/// em `whatsapp_connections`. A sessão usada é a `authenticated` normal do
/// profissional — nunca service_role — e é a RLS da tabela (select por
/// `fisioterapeuta_id = auth.uid()`) que garante que cada profissional só
/// veja a própria conexão, sem precisar filtrar por id aqui.
class WhatsappConnectionRepositorySupabase
    implements WhatsappConnectionRepository {
  WhatsappConnectionRepositorySupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<WhatsappConnection?>> getCurrentConnection() async {
    try {
      final row = await _client
          .from('whatsapp_connections')
          .select()
          .maybeSingle()
          .timeout(_kWhatsappConnectionQueryTimeout);
      return Success(row == null ? null : WhatsappConnection.fromJson(row));
    } on TimeoutException catch (e, st) {
      debugPrint(
        '[WhatsappConnectionRepositorySupabase.getCurrentConnection] timeout\n$e\n$st',
      );
      return Error(NetworkFailure());
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[WhatsappConnectionRepositorySupabase.getCurrentConnection] '
        'code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint(
        '[WhatsappConnectionRepositorySupabase.getCurrentConnection] $e\n$st',
      );
      return Error(UnexpectedFailure());
    }
  }

  Future<Map<String, dynamic>> _invoke(String action) async {
    final response = await _client.functions
        .invoke('whatsapp-connect', body: {'action': action})
        .timeout(_kWhatsappConnectionQueryTimeout);
    final data = response.data;
    if (data is! Map<String, dynamic> || data['ok'] != true) {
      throw const FormatException('resposta inesperada');
    }
    return data;
  }

  Future<Result<T>> _guarded<T>(String label, Future<T> Function() body) async {
    try {
      return Success(await body());
    } on TimeoutException catch (e, st) {
      debugPrint(
        '[WhatsappConnectionRepositorySupabase.$label] timeout\n$e\n$st',
      );
      return Error(NetworkFailure());
    } on FunctionException catch (e, st) {
      debugPrint(
        '[WhatsappConnectionRepositorySupabase.$label] status=${e.status}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint(
        '[WhatsappConnectionRepositorySupabase.$label] ${e.runtimeType}\n$st',
      );
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<bool>> isSelfConnectAvailable() => _guarded(
    'isSelfConnectAvailable',
    () async => (await _invoke('availability'))['enabled'] == true,
  );

  @override
  Future<Result<Uri>> startConnection() =>
      _guarded('startConnection', () async {
        final data = await _invoke('start');
        final uri = Uri.tryParse(data['connect_url'] as String? ?? '');
        // Só abre HTTPS: nunca um esquema arbitrário vindo da resposta.
        if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
          throw const FormatException('url inválida');
        }
        return uri;
      });

  @override
  Future<Result<void>> refreshRemoteStatus() =>
      _guarded('refreshRemoteStatus', () => _invoke('status'));

  @override
  Future<Result<void>> disconnect() =>
      _guarded('disconnect', () => _invoke('disconnect'));
}
