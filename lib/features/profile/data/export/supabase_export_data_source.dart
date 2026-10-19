import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:la_pelve/features/profile/data/export/data_export_service.dart';

class SupabaseExportDataSource implements ExportDataSource {
  SupabaseExportDataSource(
    this._client, {
    required Future<int> Function() pendingLocalChanges,
  }) : _pending = pendingLocalChanges;

  final SupabaseClient _client;
  final Future<int> Function() _pending;

  static const _bucket = 'patient-attachments';
  static const _listPage = 100;

  @override
  Future<int> countRows(String table) => _client.from(table).count();

  @override
  Future<List<Map<String, dynamic>>> fetchPage(
    String table,
    int from,
    int to,
  ) async {
    final rows = await _client
        .from(table)
        .select()
        .order('id', ascending: true)
        .range(from, to);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<List<String>> listAttachmentPaths() async {
    final userId = _client.auth.currentUser!.id;
    final paths = <String>[];
    final folders = await _listAll(userId);
    for (final entry in folders) {
      if (entry.id == null) {
        for (final file in await _listAll('$userId/${entry.name}')) {
          if (file.id != null) paths.add('$userId/${entry.name}/${file.name}');
        }
      } else {
        paths.add('$userId/${entry.name}');
      }
    }
    return paths;
  }

  Future<List<FileObject>> _listAll(String path) async {
    final out = <FileObject>[];
    var offset = 0;
    while (true) {
      final page = await _client.storage
          .from(_bucket)
          .list(
            path: path,
            searchOptions: SearchOptions(limit: _listPage, offset: offset),
          );
      out.addAll(page);
      if (page.length < _listPage) return out;
      offset += _listPage;
    }
  }

  @override
  Future<Uint8List> downloadAttachment(String path) =>
      _client.storage.from(_bucket).download(path);

  @override
  Future<int> pendingLocalChanges() => _pending();
}
