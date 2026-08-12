import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/shared/utils/enum_from_name.dart';

enum AttachmentCategory { fichaAvaliacao, documento, imagem, outro }

extension AttachmentCategoryLabel on AttachmentCategory {
  String get label => switch (this) {
    AttachmentCategory.fichaAvaliacao => 'Ficha de avaliação física',
    AttachmentCategory.documento => 'Documento',
    AttachmentCategory.imagem => 'Imagem',
    AttachmentCategory.outro => 'Anexo',
  };
}

class Attachment extends Equatable {
  const Attachment({
    required this.id,
    required this.patientId,
    required this.storagePath,
    required this.fileName,
    required this.contentType,
    required this.category,
    required this.createdAt,
  });

  final String id;
  final String patientId;
  final String storagePath;
  final String fileName;
  final String contentType;
  final AttachmentCategory category;
  final DateTime createdAt;

  bool get isImage => contentType.startsWith('image/');
  bool get isPdf => contentType == 'application/pdf';

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'storage_path': storagePath,
    'file_name': fileName,
    'content_type': contentType,
    'category': category.name,
    'created_at': createdAt.toIso8601String(),
  };

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    storagePath: json['storage_path'] as String,
    fileName: json['file_name'] as String? ?? '',
    contentType: json['content_type'] as String? ?? '',
    category:
        enumFromName(AttachmentCategory.values, json['category']) ??
        AttachmentCategory.outro,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  @override
  List<Object?> get props => [
    id,
    patientId,
    storagePath,
    fileName,
    contentType,
    category,
    createdAt,
  ];
}
