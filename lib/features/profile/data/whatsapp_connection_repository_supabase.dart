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
}
