import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/state/data_state.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/patients/domain/entities/attachment.dart';
import 'package:la_pelve/features/patients/domain/repositories/attachment_repository.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patient_attachments_state.dart';

/// Anexos de UM paciente (sob demanda). A lista atual continua na tela
/// durante as recargas e quando uma recarga falha; só a primeira carga mostra
/// loading, e uma falha sem lista anterior vira erro com "tentar novamente".
class PatientAttachmentsCubit extends Cubit<PatientAttachmentsState> {
  PatientAttachmentsCubit(this._repository, this._patientId)
    : super(const PatientAttachmentsState()) {
    reload();
  }

  final AttachmentRepository _repository;
  final String _patientId;
  int _generation = 0;

  Future<void> reload() async {
    final generation = ++_generation;
    emit(state.copyWith(attachments: state.attachments.loadingStarted()));
    final result = await _repository.getForPatient(_patientId);
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(attachments: DataState.success(data)));
      case Error(:final failure):
        debugPrint('[DataLoad] attachments falhou (${failure.runtimeType})');
        emit(state.copyWith(attachments: state.attachments.failed(failure)));
    }
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
