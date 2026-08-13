import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/attachment.dart';

void main() {
  group('Attachment.isImage / isPdf', () {
    test('detects an image content type', () {
      final attachment = Attachment(
        id: 'a1',
        patientId: 'p1',
        storagePath: 'path/photo.jpg',
        fileName: 'photo.jpg',
        contentType: 'image/jpeg',
        category: AttachmentCategory.image,
        createdAt: DateTime.utc(2026, 3, 5),
      );

      expect(attachment.isImage, isTrue);
      expect(attachment.isPdf, isFalse);
    });

    test('detects a PDF content type', () {
      final attachment = Attachment(
        id: 'a1',
        patientId: 'p1',
        storagePath: 'path/doc.pdf',
        fileName: 'doc.pdf',
        contentType: 'application/pdf',
        category: AttachmentCategory.document,
        createdAt: DateTime.utc(2026, 3, 5),
      );

      expect(attachment.isPdf, isTrue);
      expect(attachment.isImage, isFalse);
    });
  });

  group('Attachment.toJson/fromJson', () {
    test('round-trips a full attachment', () {
      final attachment = Attachment(
        id: 'a1',
        patientId: 'p1',
        storagePath: 'path/photo.jpg',
        fileName: 'photo.jpg',
        contentType: 'image/jpeg',
        category: AttachmentCategory.assessmentForm,
        createdAt: DateTime.utc(2026, 3, 5),
      );

      final restored = Attachment.fromJson(attachment.toJson());

      expect(restored, attachment);
    });

    test('defaults to other for an unknown category', () {
      final json = {
        'id': 'a1',
        'patient_id': 'p1',
        'storage_path': 'path',
        'file_name': 'file',
        'content_type': 'image/jpeg',
        'category': 'unknown_category',
        'created_at': DateTime.utc(2026, 3, 5).toIso8601String(),
      };

      expect(Attachment.fromJson(json).category, AttachmentCategory.other);
    });
  });
}
