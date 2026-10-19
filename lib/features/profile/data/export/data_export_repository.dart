import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:la_pelve/features/profile/data/export/data_export_service.dart';

/// Resultado de preparar a exportação: o pacote só existe se o servidor
/// confirmou que as contagens do pacote batem com as dele.
class PreparedExport {
  const PreparedExport(this.package);
  final ExportPackage package;
}

class DataExportRepository {
  DataExportRepository(this._client, this._service);

  final SupabaseClient _client;
  final DataExportService _service;

  /// Gera e verifica o pacote e registra o recibo no servidor.
  /// Lança [ExportException]; nunca devolve pacote não confirmado.
  Future<PreparedExport> prepare() async {
    final package = await _service.build();
    try {
      final receipt = await _client.rpc<dynamic>(
        'record_data_export',
        params: {
          'p_manifest_sha256': package.manifestSha256,
          'p_counts': package.counts,
        },
      );
      if (receipt is Map && receipt['matches'] == true) {
        return PreparedExport(package);
      }
      throw const ExportException(ExportFailureCode.serverCountMismatch);
    } on ExportException {
      rethrow;
    } on PostgrestException catch (e) {
      debugPrint('[DataExportRepository.prepare] code=${e.code}');
      throw const ExportException(ExportFailureCode.sourceFailure, 'receipt');
    }
  }
}
