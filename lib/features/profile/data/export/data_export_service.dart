import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

/// Origem dos dados da exportação. Abstração para que o serviço seja testável
/// sem rede: a implementação real fala com o Supabase.
abstract class ExportDataSource {
  /// Contagem EXATA de linhas da tabela (do dono autenticado).
  Future<int> countRows(String table);

  /// Página [from]..[to] (inclusive) em ordem estável por `id`.
  Future<List<Map<String, dynamic>>> fetchPage(String table, int from, int to);

  /// Todos os caminhos de objetos do bucket de anexos do usuário, paginados.
  Future<List<String>> listAttachmentPaths();

  Future<Uint8List> downloadAttachment(String path);

  /// Alterações locais ainda não enviadas ao servidor (fila offline).
  Future<int> pendingLocalChanges();
}

/// Falha da exportação. A mensagem NUNCA carrega dado de paciente: só nomes de
/// tabela, contagens e códigos.
class ExportException implements Exception {
  const ExportException(this.code, [this.detail = '']);

  final ExportFailureCode code;
  final String detail;

  @override
  String toString() =>
      'ExportException($code${detail.isEmpty ? '' : ': $detail'})';
}

enum ExportFailureCode {
  /// Há alterações offline não sincronizadas: o servidor ainda não tem tudo.
  pendingLocalChanges,

  /// Número de linhas lidas difere da contagem do servidor.
  incompleteTable,

  /// Os dados mudaram enquanto a exportação rodava.
  changedDuringExport,

  /// Falha ao listar ou baixar anexos.
  attachmentFailure,

  /// O pacote gerado não confere com o próprio manifesto.
  verificationFailed,

  /// O servidor não confirmou que as contagens batem.
  serverCountMismatch,

  /// Falha de rede/servidor ao ler dados.
  sourceFailure,
}

class ExportPackage {
  const ExportPackage({
    required this.bytes,
    required this.fileName,
    required this.manifestSha256,
    required this.counts,
  });

  final Uint8List bytes;
  final String fileName;

  /// SHA-256 do `manifest.json` (vai no recibo enviado ao servidor).
  final String manifestSha256;

  /// Contagens por categoria, mesmas chaves de `account_data_counts` no SQL.
  final Map<String, int> counts;
}

/// Monta o pacote ZIP de exportação e o VERIFICA antes de entregá-lo.
///
/// Garantias (e limites) estão em docs/privacy/DATA_EXPORT.md. Resumo: leitura
/// paginada com conferência de contagem antes e depois, anexos baixados com
/// nova tentativa e checksum SHA-256, releitura do ZIP gerado contra o
/// manifesto. Qualquer inconsistência aborta SEM entregar pacote parcial.
class DataExportService {
  DataExportService(
    this._source, {
    this.pageSize = 500,
    this.downloadAttempts = 3,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ExportDataSource _source;
  final int pageSize;
  final int downloadAttempts;
  final DateTime Function() _now;

  /// Tabelas exportadas, na ordem do pacote.
  static const tables = <String>[
    'profiles',
    'patients',
    'evolution_entries',
    'appointments',
    'financial_entries',
    'attachments',
    'patient_consents',
    'whatsapp_messages',
  ];

  static const _bucketPrefixOrphans = 'attachments/_sem_registro';

  Future<ExportPackage> build() async {
    if (await _guard(_source.pendingLocalChanges) > 0) {
      throw const ExportException(ExportFailureCode.pendingLocalChanges);
    }

    final expected = <String, int>{};
    for (final t in tables) {
      expected[t] = await _guard(() => _source.countRows(t));
    }

    final rows = <String, List<Map<String, dynamic>>>{};
    for (final t in tables) {
      rows[t] = await _readAll(t, expected[t]!);
    }

    final attachmentRows = rows['attachments']!;
    final storagePaths = await _guardAttachment(_source.listAttachmentPaths);
    final referenced = <String>{
      for (final a in attachmentRows) (a['storage_path'] ?? '').toString(),
    };

    final files = <_PackedFile>[];
    final attachmentEntries = <Map<String, Object?>>[];
    for (final a in attachmentRows) {
      final path = (a['storage_path'] ?? '').toString();
      final bytes = await _download(path);
      final zipPath = _attachmentZipPath(a);
      files.add(_PackedFile(zipPath, bytes));
      attachmentEntries.add({
        'id': a['id'],
        'patient_id': a['patient_id'],
        'zip_path': zipPath,
        'storage_path': path,
        'file_name': a['file_name'],
        'content_type': a['content_type'],
        'category': a['category'],
        'created_at': a['created_at'],
        'bytes': bytes.length,
        'sha256': _sha(bytes),
      });
    }

    final orphanEntries = <Map<String, Object?>>[];
    var orphanIndex = 0;
    for (final path in storagePaths.where((p) => !referenced.contains(p))) {
      final bytes = await _download(path);
      orphanIndex++;
      final zipPath =
          '$_bucketPrefixOrphans/${orphanIndex}_${_safeName(path.split('/').last)}';
      files.add(_PackedFile(zipPath, bytes));
      orphanEntries.add({
        'zip_path': zipPath,
        'storage_path': path,
        'bytes': bytes.length,
        'sha256': _sha(bytes),
      });
    }

    // Os dados não podem ter mudado enquanto lemos: reconta tudo.
    for (final t in tables) {
      final now = await _guard(() => _source.countRows(t));
      if (now != expected[t]) {
        throw ExportException(ExportFailureCode.changedDuringExport, t);
      }
    }
    final storageNow = await _guardAttachment(_source.listAttachmentPaths);
    if (storageNow.length != storagePaths.length) {
      throw const ExportException(
        ExportFailureCode.changedDuringExport,
        'storage',
      );
    }

    final tableEntries = <String, Object?>{};
    for (final t in tables) {
      final bytes = _jsonBytes(rows[t]!);
      final path = 'data/$t.json';
      files.add(_PackedFile(path, bytes));
      tableEntries[t] = {
        'file': path,
        'rows': rows[t]!.length,
        'sha256': _sha(bytes),
      };
    }

    final counts = <String, int>{
      for (final t in tables.where((t) => t != 'profiles')) t: rows[t]!.length,
      'storage_attachments': storagePaths.length,
    };

    final generatedAt = _now().toUtc();
    final manifest = <String, Object?>{
      'format': 'la-pelve-export',
      'format_version': 1,
      'generated_at': generatedAt.toIso8601String(),
      'complete': true,
      'tables': tableEntries,
      'attachments': attachmentEntries,
      'orphan_files': orphanEntries,
      'counts': counts,
    };
    final manifestBytes = _jsonBytes(manifest);
    final readme = utf8.encode(_readme(generatedAt));

    final archive = Archive();
    for (final f in files) {
      archive.add(ArchiveFile.bytes(f.path, f.bytes));
    }
    archive.add(ArchiveFile.bytes('manifest.json', manifestBytes));
    archive.add(ArchiveFile.bytes('LEIA-ME.txt', readme));
    final zipBytes = ZipEncoder().encodeBytes(archive);

    _verify(zipBytes, manifest, manifestBytes);

    return ExportPackage(
      bytes: zipBytes,
      fileName: 'la-pelve-exportacao-${_stamp(generatedAt)}.zip',
      manifestSha256: _sha(manifestBytes),
      counts: counts,
    );
  }

  Future<List<Map<String, dynamic>>> _readAll(
    String table,
    int expected,
  ) async {
    final out = <Map<String, dynamic>>[];
    var from = 0;
    while (true) {
      final page = await _guard(
        () => _source.fetchPage(table, from, from + pageSize - 1),
      );
      out.addAll(page);
      if (page.length < pageSize) break;
      from += pageSize;
    }
    final ids = out.map((r) => r['id']).toSet();
    if (out.length != expected || ids.length != out.length) {
      throw ExportException(ExportFailureCode.incompleteTable, table);
    }
    return out;
  }

  Future<Uint8List> _download(String path) async {
    Object? last;
    for (var i = 0; i < downloadAttempts; i++) {
      try {
        final bytes = await _source.downloadAttachment(path);
        return bytes;
      } catch (e) {
        last = e;
      }
    }
    // Sem o caminho/nome do arquivo na mensagem: pode identificar paciente.
    throw ExportException(
      ExportFailureCode.attachmentFailure,
      'download (${last.runtimeType})',
    );
  }

  void _verify(
    Uint8List zipBytes,
    Map<String, Object?> manifest,
    Uint8List manifestBytes,
  ) {
    final decoded = ZipDecoder().decodeBytes(zipBytes);
    final byName = {for (final f in decoded) f.name: f.readBytes()};

    void expectFile(String path, String sha, [int? bytes]) {
      final got = byName[path];
      if (got == null ||
          _sha(got) != sha ||
          (bytes != null && got.length != bytes)) {
        throw const ExportException(
          ExportFailureCode.verificationFailed,
          'arquivo do pacote',
        );
      }
    }

    final tables = manifest['tables']! as Map<String, Object?>;
    for (final e in tables.values) {
      final m = e! as Map<String, Object?>;
      expectFile(m['file']! as String, m['sha256']! as String);
    }
    for (final key in ['attachments', 'orphan_files']) {
      for (final e in manifest[key]! as List<Object?>) {
        final m = e! as Map<String, Object?>;
        expectFile(
          m['zip_path']! as String,
          m['sha256']! as String,
          m['bytes']! as int,
        );
      }
    }
    final manifestInZip = byName['manifest.json'];
    if (manifestInZip == null || _sha(manifestInZip) != _sha(manifestBytes)) {
      throw const ExportException(
        ExportFailureCode.verificationFailed,
        'manifest',
      );
    }
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on ExportException {
      rethrow;
    } catch (e) {
      throw ExportException(
        ExportFailureCode.sourceFailure,
        e.runtimeType.toString(),
      );
    }
  }

  Future<T> _guardAttachment<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      throw ExportException(
        ExportFailureCode.attachmentFailure,
        'storage (${e.runtimeType})',
      );
    }
  }

  String _attachmentZipPath(Map<String, dynamic> a) {
    final patient = _safeName((a['patient_id'] ?? 'sem_paciente').toString());
    final id = _safeName((a['id'] ?? '').toString());
    final name = _safeName((a['file_name'] ?? '').toString());
    return 'attachments/$patient/${id}_$name';
  }

  static String _safeName(String s) {
    final cleaned = s.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_');
    return cleaned.isEmpty ? 'arquivo' : cleaned;
  }

  static String _sha(List<int> bytes) => sha256.convert(bytes).toString();

  static Uint8List _jsonBytes(Object? value) => Uint8List.fromList(
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value)),
  );

  static String _stamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }

  String _readme(DateTime generatedAt) =>
      '''La Pelve - exportacao de dados
Gerado em: ${generatedAt.toIso8601String()} (UTC)

Conteudo:
- manifest.json: lista cada arquivo do pacote com tamanho e SHA-256, e as contagens por categoria.
- data/*.json: uma tabela por arquivo (pacientes com anamnese, evolucoes, agenda, financeiro,
  consentimentos, mensagens de lembrete e perfil). Os campos seguem os nomes do banco do La Pelve.
- attachments/<id do paciente>/: fotos e documentos originais, sem alteracao. A tabela
  data/attachments.json liga cada arquivo ao paciente.
- attachments/_sem_registro/: arquivos que estavam no armazenamento sem registro correspondente.

Conferencia: calcule o SHA-256 de cada arquivo e compare com manifest.json. Este pacote contem dados
pessoais sensiveis de saude: guarde em local seguro e com acesso restrito.
Este arquivo nao substitui a analise juridica sobre guarda de prontuarios.
''';
}

class _PackedFile {
  _PackedFile(this.path, this.bytes);
  final String path;
  final Uint8List bytes;
}
