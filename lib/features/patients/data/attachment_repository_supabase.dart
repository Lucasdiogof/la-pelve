import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fisioterapia_pelvica/core/error/failures.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/attachment.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/attachment_repository.dart';
import 'package:fisioterapia_pelvica/shared/utils/id_generator.dart';

class AttachmentRepositorySupabase implements AttachmentRepository {
  AttachmentRepositorySupabase(this._client);

  final SupabaseClient _client;

  static const _bucket = 'patient-attachments';

  @override
  Future<Result<List<Attachment>>> getForPatient(String patientId) async {
    try {
      final rows = await _client
          .from('attachments')
          .select()
          .eq('patient_id', patientId)
          .order('created_at');
      return Success(rows.map((row) => Attachment.fromJson(row)).toList());
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[AttachmentRepositorySupabase.getForPatient] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[AttachmentRepositorySupabase.getForPatient] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<Attachment>> upload({
    required String patientId,
    required AttachmentCategory category,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;
      final id = generateId();
      final path = '$userId/$patientId/${id}_$fileName';
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );
      final attachment = Attachment(
        id: id,
        patientId: patientId,
        storagePath: path,
        fileName: fileName,
        contentType: contentType,
        category: category,
        createdAt: DateTime.now(),
      );
      await _client.from('attachments').insert(attachment.toJson());
      return Success(attachment);
    } on StorageException catch (e, st) {
      debugPrint(
        '[AttachmentRepositorySupabase.upload] storage statusCode=${e.statusCode} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[AttachmentRepositorySupabase.upload] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[AttachmentRepositorySupabase.upload] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> delete(Attachment attachment) async {
    try {
      await _client.storage.from(_bucket).remove([attachment.storagePath]);
      await _client.from('attachments').delete().eq('id', attachment.id);
      return const Success(null);
    } on StorageException catch (e, st) {
      debugPrint(
        '[AttachmentRepositorySupabase.delete] storage statusCode=${e.statusCode} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[AttachmentRepositorySupabase.delete] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[AttachmentRepositorySupabase.delete] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<String>> getViewUrl(Attachment attachment) async {
    try {
      final url = await _client.storage
          .from(_bucket)
          .createSignedUrl(attachment.storagePath, 3600);
      return Success(url);
    } on StorageException catch (e, st) {
      debugPrint(
        '[AttachmentRepositorySupabase.getViewUrl] storage statusCode=${e.statusCode} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[AttachmentRepositorySupabase.getViewUrl] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }
}
