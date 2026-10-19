import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pelve/features/profile/data/export/data_export_service.dart';

class _FakeSource implements ExportDataSource {
  _FakeSource({
    Map<String, List<Map<String, dynamic>>>? rows,
    Map<String, Uint8List>? files,
  }) : rows = rows ?? _defaultRows(),
       files =
           files ??
           {
             'u1/p1/a1_foto.jpg': Uint8List.fromList([1, 2, 3]),
           };

  Map<String, List<Map<String, dynamic>>> rows;
  Map<String, Uint8List> files;
  int pending = 0;
  int downloadFailures = 0; // falhas antes de funcionar
  bool failDownloadsForever = false;
  bool failList = false;
  bool failFetch = false;
  int? countOverride; // para patients
  void Function()? onFirstDownload;
  final downloaded = <String>[];

  static Map<String, List<Map<String, dynamic>>> _defaultRows() => {
    'profiles': [
      {'id': 'u1', 'name': 'Dra. Teste'},
    ],
    'patients': [
      for (var i = 0; i < 5; i++) {'id': 'p$i', 'name': 'Paciente $i'},
    ],
    'evolution_entries': [
      {'id': 'e1', 'patient_id': 'p0'},
    ],
    'appointments': [
      {'id': 'g1'},
    ],
    'financial_entries': [
      {'id': 'f1', 'patient_id': 'p0'},
    ],
    'attachments': [
      {
        'id': 'a1',
        'patient_id': 'p1',
        'storage_path': 'u1/p1/a1_foto.jpg',
        'file_name': 'foto.jpg',
        'content_type': 'image/jpeg',
        'category': 'outro',
      },
    ],
    'patient_consents': [
      {'id': 'c1'},
    ],
    'whatsapp_messages': <Map<String, dynamic>>[],
  };

  @override
  Future<int> countRows(String table) async {
    if (table == 'patients' && countOverride != null) return countOverride!;
    return rows[table]!.length;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPage(
    String table,
    int from,
    int to,
  ) async {
    if (failFetch) throw StateError('rede');
    final all = rows[table]!;
    if (from >= all.length) return [];
    return all.sublist(from, (to + 1).clamp(0, all.length));
  }

  @override
  Future<List<String>> listAttachmentPaths() async {
    if (failList) throw StateError('storage');
    return files.keys.toList();
  }

  @override
  Future<Uint8List> downloadAttachment(String path) async {
    onFirstDownload?.call();
    onFirstDownload = null;
    if (failDownloadsForever) throw StateError('falha $path');
    if (downloadFailures > 0) {
      downloadFailures--;
      throw StateError('transitória');
    }
    downloaded.add(path);
    final f = files[path];
    if (f == null) throw StateError('inexistente');
    return f;
  }

  @override
  Future<int> pendingLocalChanges() async => pending;
}

DataExportService _service(_FakeSource s, {int pageSize = 2}) =>
    DataExportService(
      s,
      pageSize: pageSize,
      now: () => DateTime.utc(2026, 10, 19, 12),
    );

Future<void> _expectCode(
  Future<Object?> Function() body,
  ExportFailureCode code,
) async {
  try {
    await body();
    fail('deveria falhar com $code');
  } on ExportException catch (e) {
    expect(e.code, code);
    // A mensagem não pode vazar dado de paciente.
    expect(e.toString().contains('Paciente'), isFalse);
    expect(e.toString().contains('foto.jpg'), isFalse);
  }
}

void main() {
  test(
    'pacote completo: dados paginados, anexos originais, manifesto e checksums',
    () async {
      final pkg = await _service(_FakeSource()).build();

      final zip = ZipDecoder().decodeBytes(pkg.bytes);
      final names = zip.map((f) => f.name).toSet();
      expect(
        names,
        containsAll([
          'manifest.json',
          'LEIA-ME.txt',
          'data/patients.json',
          'data/evolution_entries.json',
          'data/appointments.json',
          'data/financial_entries.json',
          'data/attachments.json',
          'data/patient_consents.json',
          'attachments/p1/a1_foto.jpg',
        ]),
      );

      final patients =
          jsonDecode(
                utf8.decode(
                  zip
                      .firstWhere((f) => f.name == 'data/patients.json')
                      .readBytes()!,
                ),
              )
              as List;
      expect(
        patients,
        hasLength(5),
      ); // 5 linhas com páginas de 2: nenhuma perdida

      final att = zip
          .firstWhere((f) => f.name == 'attachments/p1/a1_foto.jpg')
          .readBytes()!;
      expect(att, [1, 2, 3]); // byte a byte

      final manifestBytes = zip
          .firstWhere((f) => f.name == 'manifest.json')
          .readBytes()!;
      expect(sha256.convert(manifestBytes).toString(), pkg.manifestSha256);
      final manifest =
          jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>;
      expect(manifest['complete'], isTrue);
      final entry =
          (manifest['attachments'] as List).single as Map<String, dynamic>;
      expect(entry['sha256'], sha256.convert([1, 2, 3]).toString());
      expect(pkg.counts['patients'], 5);
      expect(pkg.counts['storage_attachments'], 1);
      expect(pkg.fileName, 'la-pelve-exportacao-20261019-120000.zip');
    },
  );

  test('conta sem anexos exporta normalmente', () async {
    final s = _FakeSource(files: {});
    s.rows['attachments'] = [];
    final pkg = await _service(s).build();
    expect(pkg.counts['attachments'], 0);
    expect(pkg.counts['storage_attachments'], 0);
  });

  test('arquivo no Storage sem linha (órfão) é incluído e contado', () async {
    final s = _FakeSource();
    s.files['u1/p9/orfao.pdf'] = Uint8List.fromList([9]);
    final pkg = await _service(s).build();
    final names = ZipDecoder().decodeBytes(pkg.bytes).map((f) => f.name);
    expect(
      names.any((n) => n.startsWith('attachments/_sem_registro/')),
      isTrue,
    );
    expect(pkg.counts['storage_attachments'], 2);
  });

  test('alterações offline não sincronizadas bloqueiam a exportação', () async {
    final s = _FakeSource()..pending = 2;
    await _expectCode(_service(s).build, ExportFailureCode.pendingLocalChanges);
  });

  test(
    'exportação incompleta: menos linhas lidas que a contagem do servidor',
    () async {
      final s = _FakeSource()..countOverride = 6;
      await _expectCode(_service(s).build, ExportFailureCode.incompleteTable);
    },
  );

  test('falha durante a leitura não gera pacote', () async {
    final s = _FakeSource()..failFetch = true;
    await _expectCode(_service(s).build, ExportFailureCode.sourceFailure);
  });

  test('falha de Storage ao listar aborta', () async {
    final s = _FakeSource()..failList = true;
    await _expectCode(_service(s).build, ExportFailureCode.attachmentFailure);
  });

  test(
    'falha transitória no download de anexo é repetida e funciona',
    () async {
      final s = _FakeSource()..downloadFailures = 2;
      final pkg = await _service(s).build();
      expect(pkg.counts['attachments'], 1);
    },
  );

  test('anexo que nunca baixa aborta sem entregar pacote parcial', () async {
    final s = _FakeSource()..failDownloadsForever = true;
    await _expectCode(_service(s).build, ExportFailureCode.attachmentFailure);
  });

  test('dados que mudam durante a exportação são detectados', () async {
    final s = _FakeSource();
    s.onFirstDownload = () => s.rows['patients']!.add({'id': 'novo'});
    await _expectCode(_service(s).build, ExportFailureCode.changedDuringExport);
  });

  test('ids duplicados na leitura contam como incompleto', () async {
    final s = _FakeSource();
    s.rows['patients'] = [
      {'id': 'x'},
      {'id': 'x'},
    ];
    await _expectCode(_service(s).build, ExportFailureCode.incompleteTable);
  });

  test('nomes de arquivo perigosos não escapam da pasta do paciente', () async {
    final s = _FakeSource();
    s.rows['attachments']![0]['file_name'] = '../../etc/passwd';
    final pkg = await _service(s).build();
    final names = ZipDecoder().decodeBytes(pkg.bytes).map((f) => f.name);
    expect(names.any((n) => n.split('/').contains('..')), isFalse);
    expect(names.any((n) => n.startsWith('attachments/p1/a1_')), isTrue);
  });
}
