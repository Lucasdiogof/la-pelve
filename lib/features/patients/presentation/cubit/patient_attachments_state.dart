import 'package:la_pelve/core/state/data_state.dart';
import 'package:la_pelve/features/patients/domain/entities/attachment.dart';

class PatientAttachmentsState {
  const PatientAttachmentsState({
    this.attachments = const DataState<List<Attachment>>.loading(),
    this.uploading = false,
  });

  final DataState<List<Attachment>> attachments;
  final bool uploading;

  PatientAttachmentsState copyWith({
    DataState<List<Attachment>>? attachments,
    bool? uploading,
  }) {
    return PatientAttachmentsState(
      attachments: attachments ?? this.attachments,
      uploading: uploading ?? this.uploading,
    );
  }
}
