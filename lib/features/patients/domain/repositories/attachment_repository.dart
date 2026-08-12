import 'dart:typed_data';

import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/attachment.dart';

abstract class AttachmentRepository {
  Future<Result<List<Attachment>>> getForPatient(String patientId);

  Future<Result<Attachment>> upload({
    required String patientId,
    required AttachmentCategory category,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  });

  Future<Result<void>> delete(Attachment attachment);

  Future<Result<String>> getViewUrl(Attachment attachment);
}
