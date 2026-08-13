import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/attachment.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/attachment_repository.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patient_attachments_state.dart';

class PatientAttachmentsCubit extends Cubit<PatientAttachmentsState> {
  PatientAttachmentsCubit(this._repository, this._patientId)
    : super(const PatientAttachmentsState()) {
    reload();
  }

  final AttachmentRepository _repository;
  final String _patientId;

  Future<void> reload() async {
    emit(state.copyWith(clearResult: true));
    final result = await _repository.getForPatient(_patientId);
    emit(state.copyWith(result: result));
  }

  Future<Result<Attachment>> upload({
    required AttachmentCategory category,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    emit(state.copyWith(uploading: true));
    final result = await _repository.upload(
      patientId: _patientId,
      category: category,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
    emit(state.copyWith(uploading: false));
    if (result case Success()) await reload();
    return result;
  }

  Future<Result<void>> delete(Attachment attachment) async {
    final result = await _repository.delete(attachment);
    if (result case Success()) await reload();
    return result;
  }
}
